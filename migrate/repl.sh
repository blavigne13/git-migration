#!/bin/bash
halp="
Commands:
    ls|list         List migration configuration files in current directory.
    st|status       Print the current project's configuration and status.
    lo|load <name>  Load the migration file '<name>.migration' if it exists in
                    the current directory. '.migration' at the end of <name> may
                    be included or omitted as desired.
    init            Initialize current migration project. Creates a bare Git 
  				    repository and configures SubGit.
    clone           Clone the the project path(s) from the SVN repository and 
                    convert to a bare Git repository using SubGit.
    push            Push all Git branches and tags to the remote Git repository.
    nuke            Nuke the current migration project from orbit. Deletes the 
    			    project's associated Git repository and corresponding SubGit
    			    configuartion. Does not delete the .migration file.
    new <name>      Create <name>.migration in the current directory and open it 
                    the editor. Initial configuration is populated using using
                    values found in the [default] section of .migrate-config.
    ed|edit         Open the currently loaded migration file in the editor.
    pa|paths        Recursively search the SVN repository for this project's
                    paths. In order to minimize network usage, the SVN
                    repository's full recursive directory tree is cached to
                    disk. As such, the first query may take a few minutes
                    (depending on network speed). Requires svn-dir defined in
                    migration file.
                    Parameters:
                        [refresh]  Refresh the cache for this project's
                                   repository. Note: If included, refresh must
                                   be the first parameter passed to paths.
                                   (Because I don't feel like doing it the right
                                   way at the moment.)
                        [depth]  Numeric value indicating the depth of included
                                 sub-directories of svn-dir. Default behavior is
                                 depth 1. Examples where 'paths 2' would be
                                 helpful (files to be tracked are in src):
                                     svn-dir/tags/*/src
                                     tags/svn-dir/*/*/src
    re|recent       Query the SVN repository for commit activity on project
                    paths (as reported by 'paths  0'), report the commit count
                    for each author, and map to 'first-name last-name
                    <email-address>' if mapped in authors-file. Requires svn-dir
                    defined in migration file.
                    Options:
                        [months]  Numeric value indicating the length of time
                                  (in months, duh) to query. Default behavior is
                                  3 months.
    exit            Deposits 1337 Liberian Dollars into your bank account.
    halp            Probably prints this help message.
"

repl() {
	msg "I can has repl?"
	while true; do
		declare -a cmd

		status_bar
		read -e -p "${cyan@E}\$ ${clr@E}" -a cmd
		history -s "${cmd[@]}"

		cd "${project_path}"
		case "${cmd}" in
			ls|list) list;;
			st|status) status;;
			lo|load) load "${cmd[@]:1}" && status;;
			init) init;;
			clone) clone;;
			push) push;;
			nuke) nuke;;
			new) new_migration "${cmd[@]:1}";;
			ed|edit) eval "${core[editor]} ${project_path}/${migration[file]}";;
			re|recent) recent_users "${cmd[@]:1}";;
			pa|paths) svn_paths "${cmd[@]:1}";;
			clr|clear) clear;;
			exit) break;;
			h|halp) echo "${halp}";;
			*) err "invalid command: ${cmd[0]}: type 'halp' for help, pls.";;
		esac
	done
	
	msg "kthxbai"
}

status_bar() {
	local msg="
${yellow}${migration[file]}${clr}
"

	if [[ -z "${migration[file]}" ]]; then
		msg+="[${red}load${clr}] "
	else
		msg+="[${green}load${clr}] "
	fi

	if test_init; then
		msg+="[${green}init${clr}] "
	else 
		msg+="[${red}init${clr}] "
	fi

	if test_clone; then
		msg+="[${green}clone${clr}] "
	else
		msg+="[${red}clone${clr}] "
	fi

	if test_push; then
		msg+="[${green}push${clr}]"
	else
		msg+="[${red}push${clr}]"
	fi

	echo -e "${msg}"
}
