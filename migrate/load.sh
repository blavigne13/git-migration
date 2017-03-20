#!/bin/bash
load() {
	local name="${1%.migration}.migration"

	if [[ -z "$1" || ! -f "${name}" ]]; then
		err "load: ${name}: file not found"
		list
		return 2
	fi

	drop_a_load \
		&& msg "loading: ${name}" \
		&& migration[file]="${name}" \
		&& read_migration_file \
		&& set_optional \
		&& check_required \
		&& migration[default-domain]="${migration[default-domain]/'='/' = '}" \
		&& migration[trunk]=$(format_map "${migration[trunk]}") \
		&& migration[branches]=$(format_map "${migration[branches]}") \
		&& migration[tags]=$(format_map "${migration[tags]}")

		if [[ ! "$?" = "0" ]]; then
			# drop_a_load
			err "load: ${name}: fail"
			return 1
		fi
	
		msg "${name} is loaded"
}

# Clear migration vars
drop_a_load() {
	unset migration
	declare -g -A migration
	msg "load dropped"
}

check_required() {
	declare ret

	if [[ ! "${migration[svn-url]}" == https://svn.schoolspecialty.com/svn/* ]]; then
		err "load: invalid svn-url: ${migration[svn-url]}"
		ret="${ret:=1}"
	fi
	if [[ ! "${migration[git-url]}" == *@bitbucket.schoolspecialty.com:*.git ]]; then
		err "load: invalid git-url: ${migration[git-url]}"
		# ret="${ret:=1}"
	fi

	if [[ -z "${migration[authors-file]}" ]]; then
		err "load: authors-file: missing required item"
		ret="${ret:=1}"
	fi

	if [[ ! -f "${migration[authors-file]}" ]]; then
		err "load: ${migration[authors-file]}: file not found or not a regular file"
		ret="${ret:=1}"
	fi

	if [[ ! "${migration[trunk]}" == *trunk*:*refs/heads/master ]]; then
		err "load: invalid trunk map: ${migration[trunk]}"
		ret="${ret:=1}"
	fi

	if [[ -n "${migration[branches]}" && ! "${migration[branches]}" == *branches*:*refs/heads/* ]]; then
		err "load: invalid branches map: ${migration[branches]}"
		ret="${ret:=1}"
	fi

	if [[ -n "${migration[tags]}" && ! "${migration[tags]}" == *tags*:*refs/tags/* ]]; then
		err "load: invalid tags map: ${migration[tags]}"
		ret="${ret:=1}"
	fi

	return "${ret:-0}"
}

set_optional() {
	declare ret

	if [[ -z "${migration[svn-dir]}" ]]; then
		msg "svn-dir not provided, SVN queries disabled."
		svn_queries+="no-svn-dir!"
	fi

	if [[ -z "${migration[git-dir]}" ]]; then
		migration[git-dir]="${migration[git-url]##*'/'}"
	fi

	if [[ -z "${migration[default-domain]}" ]]; then
		migration[default-domain]="${default[default-domain]}"
	fi

	if [[ -z "${migration[authors-file]}" || ! -f "${migration[authors-file]}" ]]; then
		err "authors-file not found: ${migration[authors-file]}"
		info "Checking for" "
    ${project_path}/${default[authors-file]}
    ${project_path}/../${default[authors-file]}
    ${scripts_path}/${default[authors-file]}"

		if [[ -f "${project_path}/${default[authors-file]}" ]]; then
			migration[authors-file]=$(readlink -f "${project_path}/${default[authors-file]}")
			info "Found" "${migration[authors-file]}\n"
		elif [[ -f "${project_path}/../${default[authors-file]}" ]]; then
			migration[authors-file]=$(readlink -f "${project_path}/../${default[authors-file]}")
			info "Found" "${migration[authors-file]}\n"
		elif [[ -f "${scripts_path}/${default[authors-file]}" ]]; then
			migration[authors-file]=$(readlink -f "${scripts_path}/${default[authors-file]}")
			info "Found" "${migration[authors-file]}\n"
		else
			migration[authors-file]=""
			err "
If you REALLY don't want to map commit authors, make an empty authors.txt.
After all, it shouldn't be easy to shoot yourself in the foot...
"
			ret="${ret:=1}"
		fi
	fi

	return "${ret:-0}"
}

read_migration_file() {
	declare ret

	(( lnum = 0 ))
	while read line || [ -n "${line}" ]; do
		(( ++lnum ))
		line="${line/'#'*/}" # strip comments
		line="${line//[[:space:]]/}" # strip whitespace

		case "${line}" in
			svn-url*)
				migration[svn-url]="${line#*=}"
				;;
			svn-dir*)
				migration[svn-dir]="${line#*=}"
				;;
			git-url*)
				migration[git-url]="${line#*=}"
				;;
			git-dir*)
				migration[git-dir]="${project_path}/${line#*=}"
				;;
			authors-file*)
				migration[authors-file]="${line#*=}"
				;;
			default-domain*)
				migration[default-domain]="\tdefaultDomain=${line#*=}"
				;;
			trunk*)
				migration[trunk]="\t${line}"
				;;
			branches*)
				migration[branches]+="\t${line}\n"
				;;
			tags*)
				migration[tags]+="\t${line}\n"
				;;
			"")
				;;
			*)
				err "load: ${migration[file]} (${lnum}): ${line}: invalid entry"
				ret="${ret:=1}"
				;;
		esac
	done < "${migration[file]}"

	return "${ret:=0}"
}

# meant to be used w/ command substitution
format_map() {
	local map="${1%'\n'}" # strip trailing newline
	map="${map%'/'}" # strip trailing slash
	map="${map/'='/' = '}" # replace first '=' by ' = '
	map="${map//'/'/'\/'}" # escape slashes
	map="${map//'*'/'\*'}" # escape asterisks
	echo "${map}"
}

list() {
	header "Repository migration files"
	for f in *.migration; do
		info "    ${f}"
	done
}
