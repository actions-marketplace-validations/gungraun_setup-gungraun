#!/usr/bin/env sh

set -e

if [ -n "${GUNGRAUN_ACTION_DEBUG}" ]; then set -x; fi

VALGRIND_SOURCE_REPO='https://sourceware.org/git/valgrind.git'
max_attempts=5
attempt=1
last_error=''

while [ "$attempt" -le "$max_attempts" ]; do
    output="$(git ls-remote "$VALGRIND_SOURCE_REPO" 2>&1)" || {
        last_error="$output"
        attempt=$((attempt + 1))
        continue
    }

    versions="$(printf '%s\n' "$output" |
        awk '/VALGRIND_/ { match($0, /[0-9]+_[0-9]+_[0-9]+/); print substr($0, RSTART, RLENGTH) }' |
        sort -uV |
        tr '_' '.')"

    if [ -n "$versions" ]; then
        printf '%s\n' "$versions"
        exit 0
    fi

    last_error="$output"
    attempt=$((attempt + 1))

    sleep "$(awk -v a="1" -v b="30" 'BEGIN{srand(); printf "%d", a+int((b-a+1)*rand())}')"
done

echo "Failed to determine Valgrind source versions from ${VALGRIND_SOURCE_REPO}" >&2
if [ -n "$last_error" ]; then
    printf '%s\n' "$last_error" >&2
fi
exit 1
