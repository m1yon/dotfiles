---
name: to-issues-native
description: Wrapper around the /to-issues skill that publishes the slices using GitHub's native sub-issue and blocked-by relationships. Use when the user wants to break a plan or PRD into GitHub issues with native parent/child links and a native dependency graph.
---

# To Issues (GitHub Native)

Thin wrapper around `/to-issues`. Kept separate so the upstream skill can change without affecting these GH-native overrides.

## Process

1. Load and follow `/to-issues`.

2. Override the publish behaviour with the GH-native equivalents below. Where the native link replaces a body-text section, drop that section from the issue body — do not write both.

## GH-native overrides

Issue ids in these endpoints are **numeric database ids**, NOT GraphQL node ids. Get one with:

```sh
gh api repos/{owner}/{repo}/issues/<number> --jq '.id'
```

**Parent linkage** — attach a child as a native sub-issue of its parent:

```sh
gh api -X POST repos/{owner}/{repo}/issues/<parent_number>/sub_issues \
  -F sub_issue_id=<child_database_id>
```

**Dependency graph** — record a blocker:

```sh
gh api -X POST repos/{owner}/{repo}/issues/<number>/dependencies/blocked_by \
  -F issue_id=<blocker_database_id>
```

Publish blockers before the issues that depend on them so the database ids exist when you wire up the graph.

Resolve `{owner}/{repo}` from `git remote -v`.
