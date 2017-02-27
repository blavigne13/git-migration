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
declare -A files

# Failsafes
core[editor]="vim"

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
            Parameters:
                [refresh]  Refresh the cache for this project's repository.
                           Note: If included, refresh must be the first 
                           parameter passed to paths.
                [depth]    Numeric value indicating the depth of included sub-
                           directories of svn-dir. Default behavior is depth 1.
                           Examples where 'paths 2' would be helpful (files to
                           be tracked are in src):
                               svn-dir/tags/*/src
                               tags/svn-dir/*/*/src
    recent  Query the SVN repository for commit activity on project paths (as
            reported by 'paths --depth 0'), report the commit count for each
            author, and map to 'first-name last-name <email-address>' if mapped
            in authors-file. Requires svn-dir defined in migration file.
            Options:
                [months]  Numeric value indicating the length of time (in
                          months, duh) to query. Default behavior is 3 months.

Dependencies and stuff:
    ls      If ls is aliased to something that prevents 'ls -1' from printing
            the name (and *only* the name) of *exactly* one file per line,
            things might not work as intended. Or they might not not work as
            intended. Feel free to test it...
    SubGit  clone.sh is the shortest script in this package. SubGit is the
            reason for that--it does all the heavy lifting involved in
            transalting SVN to Git. subgit/bin needs to be in your PATH for
            init and clone to work.
"

main() {
	read_config
    for f in "${scripts_path}"/migrate/*.sh; do
        source "${f}"
    done

	glob="*.migration"
	while true; do
		case "$1" in
			-r|--recursive) glob="*/*.migration"; shift;;
			-R|--recurrent) glob="*.migration */*.migration"; shift;;
			*) break;;
		esac
	done
	glob=$(ls -1 ${glob} | sort -u)

	case "$1" in
		"") repl;;
		verify) verify_all;;
		gogogo) gogogo;;
		paths) svn_paths_gogogo "$2";;
		recent) recent_users_gogogo "$2";;
        wikify) wikify_gogogo "$2" "$3";;
		*) echo "${usage}";;
	esac
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

wikify_gogogo() {
    local regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\)[[:space:]]\+<\(.*\)>.*/| \1 | \2 | \3 |/'
    local another_regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\).*/| \1 | \2 | |/'
    
    echo "
{toc}

h2. Migration Status

|| Action || Status ||
| Contact committers |  |
| Confirm maps |  |
| Migrate repository |  |
| Bamboo build |  |

h3. Comments

lorem ipsum

h3. Recent Committers (${2:-3} months)

|| Commits || Name || Email ||"
    recent_users_gogogo "$2" | sed "${regex}" | sed "${another_regex}"
    echo "
h2. Repositories
"
    for f in ${glob}; do
        >/dev/null load "${f}" && wikify "$1" "$2"
    done
}

wikify() {
    local regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\)[[:space:]]\+<\(.*\)>.*/| \1 | \2 | \3 |/'
    local another_regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\).*/| \1 | \2 | |/'

    echo "
h3. ${migration[file]%.migration}

h4. Comments

lorem ipsum

h4. Recent Committers (${2:-3} months)

|| Commits || Name || Email ||"
    recent_users "$2" | sed "${regex}" | sed "${another_regex}"
    echo "
h4. Path map

|| SVN repo path || Maps to || Comments ||"
    svn_paths "$1" | sed 's/^/| /' | sed 's/$/ |  |  |/'
    echo "
{noformat:title=Migration map}"
    cat "${migration[file]}" | sed 's/#.*//' | egrep --invert-match '^$'
    echo "{noformat}"
}

main "$@"