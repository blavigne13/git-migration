#!/bin/bash
clone() {
    cd "${project_path}"

    if [[ ! -d "${migration[git-dir]}" ]]; then
        err "clone: dir not found: ${migration[git-dir]}"
        return 1
    fi

    subgit install "${migration[git-dir]}" \
        && subgit uninstall --purge "${migration[git-dir]}" \
        && (cd "${migration[git-dir]}" && git gc --aggressive)
}

ignore() {
    cd "${project_path}/${migration[git-dir]}"
    if [[ -f ".gitignore" ]]; then
        info "Contents of .gitignore" "\n$(cat .gitignore | sed 's/^/    /')"
    else
        info "file not found" ".gitignore"
    fi
}

test_clone() {
	(cd "${project_path}/${migration[git-dir]}" && git log -0) &>/dev/null 
}
