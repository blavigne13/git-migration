#!/bin/bash
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

new_migration() {
    local name="${1%.migration}.migration"

	if [[ -z "$1" ]]; then
		err "Usage: new <repo-name>"
		return 2
    elif [[ -e "${name}" ]]; then
        err "file already exists: ${name}"
        return 1
	else
        echo "${blank_migration}" > "${name}"
        eval "${core[editor]} ${name}"
    fi
}

nuke() {
	local the_site="${project_path}/${migration[git-dir]}"

    if [[ ! -d "${the_site}" ]]; then
        err "nuke: directory not found: ${the_site}"
        return 1
    fi

    msg "Nuking the the site from orbit. It's the only way to be sure..."
    info "This will permanently delete ${the_site}"
    read -p "Are you sure? (yes/no) "
    if [[ "${REPLY}" = "yes" ]]; then
        subgit uninstall --purge "${the_site}"
        rm -rfd "${the_site}"
    fi
}
