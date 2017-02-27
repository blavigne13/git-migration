#!/bin/bash
init() {
	if [[ -d "${migration[git-dir]}" ]]; then
		err "init: ${migration[git-dir]}: directory already exists"
		return 1
	fi

	local cfg_file="${project_path}/${migration[git-dir]}/subgit/config"
	local domain="defaultDomain = localhost"
	local trunk="trunk = trunk:refs\/heads\/master"
	local branches="branches = branches\/\*:refs\/heads\/\*"
	local tags="tags = tags\/\*:refs\/tags\/\*"

	subgit configure --svn-url "${migration[svn-url]}" "${migration[git-dir]}" \
		&& cp "${cfg_file}" "${cfg_file}.old" \
		&& cp "${migration[authors-file]}" "${migration[git-dir]}/subgit/authors.txt" \
		&& perl -pi -e "s/${domain}/${migration[default-domain]}/" "${cfg_file}" \
		&& perl -pi -e "s/${branches}/${migration[branches]}/" "${cfg_file}" \
		&& perl -pi -e "s/${tags}/${migration[tags]}/" "${cfg_file}" \
		&& perl -pi -e "s/${trunk}/${migration[trunk]}/" "${cfg_file}" \
		|| (err "init: fail" && false)
}

test_init() {
	(cd "${project_path}/${migration[git-dir]}/subgit" \
		&& local url=$(grep "^[[:space:]]*url[[:space:]]*=" config) \
		&& [[ "${url//[[:space:]]/}" = "url=${migration[svn-url]//[[:space:]]/}" ]] \
		&& local trunk=$(grep "^[[:space:]]*trunk[[:space:]]*=" config) \
		&& trunk=$(format_map "${trunk}") \
		&& [[ "${trunk//[[:space:]]/}" = "${migration[trunk]//[[:space:]]/}" ]]) \
		&>/dev/null
}
