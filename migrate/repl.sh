#!/bin/bash
halp() {
	echo "
Commands:
    ls, list        List migration configuration files in current directory.
    st, status      Print the current project's configuration.
    load [project]  Load the specified migration project. If [project] is not
  				    found or is blank, 'list' is invoked.
    init            Initialize current migration project. Creates a bare Git 
  				    repository and configures SubGit.
    clone           Clone the SVN repository and convert to a bare Git 
  				    repository using SubGit.
    push            Push all Git branches and tags to remote origin.
    nuke            Nuke the current migration project from orbit. Any Git 
  				    repositories created for this project are removed, but the
  				    project's .migration file is retained.
    new
    ed, edit
    re, recent
    pa, paths
    exit
    h, halp         Print this help message.
"
}

repl() {
	msg "I can has repl?"
	while true; do
		local cmd=""

		status_bar
		read -e -p "${cyan@E}\$ ${clr@E}" -a cmd
		history -s "${cmd[@]}"

		cd "${project_path}"
		case "${cmd}" in
			ls|list) list;;
			st|status) status;;
			lo|load) load "${cmd[1]}" && status;;
			init) init;;
			clone) clone;;
			push) push;;
			nuke) nuke;;
			new) new_migration "${cmd[1]}";;
			ed|edit) eval "${core[editor]} ${project_path}/${migration[file]}";;
			re|recent) recent_users "${cmd[1]}";;
			pa|paths) svn_paths "${cmd[1]}";;
			clr|clear) clear;;
			exit) break;;
			h|halp) halp;;
			*) err "invalid command: ${cmd},
type 'halp' for help, pls.
";;
		esac
	done
	
	msg "kthxbai"
}

status_bar() {
	local msg="\n${yellow}${migration[file]}"

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
