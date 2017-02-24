#!/bin/bash
load() {
	cd "${project_path}"
	
	if [[ -z "$1" ]]; then
		err "load: file not specified"
		list
		return 2
	elif [[ ! -f "$1" ]]; then
		err "load: $1: file not found or not a regular file"
		list
		return 2
	fi

	unload \
		&& migration[file]="$1" \
		&& read_migration_file \
		&& set_optional \
		&& check_required \
		&& migration[default-domain]="${migration[default-domain]/'='/' = '}" \
		&& migration[trunk]=$(format_map "${migration[trunk]}") \
		&& migration[branches]=$(format_map "${migration[branches]}") \
		&& migration[tags]=$(format_map "${migration[tags]}") \
		|| (unload; exit 1)
}

# Clear global vars
unload() {
    
migration[file]="" \
    	&& migration[svn-url]="" \
    	&& migration[svn-dir]="" \
    	&& migration[git-url]="" \
    	&& migration[git-dir]="" \
    	&& migration[trunk]="" \
    	&& migration[branches]="" \
    	&& migration[tags]="" \
    	&& migration[authors-file]="" \
    	&& migration[default-domain]="" \
    	&& echo "Unloaded" \
    	|| (err "Unload failed"; exit 1)
}

check_required() {
	declare ret

	if [[ ! "${migration[svn-url]}" == https://svn.schoolspecialty.com/svn/* ]]; then
		err "load: invalid svn-url: ${migration[svn-url]}"
		ret="${ret:=1}"
	fi

	if [[ ! "${migration[git-url]}" == ssh://git@bitbucket.schoolspecialty.com/*.git ]]; then
		err "load: invalid git-url: ${migration[git-url]}"
		# ret="${ret:=1}"
	fi

	if [[ ! "${migration[trunk]}" == *trunk*:*refs/heads/master ]]; then
		err "load: invalid trunk map: ${migration[trunk]}"
		ret="${ret:=1}"
	fi

	if [[ -z "${migration[authors-file]}" ]]; then
		err "load: authors-file: missing required item"
		ret="${ret:=1}"
	fi

	if [[ ! -f "${migration[authors-file]}" ]]; then
		err "load: ${migration[authors-file]}: file not found or not a regular file"
		ret="${ret:=1}"
	fi

	return ${ret:-0}
}

set_optional() {
	if [[ -z "${migration[svn-dir]}" ]]; then
		msg "svn-dir not provided, SVN queries disabled."
	fi

	if [[ -z "${migration[git-dir]}" ]]; then
		migration[git-dir]="${migration[git-url]##*'/'}"
	fi

	if [[ -z "${migration[default-domain]}" ]]; then
		migration[default-domain]="${default[default-domain]}"
	fi
	echo "af____${migration[@]}"
	echo
	echo "af______${migration[*]}"
	echo "af______${migration[#]}"
	if [[ -z "${migration[authors-file]}" || ! -f "${migration[authors-file]}" ]]; then
		info "
Authors-file not configured, looking for:" "
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
			msg "
It shouldn't be easy to shoot yourself in the foot...
If you REALLY don't want to map commit authors, make an empty authors.txt.
"
		fi
	fi
}

read_migration_file() {
	(( lnum=0 ))	
	while read line || [ -n "${line}" ]; do
		(( ++lnum ))
		line="${line/'#'*/}" # strip comments
		line="${line//[[:space:]]/}" # strip whitespace

		case "${line}" in
			svn-url*) migration[svn-url]="${line#*=}";;
			svn-dir*) migration[svn-dir]="${line#*=}";;
			git-url*) migration[git-url]="${line#*=}";;
			git-dir*) migration[git-dir]="${project_path}/${line#*=}";;
			authors-file*) migration[authors-file]="${line#*=}";;
			defaultDomain*) migration[default-domain]="${line}";;
			trunk*) migration[trunk]="${line}";;
			branches*) migration[branches]+="${line}\n";;
			tags*) migration[tags]+="${line}\n";;
			"") ;;
			*) err "load: ${migration[file]} (${lnum}): ${line}: invalid entry"; return 1;;
		esac
	done < "${migration[file]}"
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
