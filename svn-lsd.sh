#!/bin/bash
echo "
h2. {nolink}$1{nolink}

|| *Revision* || *Author* || *Date* || *Path* || Notes ||"

filter_regex="(trunk|branches)/([^/]*/){0,1}\$" 
format_regex='s/^[[:space:]]*'
format_regex+='([0-9]+)[[:space:]]+'
format_regex+='([^[:space:]]*)[[:space:]]+'
format_regex+='(.{3}[[:space:]]+.{2}[[:space:]]+.{2}:?.{2})[[:space:]]+'
format_regex+='(.*)$/| \1 | \2 | \3 | \4 |  |/'
filter_regex="dataload"

tmp_file="${1##*/}"
test -e "${tmp_file}" \
	|| (svn ls -R --verbose "$1" | egrep '/$' > "${tmp_file}")
egrep "${filter_regex}" "${tmp_file}" \
	| egrep -v "[[:space:]]obsolete/|[[:space:]]trunk/$|[[:space:]]branches/$" \
	| sort -k6 \
	| uniq -f5 \
	| sed -r "${format_regex}"
