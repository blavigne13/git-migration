#!/bin/bash
migrate() {
	>/dev/null load "$1" && echo "    $1 loaded" \
		&& >/dev/null init && echo "    $1 initialized" \
		&& >/dev/null clone && echo "    $1 cloned" \
		&& push && echo "    $1 pushed." \
		&& msg "$1 complete, yay!" \
		|| (msg "$1 failed, Boo!" && false)
}

gogogo() {
	(( job_count = 0 ))
	(( max_jobs = NUMBER_OF_PROCESSORS ))

	msg "\nGOGOGO!"
	info "Max concurrent migrations" "${max_jobs}"
	info "Repository migration files" "\n$(ls -1 ${glob} | sed 's/^/    /')"	

	for f in ${glob}; do
		# if max_jobs already started, wait for one to finish
		if [[ "${job_count}" -ge "${max_jobs}" ]]; then
			info "${job_count} migrations in progress" "waiting..."
			wait -n
			(( --job_count ))
		fi

		# make sure f is a regular file
		if [[ -f "${f}" ]]; then
			info "Starting migration" "${f}"
			migrate "${f}" &
			(( ++job_count ))
		fi
	done
	msg "
All jobs started!!1
	"

	# wait 1 job at a time
	while [[ ${job_count} > 0 ]]; do
		info "Waiting on in-progress migrations" "${job_count} jobs"
		wait -n
		(( --job_count ))
	done

	# double checking, in case I suck at this
	info "Waiting on remaining migrations" "(should be ${job_count} jobs)"
	jobs -r
	wait
	msg "kthxbai"
}

verify_all() {
	info "Repository migration files" "\n$(ls -1 ${glob} | sed 's/^/    /')\n"

	for f in ${glob}; do
		load "${f}" && status
		info "\nMigration file" "${f}"
		read -s -n 1 -p "Press the 'any' key to continue..."
	done
}

svn_paths_gogogo() {
    for f in ${glob}; do
    	info "Migration file" "${f}"
        load "${f}" > /dev/null && svn_paths "$@" | sed 's/^/    /'
        sep
    done
}

recent_users_gogogo() {
    local all_users=""

    for f in ${glob}; do
        >/dev/null load "${f}" && all_users+="$(recent_users_query "$@")\n"
    done

    apply_map "$(echo -e "${all_users%'\n'}" | sort | uniq -c | sort -r)"
}

old_recent_users_gogogo() {
    local all_users=""

    for f in ${glob}; do
        info "Migration file" "${f} "
        >/dev/null load "${f}" \
            && all_users+="$(recent_users_query "$@")\n" \
            && recent_users "$@"
        sep
    done

    msg "Combined"
    apply_map "$(echo -e "${all_users%'\n'}" | sort | uniq -c | sort -r)"
}
