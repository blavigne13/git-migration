#!/bin/bash
init() {
	# if [[ -d "${migration[git-dir]}" ]]; then
	# 	err "init: ${migration[git-dir]}: directory already exists"
	# 	return 1
	# fi

	local cfg_file="${project_path}/${migration[git-dir]}/subgit/config"

	local domain="defaultDomain = localhost"
	local trunk="trunk = trunk:refs\/heads\/master"
	local branches="branches = branches\/\*:refs\/heads\/\*"
	local tags="tags = tags\/\*:refs\/tags\/\*"

	subgit configure --svn-url "${migration[svn-url]}" "${migration[git-dir]}" \
		&& echo "--" \
		&& cp "${cfg_file}" "${cfg_file}.old" \
		&& cp "${migration[authors-file]}" "${migration[git-dir]}/subgit/" \
		&& echo "----" \
		&& perl -pi -e "s/${domain}/${migration[default-domain]}/" "${cfg_file}" \
		&& perl -pi -e "s/${trunk}/${migration[trunk]}/" "${cfg_file}" \
		&& echo "--++" \
		&& perl -pi -e "s/${branches}/${migration[branches]}/" "${cfg_file}" \
		&& perl -pi -e "s/${tags}/${migration[tags]}/" "${cfg_file}"
}

test_init() {
	&>/dev/null diff -q "${migration[authors-file]}" \
		"${project_path}${migration[git-dir]}/subgit/${migration[authors-file]##*'/'}"
}
