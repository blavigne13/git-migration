#!/bin/bash
readonly red='\033[1;31m'
readonly green='\033[0;32m'
readonly yellow='\033[0;33m'
readonly blue='\033[1;34m'
readonly purple='\033[0;35m'
readonly cyan='\033[0;36m'
readonly gray='\033[0;37m'
readonly clr='\033[0m'

pprint() {	
	if [[ "$#" -eq "2" ]]; then local sep1=": "; fi
	if [[ "$#" -eq "3" ]]; then local sep2=": "; fi

	if [[ ! -t 1 ]]; then
		echo -e "${1#\\033*m}${sep1}${2/#\\033*m}${sep2}$3"
	else
		echo -e "$1${sep1}$2${sep2}$3${clr}"
	fi
}

err() {
	>&2 echo "$1"
}

# If the second arg of a two-part msg is a var that can be the empty string,
# then include a space after it in order to force correct coloring
# eg: info "my message" "${my_var} "
info() {
	if [[ -z "$2" ]]; then
		pprint "${yellow}$1"
	else
		pprint "${clr}$1" "${yellow}$2"
	fi
}

header() {
	pprint "${green}$1"
}

msg() {
	pprint "${cyan}$1"
}

sep() {
	echo "----------------------------------------"
}

status() {
	header "\nMigration Configuration"
	echo "Migration file"
	info "  ${migration[file]}"
	echo "svn-url"
	info "  ${migration[svn-url]}"
	echo "svn-dir"
	info "  ${migration[svn-dir]}"
	echo "git-url"
	info "  ${migration[git-url]}"
	echo "git-dir:"
	info "  ${migration[git-dir]}"
	echo "default-domain"
	info "  ${migration[default-domain]}"
	echo "authors-file"
	info "  ${migration[authors-file]}"
	echo "trunk"
	info "  ${migration[trunk]}"
	echo "branches"
	info "  ${migration[branches]}"
	echo "tags"
	info "  ${migration[tags]}"
}
