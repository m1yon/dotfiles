---
name: ralph-issues
description: Completes GitHub PRD sub-issues in dependency order by spawning a fresh Claude task per issue. Each subagent pulls the issue via gh CLI, implements it, runs tests and lint, commits, and closes the issue. Use when user wants to iteratively work through linked GitHub sub-issues under a parent PRD.
---

# Ralph Issues

Complete the sub-issues of a parent PRD GitHub issue, one fresh subagent per issue. The orchestrator surveys open issues, groups them by PRD with children already dependency-sorted, confirms with the user, then dispatches; each subagent pulls its assigned issue, does the work, closes the issue, and appends notes for future subagents.

## Quick start

1. **Survey issues** — spawn a subagent to pull every open issue and return them grouped by PRD, with each PRD's children already topologically sorted by `Blocked by #N`.
2. **Pick the PRD** — present the report, let the user choose which PRD to work through.
3. **Dispatch loop** — for each open sub-issue in order, spawn a fresh subagent. Wait for result. On blocker, ask the user.

## Orchestrator workflow

### 1. Survey open issues and pick a PRD

Resolve the current repo first: `gh repo view --json nameWithOwner -q .nameWithOwner` → `<owner>/<repo>`.

Then spawn a fresh `general-purpose` subagent with the prompt below. It returns a grouped list of open issues organized by PRD, with children already topologically sorted by `Blocked by #N` dependencies.

<subagent-prompt>
Survey all open GitHub issues in <owner>/<repo> and return them grouped by PRD with dependency-ordered children.

Convention used by this repo:
- A child issue's body contains a `## Parent` section followed by `#<N>`, where `#<N>` is the parent PRD's issue number.
- An issue's body may list `Blocked by #<N>` references (typically in a "Blocked by" section, sometimes inline) indicating dependencies on sibling issues.

Steps:
1. Fetch all open issues with bodies in one call:
   `gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,title,body`
2. For each issue, parse:
   - Parent ref: the first `#<digits>` that appears after a `## Parent` section header.
   - Blockers: every `Blocked by #<digits>` mention in the body.
3. Group issues by parent. An issue referenced as a parent by at least one child is a "PRD".
4. Within each PRD, topologically sort its children (children with no unresolved blockers first, then children whose blockers are all earlier in the order). On cycles or blockers pointing outside the PRD, fall back to ascending issue-number order and note the anomaly next to the affected child.
5. Sort PRDs by their own issue number ascending.

Output format (markdown, nothing else):

## PRDs

### PRD #<N> — <title>
1. #<child-number> — <child-title> (blockers: none | #X, #Y)
2. ...

### PRD #<N> — <title>
1. ...

## Orphans (open issues with no parent and not referenced as a parent)
- #<N> — <title>
- ...

## Anomalies
- Brief notes on cycles, external blockers, or parsing oddities. Omit this section entirely if none.

Keep the report under 300 lines. Do not include issue bodies or extra prose.
</subagent-prompt>

Present the returned report verbatim to the user and ask which PRD they want to work on. Do not proceed until they pick one.

If the subagent reports no PRDs, tell the user and ask for a PRD URL or issue number. Then re-dispatch the same subagent with a narrowed prompt that fetches that specific issue's referencing children.

### 2. Dispatch loop

All work happens on the **current branch** — no per-issue branching. The ordered sub-issue list for the chosen PRD (from step 1) is the queue.

For each issue in order, spawn a fresh general-purpose subagent. Pass the prompt template below. Wait for it to return, then:

- **done**: continue to the next issue.
- **failed**: pause. Show the blocker to the user. Resume only after direction (skip / retry / stop).
- **already-done**: subagent found the issue already closed — skip and continue.

Do not continue inline in the orchestrator. Every issue gets a fresh subagent.

Task prompt template (substitute `<N>`, `<PRD>`, `<PRD-URL>`, `<owner>`, `<repo>`):

```
Complete GitHub issue #<N> in <owner>/<repo>. This issue is a sub-issue of PRD #<PRD>: <PRD-URL>

Progress file: progress-<PRD>.txt at repo root. Prior subagents record Summary + Advice there — read it fully before planning your work.

Work on the current branch only — do not create, switch, or push branches.

1. FIRST, read the parent PRD for overall context: `gh issue view <PRD> --repo <owner>/<repo> --comments`. Understand the bigger goal before touching the sub-issue.
2. Read progress-<PRD>.txt if it exists. Carry forward any relevant advice from prior subagents.
3. Read the sub-issue: `gh issue view <N> --repo <owner>/<repo> --comments`. If it is already closed, stop and return Status: already-done.
4. Implement the required changes. Stay within the scope of the sub-issue, but use the PRD to resolve ambiguity.
5. Run tests. Use `task test` if a Taskfile exists, else the repo's standard.
6. Run lint. Use `task lint` if a Taskfile exists, else the repo's standard.
7. Both must pass. If either fails and you cannot resolve it within scope, STOP: do not commit, do not close the issue. Append a `failed` entry (see step 9) and return.
8. Commit with message: "<type>: <short title> (fixes #<N>)"
9. Append a new section to progress-<PRD>.txt. If the file does not exist, start it with `# PRD #<PRD> — <prd-title>` on line 1.

   ## #<N> — <done|failed> — <ISO-timestamp> — <commit-sha-or-dash>

   Summary: one paragraph on what you did / what blocked you. Include files touched.

   Advice: notes for future subagents — gotchas, conventions, flaky tests, modules to avoid. "none" if none.

10. On success, close the GitHub issue: `gh issue close <N> --repo <owner>/<repo> --comment "Completed in <commit-sha>."`
11. Return a short status to the orchestrator:
    - Status: done | failed | already-done
    - Commit SHA (if done)
    - Blocker: brief description (if failed)
```

### 3. Completion

- Summarize: completed N, failed K, skipped M.
- Suggest pushing the branch and opening a PR referencing the PRD.

## Notes

- Each subagent runs in a fresh context. The progress file is the only channel between subagents.
- The issue-running subagent owns `progress-*.txt`. The orchestrator never reads or writes it.
- Add `progress-*.txt` to `.gitignore` if not present.
- Subagents close their own issues via `gh issue close`. The orchestrator does not.
- Do NOT close the parent PRD issue — let it close when all children are closed (or let the user close it).
