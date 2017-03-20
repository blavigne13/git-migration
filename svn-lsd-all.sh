#!/bin/bash
apply_map() {
    local result="$1"

    while read name || [ -n "${name}" ]; do
        result="${result//${name/% =*}/${name/#*= }}"
    done < "/home/lavigb11/git-migration/authors.txt"

    echo "${result}"
}

while read line || [ -n "${line}" ]; do
	[[ ${line} != \#* ]] && apply_map "$(svn-lsd.sh "${line}")"
done < "$1"
