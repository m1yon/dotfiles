---
name: pr-feedback-to-issues
description: Convert PR review feedback into GitHub issues that agents can independently pick up. Fetches unresolved comments via agh CLI, auto-filters noise, groups by logical concern, deduplicates against existing issues, creates issues via gh CLI, and replies on the PR with issue links. Use when user wants to turn PR feedback into issues, create issues from review comments, or track PR feedback as issues.
allowed-tools:
  - Bash(agh:*)
  - Bash(gh:*)
  - Bash(git:*)
---

# PR Feedback to Issues

Convert unresolved PR review feedback into standalone GitHub issues, grouped by logical concern, that an agent can pick up independently.

---

## Phase 1: Fetch & Identify PR

1. Get the current PR number and repo:
   ```bash
   gh pr view --json number,url,title,headRefName --jq '{number, url, title, branch: .headRefName}'
   ```
   If no PR exists for the current branch, stop and inform the user.

2. Fetch unresolved feedback:
   ```bash
   agh get-pr-feedback
   ```
   Output is a JSON array. Each item has: `type`, `commentType` (`"review"`, `"issue"`, or `null`), `commentId`, `threadId`, `user`, `body`, `path`, `line`, `lineRange`, `referencedCode`, `date`, `url`.

3. If no feedback items, report "No unresolved feedback found" and stop.

---

## Phase 2: Auto-Filter

Remove non-actionable items. Drop any item where:
- The body is purely an acknowledgment ("LGTM", "Looks good", "Thanks", "+1", thumbs up, etc.)
- `commentType` is `null` AND the body contains no concrete ask or suggestion (review summaries that are just approval)
- The body is only a question with no implied change request

Keep items that contain a concrete suggestion, bug report, request for change, or actionable feedback — even if phrased as a question (e.g., "Should this handle nil?").

If all items are filtered out, report "No actionable feedback found" and stop.

---

## Phase 3: Group by Concern

Analyze the remaining items and group them by logical task — the way a developer would tackle them together:
- Comments about the same concern across files go together (e.g., "missing error handling" in 3 places)
- Unrelated comments on the same file stay separate (e.g., security fix vs typo)
- Each group should be a coherent unit of work

---

## Phase 4: Deduplicate

1. Ensure the `pr-feedback` label exists:
   ```bash
   gh label create pr-feedback --description "Tracked from PR review feedback" --color "c5def5" 2>/dev/null || true
   ```

2. Fetch existing open issues with the label:
   ```bash
   gh issue list --label pr-feedback --state open --json body --jq '.[].body'
   ```

3. For each group, check if ALL of its comment URLs already appear in existing issue bodies. If so, skip the entire group. If some comments are new, include the full group (the issue body will contain all comments, existing and new).

---

## Phase 5: Create Issues

For each non-duplicate group, create an issue via `gh issue create`.

**Title:** A concise description of the concern (not the reviewer's words verbatim — synthesize).

**Body format:**
```markdown
Relates to PR #{pr_number}

## Feedback

{For each comment in the group:}

### {path}:{line} (@{user})

> {quoted comment body}

```{language}
{referencedCode}
```

[View comment]({url})

{End for each}
```

**Command:**
```bash
gh issue create --title "TITLE" --label "pr-feedback" --body "$(cat <<'EOF'
BODY_HERE
EOF
)"
```

Capture the issue number from the output.

---

## Phase 6: Reply on PR

For each comment that was included in a created issue, reply on the PR:
```bash
agh reply-to-comment --comment-id COMMENT_ID --type COMMENT_TYPE --body "Tracked in #ISSUE_NUMBER"
```

- Skip items with `commentType: null` (review summaries cannot be replied to).
- All comments in the same group get the same issue number.

---

## Phase 7: Summary

Print a summary:
```
## PR Feedback Issues Created

**Created:** {N} issues from {M} feedback items
**Skipped (noise):** {N} non-actionable items
**Skipped (duplicate):** {N} already-tracked items

Issues:
- #{num}: {title}
- #{num}: {title}
```

---

## Common Mistakes

- Don't create issues for non-actionable feedback — auto-filter must run first.
- Don't group by file — group by logical concern/theme.
- Don't create duplicate issues — always check existing `pr-feedback` issues for comment URLs.
- Don't reply to items with `commentType: null` — review summaries have no comment endpoint.
- Don't assign issues to anyone — leave unassigned.
- Don't forget the PR reference ("Relates to PR #N") in the issue body.
