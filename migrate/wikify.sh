#!/bin/bash

wikify_gogogo() {
    local regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\)[[:space:]]\+<\(.*\)>.*/| \1 | \2 | \3 |/'
    local another_regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\).*/| \1 | \2 | |/'
    
    echo "
{toc}

h2. Migration Status

|| Action || Status ||
| Contact committers |  |
| Confirm maps |  |
| Migrate repository |  |
| Bamboo build |  |

h3. Comments

lorem ipsum

h3. Recent Committers (${2:-3} months)

|| Commits || Name || Email ||"
    recent_users_gogogo "$2" | sed "${regex}" | sed "${another_regex}"
    echo "
h2. Repositories"

    for f in ${glob}; do
        cd "${project_path}"
        >/dev/null load "${f}" && wikify "$1" "$2"
    done
}

wikify() {
    local regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\)[[:space:]]\+<\(.*\)>.*/| \1 | \2 | \3 |/'
    local another_regex='s/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]\+\(.*\).*/| \1 | \2 | |/'

    echo "
h3. ${migration[file]%.migration}

h4. Comments

lorem ipsum

h4. Recent Committers (${2:-3} months)

|| Commits || Name || Email ||"
    recent_users "$2" | sed "${regex}" | sed "${another_regex}"
    echo "
h4. Path map

|| SVN repo path || Maps to || Comments ||"
    svn_paths "$1" | sed 's/^/| /' | sed 's/$/ |  |  |/'
    echo "
{noformat:title=Migration map}"
    cat "${migration[file]}" | sed 's/#.*//' | egrep --invert-match '^$'
    echo "{noformat}"
}