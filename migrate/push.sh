#!/bin/bash
push() {
	cd "${project_path}"

	if [[ ! -d "${migration[git-dir]}" ]]; then
		err "push: ${migration[git-dir]}: directory not found"
		return 1
	fi
	
	cd "${migration[git-dir]}" \
		&& git remote add origin "${migration[git-url]}" \
		&& git push -u --all origin \
		&& (test -z "${migration[tags]}" || git push -u --tags origin)
}

test_push() {
	(&>/dev/null cd "${project_path}/${migration[git-dir]}" && git status)
}

test_pushed() {
	local result="$(git push --dry-run)"

	if [[ "${result}" = "Everything up-to-date" ]]; then
		return 1
	fi
}

test_ssh() {
	test -n "${SSH_AUTH_SOCK}"
}
