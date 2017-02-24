#!/bin/bash
svn_paths() {
    local cache_file="${cache_path}/${migration[svn-url]##*/}"
    local depth="${1:-0}"

    if [[ ! -f "${cache_file}" ]]; then
        svn ls -R "${migration[svn-url]}" | egrep '.*/$' > "${cache_file}"
    fi

    egrep "${migration[svn-dir]}/([^/]*/){0,${depth}}\$" "${cache_file}"
}

svn_paths_gogogo() {
    for f in *.migration; do
        >/dev/null load "${f}" && svn_paths "$1" | sed 's/^/    /'
    done
}

recent_users_query() {
    # default to 3 months
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
    start[m]=$(( end[m] - ${months} ))
    start[d]="${end[d]}"

    while [[ "${start[m]}" -le "0" ]]; do
        (( --y ))
        (( m += 12 ))
    done

    m=$(printf %02d $m)
    svn log -q -r "{${start[y]}-${start[m]}-${start[d]}}:{${end[y]}-${end[m]}-${end[d]}}" "${migration[svn-url]}" $(svn_paths) \
        | egrep -v '^-*$' \
        | sed 's/^[^|]* | \([^|]*\).*$/\1/'
}

apply_map() {
    local result="$1"

    while read name || [ -n "${line}" ]; do
        result="${result/${name/% =*}/${name/#*= }}"
    done < "${migration[authors-file]}"

    echo "${result}"
}

recent_users() {
    apply_map "$(recent_users_query "$1" | sort | uniq -c | sort -r)"
}

recent_users_gogogo() {
    local all_users=""

    for f in */*.migration; do
        info "Migration file" "${f} "
        info "svn-dir" "${migration[svn-dir]}"

        >/dev/null load "${f}" \
            && recent_users "$1" \
            && echo "--------------------------------------------------------" \
            && all_users+="$(recent_users_query "$1")\n"
    done

    msg "Combined"
    apply_map "$(echo -e "${all_users%'\n'}" | sort | uniq -c | sort -r)"
}
