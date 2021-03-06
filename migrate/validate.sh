#!/bin/bash
# This module is a work in progress...


git_co() {
    if [[ ! -d "${migration[git-dir]}" ]]; then
        git clone "${migration[git-dir]}"
    fi

    cd "${migration[git-dir]}"
    git checkout "$1"
}

svn_co() {
    # change to take advantage of wildcards in checkout path?
    svn co "${migration[svn-url]}" "$1/${migration[svn-dir]}"
    cd "${migration[svn-dir]}"
}

git_log() {
    cd "${migration[git-dir]}"
    #git checkout "${1}"
    git log --date=iso-local --pretty=format:"%cd%n%B" \
        | egrep -v '^$' \
        > ../"${migration[git-dir]}".log
}

svn_log() {
    svn log "${migration[svn-url]}" "${1}" \
        | egrep -v '^-*$\|^$' \
        | sed 's/^r[^|]* | [^|]* | \([^|]*\) ([^|]* | [^|]*$/\1/' \
        > ../"${migration[svn-dir]}".svn.log
}

# checkout and diff 
diff_files() {
    return 0
}

# diff timestamp and message for each commit
diff_logs() {
    diff -us --suppress-common-lines \
        "${migration[svn-dir]}".svn.log \
        "${migration[git-dir]}".git.log \
        | less
}

validate() {
    if [[ ! -d "${migration[git-dir]}" ]]; then
        echo -e "validate: Git dir not found: ${migration[git-dir]}"
        return 1
    fi

    svn_log "${1}"
    git_log "${2}"
}
