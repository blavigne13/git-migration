#!/bin/bash
# Set paths
readonly project_path=$(pwd)
readonly scripts_path=$(dirname "$0")
readonly cache_path="${scripts_path}/svn_cache"

# Create cache_path if need be
if [[ ! -e "${cache_path}" ]]; then
	mkdir "${cache_path}"
elif [[ ! -d "${cache_path}" ]]; then
	err "
migrate: not a directory: ${cache_path}
Why is ${cache_path} a _file_?
"
	svn-queries+="no-cache!"
fi


# Global vars
readonly config_file="${scripts_path}/.migrate-config"
declare -A core
declare -A default
declare -A migration

# Failsafes
core[editor]="vim"

# Source files
for f in "${scripts_path}/migrate/"*.sh; do
	source "${f}"
done

readonly usage="
Usage:
    migrate.sh                  Start in read-evaluate-print-loop mode, suitable
                                for working with individual migration files.
    migrate.sh [options] <job>  Perform a batch job on all migration files in
                                the current directory.

Options:
    -r|--recursive  Instead of the current directory, recursively search for
                    migration files in sub-directories.
                    (*/*.migration)
    -R|--recurrent  In addition to the current directory, recursively search for
                    migration files in sub-directories.
                    (*/*.migration)

Jobs:
    verify  Load, display and optionally edit, all migration files in the
            current directory. (load, status, [edit])
    gogogo  Load all migration files in the current directory (*.migration) and
            perform a complete SVN-to-Git migration. (load, init, clone, push)            
            Note: Requires an SSH key configured for the target Git repository
            and an active SSH agent with said key loaded. (eg: ssh-agent)
    paths   Recursively search the SVN repository for this project's paths. In
            order to minimize network usage, the SVN repositor's full recursive
            directory tree is cached to disk. As such, the first query may take
            a few minutes (depending on network speed). Requires svn-dir defined
            in migration file.
            Options:
                -d|--depth <n>  Include sub-directories of svn-dir to depth <n>.
                                Default behavior is depth 1. Examples for 
                                'paths -d 2' (files to be tracked are in src):
                                    svn-dir/tags/*/src
                                    tags/svn-dir/*/*/src
                -f|--freshen    Freshen the cache for this project's repository.
    recent  Query the SVN repository for commit activity on project paths (as
            reported by 'paths --depth 0'), report the commit count for each
            author, and map to 'first-name last-name <email-address>' if mapped
            in authors-file. Requires svn-dir defined in migration file.
            Options:
                -m|--months <n>  Specify a length of time (in months, duh) to
                                 query. Default behavior is 3 months.
"

readonly blank_migration="# Commented properties are optional

svn-url = ${default[svn-url]}
# svn-dir = ${default[svn-dir]}

git-url = ${default[git-url]}
# git-dir = ${default[git-dir]}

authors-file = ${default[authors-file]}
default-domain = ${default[default-domain]}

trunk = ${default[trunk]}
# branches = ${default[branches]}
# tags = ${default[tags]}
"

main() {
	read_config

	if test_ssh; then
		(( no_ssh = 0 ))
	else
		(( no_ssh = 1 ))
	fi

	while true; do
		case "$1" in
			-r|--recursive)
				glob="*/*.migration"
				shift
				;;
			-R|--recurrent)
				glob="*.migration */*.migration"
				shift
				;;
			*)
				glob="*.migration"
				break
				;;
		esac
	done
	
	case "$1" in
		"") repl;;
		verify) verify_all;;
		gogogo) gogogo;;
		paths) svn_paths_gogogo "$2";;
		recent) recent_users_gogogo "$2";;
		*) echo "${usage}";;
	esac
}

verify_all() {
	for f in $(echo "${glob}"); do
		while true; do
			load "${f}" && status
			echo ""
			read -s -n 1 -p "Edit this file? (y/n) "
			if [[ "${RESULT}" = "y" ]]; then
				eval "${core[editor]} ${project_path}/${migration[file]}"
			elif [[ "${RESULT}" = "n" ]]; then
				break;
			else
				msg "srsly?"
			fi
		done
	done
}

gogogo() {
	(( job_count = 0 ))
	(( max_jobs = NUMBER_OF_PROCESSORS ))

	msg "\nGOGOGO!"
	info "Max concurrent migrations" "${max_jobs}"
	info "Repository migration files" "\n$(ls *.migration | sed 's/^/    /')"

	while true; do
		read -s -n 1 -p "Are you sure? (y/n) "
		if [[ "${REPLY}" = "y" ]]; then
			break;
		elif [[ "${REPLY}" = "n" ]]; then
			msg "I hate you too!"
			return 1
		else
			msg "wtf, mate?"
		fi
	done

	for f in *.migration; do
		# if max_jobs already started, wait for one to finish
		if [[ "${job_count}" -ge "${max_jobs}" ]]; then
			info "${job_count} migrations in progress" "waiting..."
			wait -n
			(( --job_count ))
		fi

		# make sure f is a regular file
		if [[ -f "${f}" ]]; then
			info "Starting migration" "${f}"
			migrate "${f}" &
			(( ++job_count ))
		fi
	done
	msg "\nAll jobs started"

	# wait 1 job at a time
	while [[ ${job_count} > 0 ]]; do
		info "Waiting on in-progress migrations" "${job_count} jobs"
		wait -n
		(( --job_count ))
	done

	# double checking, in case I suck at this
	info "Waiting on remaining migrations" "(should be ${job_count} jobs"
	jobs -r
	wait
	msg "\nkthxbai"
}

# full migration of file passed as arg
migrate() {
	#sleep $((RANDOM % 13))
	#/dev/null
	(load "$1") \
		&& (init) \
		&& (clone) \
		&& (push) \
		&& (echo "yay!") \
		|| (echo "boo!" && false)
}

new_migration() {
	if [[ -z "$1" ]]; then
		err "Usage: new <repo-name>"
		return 2
	fi

	echo "${blank_migration}" > "$1.migration"
	eval "${core[editor]} $1.migration"
}

read_config() {
	if [[ ! -f "${config_file}" ]]; then
		err "config file not found: ${config_file}" && false
	fi

	local lnum="0"
	local section=""
	local name=""
	local value=""

	while read line || [ -n "${line}" ]; do
		(( ++lnum ))
		line=$(echo "${line}" | sed 's/^[[:space:]]*|[[:space:]]*$//')

		if [[ "${line}" =~ \[.*\] ]]; then
			section="${line:1:-1}"
		else
			name="${section}[${line%%=*}]"
			value="${line##*=}"

			if [[ -n "${name}" ]]; then
				eval "${name}=\"${value}\""
			fi
		fi
	done < "${config_file}"

	readonly -A core
	readonly -A default
}

nuke() {
	local the_site="${migration[git-dir]}"

    if [[ ! -d "${the_site}" ]]; then
        err "nuke: directory does not exist: ${the_site}"
        return 1
    fi

    msg "Nuking the the site from orbit. It's the only way to be sure..."
    fail "This will permanently delete ${the_site}"

    read -p "Are you sure? (yes/no) "
    if [[ "${REPLY}" = "yes" ]]; then
        subgit uninstall --purge "${the_site}" \
        	&& rm -rfd "${the_site}"
    fi
}

main "$@"
