---
name: ralph-issues
description: Completes GitHub PRD sub-issues in dependency order by spawning a fresh Claude task per issue. Each subagent pulls the issue via gh CLI, implements it, runs tests and lint, commits, and closes the issue. Use when user wants to iteratively work through linked GitHub sub-issues under a parent PRD.
---

# Ralph Issues

Complete the sub-issues of a parent PRD GitHub issue, one fresh `TaskCreate` per issue. The orchestrator auto-discovers the PRD and its sub-issues, confirms with the user, then dispatches; each subagent pulls its assigned issue, does the work, closes the issue, and appends notes for future subagents.

## Quick start

1. **Discover the PRD** — resolve repo from `gh repo view --json nameWithOwner`, then `scripts/find-prds.sh <owner> <repo>`. Confirm with user.
2. **Discover sub-issues** — `scripts/get-sub-issues.sh <owner> <repo> <prd-number>`. Show list and confirm.
3. **Order by dependencies** (parse `Blocked by #N` from issue bodies; else API order).
4. **For each open sub-issue**: spawn a fresh `TaskCreate` with the issue number + PRD link. Wait for result. On blocker, ask the user.

## Orchestrator workflow

### 1. Discover PRD

Never ask the user up front. Discover, then confirm.

1. Resolve the current repo: `gh repo view --json nameWithOwner -q .nameWithOwner` → `<owner>/<repo>`.
2. List PRD candidates (open issues with sub-issues, most-recently-updated first):

   ```
   scripts/find-prds.sh <owner> <repo>
   ```

   Outputs TSV: `<number>\t<sub-issue-count>\t<title>`.
3. Pick + confirm:
   - **One candidate**: show `#<N> — <title> (<count> sub-issues)` and ask the user to confirm.
   - **Multiple candidates**: show the full list and ask the user which one.
   - **Zero candidates**: tell the user none were found and ask for a PRD URL or issue number.
4. Do not proceed to dispatch until the user has explicitly confirmed the PRD.

### 2. Discover sub-issues

Always fetch from the API, even if sub-issue numbers appear in conversation — the API is the source of truth:

```
scripts/get-sub-issues.sh <owner> <repo> <prd-number>
```

Outputs TSV: `<number>\t<state>\t<title>`. Keep only `OPEN`. Show the filtered list to the user and confirm before dispatching.

### 3. Dependency order

For each open sub-issue body (`gh issue view <N>`), grep for `Blocked by #<N>`. Topological sort. On cycles or missing refs, fall back to API order and warn the user.

### 4. Dispatch loop

All work happens on the **current branch** — no per-issue branching.

For each issue in order, spawn a fresh `TaskCreate` (general-purpose subagent). Pass the prompt template below. Wait for it to return, then:

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

### 5. Completion

- Summarize: completed N, failed K, skipped M.
- Suggest pushing the branch and opening a PR referencing the PRD.

## Notes

- Each `TaskCreate` is a fresh context. The progress file is the only channel between subagents.
- The subagent owns `progress-*.txt`. The orchestrator never reads or writes it.
- Add `progress-*.txt` to `.gitignore` if not present.
- Subagents close their own issues via `gh issue close`. The orchestrator does not.
- Do NOT close the parent PRD issue — let it close when all children are closed (or let the user close it).
