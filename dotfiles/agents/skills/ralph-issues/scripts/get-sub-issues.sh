#!/usr/bin/env bash
# Usage: get-sub-issues.sh <owner> <repo> <issue-number>
# Output: TSV of <number>\t<state>\t<title> for each sub-issue of the given issue.
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <owner> <repo> <issue-number>" >&2
  exit 2
fi

owner="$1"
repo="$2"
number="$3"

gh api graphql \
  -H "GraphQL-Features: sub_issues" \
  -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          title
          subIssues(first: 100) {
            nodes { number title state url }
          }
        }
      }
    }' \
  -F owner="$owner" -F repo="$repo" -F number="$number" \
  --jq '.data.repository.issue.subIssues.nodes[] | [.number, .state, .title] | @tsv'
