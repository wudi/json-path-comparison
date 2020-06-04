#!/bin/bash
set -euo pipefail

readonly query_results="$1"
readonly majority_result="$2"

. ./src/shared.sh

all_implementations_and_proposals() {
    find ./implementations -name run.sh -maxdepth 2 -print0 | xargs -0 -n1 dirname | xargs -n1 basename
    find ./proposals -name run.sh -maxdepth 2 -print0 | xargs -0 -n1 dirname | xargs -n1 basename
}

matching_majority_result() {
    {
        if is_scalar_implementation "$implementation"; then
            grep '^scalar-consensus' < "${majority_result}" || grep '^consensus' < "${majority_result}"
        else
            grep '^consensus' < "${majority_result}"
        fi
    } | cut -f2
}

equals_majority_result() {
    local implementation="$1"
    local result
    result="$(query_result_payload "${query_results}/${implementation}")"

    test "$result" == "$(matching_majority_result "$implementation")"
}

main() {
    while IFS= read -r implementation; do
        if equals_majority_result "$implementation"; then
            echo "$implementation"
        fi
    done <<< "$(all_implementations_and_proposals)"
}

main
