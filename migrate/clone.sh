#!/bin/bash
clone() {
	cd "${project_path}"

    if [[ ! -d "${migration[git-dir]}" ]]; then
        err "clone: dir not found: ${migration[git-dir]}"
        return 1
    fi

    (subgit install "${migration[git-dir]}" | sed 's/ | /\n') \
        && subgit uninstall --purge "${migration[git-dir]}" \
        && (cd "${migration[git-dir]}" && git gc --aggressive)
}

test_clone() {
	&>/dev/null cd "${migration[git-dir]}" && git log -0
}
