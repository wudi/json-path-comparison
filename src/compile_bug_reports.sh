#!/bin/bash
set -euo pipefail

readonly tmp_consensus_dir="$1"
readonly target_dir="$2"

. src/shared.sh

all_implementations() {
    find ./implementations -type d -depth 1 -print0 | xargs -0 -n1 basename | sort
}

sort_by_selector() {
    xargs -n1 -I% sh -c 'echo "$(cat ./queries/%/selector)\t%"' \
        | sort \
        | cut -f2

}

all_query_results() {
    find "$tmp_consensus_dir" -type d -depth 1 -print0 | xargs -0 -n1 basename | sort_by_selector
}

indent_2() {
    sed 's/^/  /'
}

is_outlier_while_gold_standard_exists() {
    local query="$1"
    local implementation="$2"

    local consensus_dir="${tmp_consensus_dir}/${query}"

    [[ $(wc -l < "$consensus_dir"/matching_implementations) -gt 0 && -f "${consensus_dir}/outliers/${implementation}" ]]
}

header() {
    echo "Results do not match other implementations

The following queries provide results that do not match those of other implementations of JSONPath
(compare https://github.com/cburgmer/json-path-comparison/tree/master/comparison):
"
}

failing_query() {
    local query="$1"
    local consensus_dir="${tmp_consensus_dir}/${query}"
    local selector
    local document
    local gold_standard
    local result

    selector="$(cat "./queries/${query}/selector")"
    document="$(cat "./queries/${query}/document.json")"
    gold_standard="$(cat "${consensus_dir}/gold_standard.json")"
    result="$(cat "${consensus_dir}/outliers/${implementation}")"

    echo "- [ ] \`${selector}\`
  Input:
  \`\`\`
$(indent_2 <<< ${document})
  \`\`\`
  Expected output
  \`\`\`
$(indent_2 <<< ${gold_standard})
  \`\`\`
  Actual output
  \`\`\`
$(indent_2 <<< ${result})
  \`\`\`
"
}

process_implementation() {
    local implementation="$1"
    local query

    header

    while IFS= read -r query; do
        if is_outlier_while_gold_standard_exists "$query" "$implementation"; then
            failing_query "$query"
        fi
    done <<< "$(all_query_results)"
}

main() {
    local implementation

    while IFS= read -r implementation; do
        process_implementation "$implementation" > "${target_dir}/report_for_${implementation}.md"
    done <<< "$(all_implementations)"
}

main