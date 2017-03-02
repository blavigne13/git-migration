#!/bin/bash
junit_gogogo() {
    for f in ${glob}; do
        cd "${project_path}"
        >/dev/null load "${f}" && junit
    done
}

junit() {
    cd "${project_path}/${migration[git-dir]}"
    local tree="$(ls refs/heads)"
    echo "__${tree}"
    local tree="$(git ls-tree -r --name-only "${tree}" | sort -u)"
    echo "____${tree}"

    echo "${tree}" | grep '/[^/]*Test[^/]*java'
    echo "===="
    echo "${tree}" | grep '/test[^/]*java'
    echo "===="
    echo "${tree}" | grep '.*/test/.*java'

    # git ls-tree -r --name-only $(git log -1 --pretty=format:%H) | egrep '.*Test.*.?ava'
    echo "======="
    pwd
    ls refs/heads
}
