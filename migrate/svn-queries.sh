#!/bin/bash
svn_paths() {
    local cache_file="${cache_path}/${migration[svn-url]##*/}"

    if [[ "$1" = "refresh" ]]; then
        rm -f "${cache_file}"
        shift
    fi

    local depth="${1:-1}"
    
    if [[ ! -f "${cache_file}" ]]; then
        svn ls -R "${migration[svn-url]}" | egrep '.*/$' > "${cache_file}"
    fi

    egrep "${migration[svn-dir]}/([^/]*/){0,${depth}}\$" "${cache_file}"
}

recent_users_query() {
    local months="${1:-3}"

    if [[ "${months}" != ?(-)*([0-9]) ]]; then
        err "recent_users" "Not a number" "${months}"
        err "Usage: recent [number-of-months]"
        return 2
    fi

    if [ "${months}" -lt 0 ]; then
        err "recent_users_query: ${months}: cannot look into the future"
        return 2
    fi

    declare -A end
    declare -A start
    end[y]=$(date +'%Y')
    end[m]=$(date +'%m')
    end[d]=$(date +'%d')
    start[y]="${end[y]}"
    start[m]=$(( end[m]-${months} ))
    start[d]="${end[d]}"

    while [[ "${start[m]}" -le "0" ]]; do
        (( --start[y] ))
        (( start[m]+=12 ))
    done

    start[m]=$(printf %02d ${start[m]})
    svn log -q -r "{${start[y]}-${start[m]}-${start[d]}}:{${end[y]}-${end[m]}-${end[d]}}" "${migration[svn-url]}" $(svn_paths) \
        | egrep -v '^-*$' \
        | sed 's/^[^|]* | \([^|]*\).*$/\1/'
}

apply_map() {
    local result="$1"

    while read name || [ -n "${name}" ]; do
        result="${result/${name/% =*}/${name/#*= }}"
    done < "${migration[authors-file]}"

    echo "${result}"
}

recent_users() {
    apply_map "$(recent_users_query "$1" | sort | uniq -c | sort -r)"
}
