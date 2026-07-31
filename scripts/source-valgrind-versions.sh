#!/usr/bin/env sh

set -e

if [ -n "${GUNGRAUN_ACTION_DEBUG}" ]; then set -x; fi

VALGRIND_SOURCE_REPO='git://sourceware.org/git/valgrind.git'
max_attempts=5
attempt=1
last_error=''

while [ "$attempt" -le "$max_attempts" ]; do
    if output="$(git ls-remote "$VALGRIND_SOURCE_REPO" 2>&1)"; then
        versions="$(printf '%s\n' "$output" |
            awk '/VALGRIND_/ { match($0, /[0-9]+_[0-9]+_[0-9]+/); print substr($0, RSTART, RLENGTH) }' |
            sort -uV |
            tr '_' '.')"

        if [ -n "$versions" ]; then
            printf '%s\n' "$versions"
            exit 0
        fi
    else
        last_error="$output"
    fi

    attempt=$((attempt + 1))
    if [ "$attempt" -le "$max_attempts" ]; then
        max_delay=$((10 << (attempt - 2)))
        if [ "$max_delay" -gt 120 ]; then max_delay=120; fi
        sleep "$(awk -v max="$max_delay" 'BEGIN{srand(); printf "%d", 1+int(max*rand())}')"
    fi
done

echo "Failed to determine Valgrind source versions from ${VALGRIND_SOURCE_REPO}" >&2
if [ -n "$last_error" ]; then
    printf '%s\n' "$last_error" >&2
fi
exit 1
