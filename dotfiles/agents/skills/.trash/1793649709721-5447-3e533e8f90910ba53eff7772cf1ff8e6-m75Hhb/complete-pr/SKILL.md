---
name: "complete-pr"
description: "Merge a PR Michael has approved once its checks pass, then complete its Linear issue and check off the Todoist mirror. Use for /complete-pr or 'complete this PR'."
---

# Complete PR

Michael calls this when he has approved a PR. Calling it is the approval: do not ask him to confirm the merge again. Wait for the checks, merge, then close the matching Linear issue(s) and their Todoist mirrors. Nothing in Linear or Todoist changes unless the merge succeeds.

## Input
The argument is a PR URL, `owner/repo#123`, or a number. With no argument, use the PR for the current branch of the repo in this session (`gh pr view --json url`). If there is still no PR, ask which one.

## Tools
- `gh` for GitHub. If it fails to authenticate or cannot see the repo, call `mcp__claude-code-remote__add_repo` with the owner, repo and `access: "push"`, then retry. If access is denied, relay the reason and stop.
- Load with one ToolSearch call: mcp__Linear__get_issue, mcp__Linear__save_issue, mcp__Linear__list_issue_statuses, mcp__Todoist__find-tasks, mcp__Todoist__find-completed-tasks, mcp__Todoist__add-comments, mcp__Todoist__complete-tasks.

## Steps

1. **Read the PR.** `gh pr view <pr> --repo <owner/repo> --json number,title,url,state,isDraft,mergeable,reviewDecision,headRefName,headRefOid,body,baseRefName`. Record `headRefOid` as SHA, the commit Michael approved.
   - Already merged: skip to step 4.
   - Closed without merge, draft, `mergeable` CONFLICTING, or `reviewDecision` CHANGES_REQUESTED: stop and say why. Change nothing.

2. **Wait for checks.** Run `gh pr checks <n> --repo <owner/repo> --watch --fail-fast --interval 30` with Bash `run_in_background: true` and a 2-hour timeout. Tell Michael in one line that you are waiting on checks.
   - All pass: continue.
   - No checks reported: treat as passed and say so in the summary.
   - Any check fails or is cancelled: stop. Report the failing check names with their links and offer `/fix-ci`. Do not merge and do not touch Linear or Todoist.
   - Timeout: report which checks are still pending and stop.

3. **Merge.** Read the allowed methods with `gh repo view <owner/repo> --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`. Use squash if allowed, else merge, else rebase. Run `gh pr merge <n> --repo <owner/repo> --<method> --delete-branch --match-head-commit <SHA>`.
   - `--match-head-commit` makes the merge fail if someone pushed after Michael approved. If that happens, stop and tell him the PR has new commits to review.
   - If branch protection or a required review blocks the merge, report the exact error and stop.
   - Confirm with `gh pr view --json state,mergedAt,mergeCommit` that state is MERGED.

4. **Find the Linear issue(s).** Collect every identifier matching `[A-Z]+-\d+` (case-insensitive, uppercase it) from the branch name, PR title, and PR body. Ignore matches that `get_issue` cannot find. If none are found, ask Michael for the issue ID; the merge stands either way.

5. **Complete each Linear issue.** `mcp__Linear__get_issue` (fields id,identifier,status,statusType,assignee,team,url).
   - statusType already "completed" (the GitHub integration often does this on merge): leave it, note it.
   - statusType "canceled": leave it, report it.
   - Not assigned to Michael: do not close it; report it and ask whether to close it anyway.
   - Otherwise `mcp__Linear__save_issue` with id = the identifier and state = the team's completed state: "Completed" for MEC; for other teams, `list_issue_statuses` and use the status of type "completed". Verify with `get_issue` that statusType is "completed". On failure, report it and leave its Todoist mirror open.

6. **Check off the Todoist mirror.** For each issue now completed in Linear, find its mirror: `mcp__Todoist__find-tasks` with projectId 6hhGx42gGrMJP7M9 (MECA), labels ["linear"], responsibleUserFiltering "all", and pick the open task whose title starts with "<identifier> ".
   - Found: add the comment "Completed by Linear sync: issue is Completed in Linear (merged <PR url>)" with notifyUsers ["none"], then complete the task. The comment is the marker that tells the hourly Linear ⇄ Todoist sync this checkoff needs no action, so add it before completing.
   - Already completed or no mirror (issue was in Backlog, say): note it; nothing to do.
   - Two open mirrors with the same prefix: complete neither; report it.
   - Never delete Todoist tasks, and never change any other Todoist or Linear field.

7. **Report.** A few lines: PR merged (method, short merge SHA, link), Linear issues completed or already completed, Todoist tasks checked off, and anything skipped with the reason.