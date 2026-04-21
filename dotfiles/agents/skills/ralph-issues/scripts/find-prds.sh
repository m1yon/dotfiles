#!/usr/bin/env bash
# Usage: find-prds.sh <owner> <repo>
# Output: TSV of <number>\t<sub-issue-count>\t<title> for each open issue
# that has at least one sub-issue (i.e. PRD candidates), most-recently
# updated first.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <owner> <repo>" >&2
  exit 2
fi

owner="$1"
repo="$2"

gh api graphql \
  -H "GraphQL-Features: sub_issues" \
  -f query='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        issues(first: 50, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
          nodes {
            number
            title
            subIssues(first: 1) { totalCount }
          }
        }
      }
    }' \
  -F owner="$owner" -F repo="$repo" \
  --jq '.data.repository.issues.nodes[] | select(.subIssues.totalCount > 0) | [.number, .subIssues.totalCount, .title] | @tsv'
