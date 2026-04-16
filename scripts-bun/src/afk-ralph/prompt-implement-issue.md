# Epic: {{prdTitle}}

{{prdDescription}}
{{progressSection}}
# Issue: {{issueIdentifier}} — {{issueTitle}}

{{issueDescription}}

{{issueComments}}

# Instructions

1. Check if any available skills are relevant to this issue. If so, use the Skill tool to invoke them.
2. Claim the issue: `bd update {{issueIdentifier}} --claim`. This sets its status to `in_progress` and records you as the assignee.
3. Solve {{issueIdentifier}}. Meet every acceptance criterion.
4. Run the tests, linter, and type-checker. Fix any errors.
5. Append a progress entry to the on-disk progress document at `.afk-ralph/progress-<epic-id>.md` (path is relative to the repo root — you are running with the repo root as cwd). The epic id is the parent issue in the header above. The file already exists; append — do NOT overwrite. Add a new H2 block with the exact structure:

   ```
   ## {{issueIdentifier}}: {{issueTitle}}

   _<UTC ISO timestamp> · <completed|blocked>_

   **Status:** completed | blocked
   **Did:** 1-3 bullets
   **Discovered:** patterns/conventions/gotchas found in the codebase
   **For next agent:** files/commands/decisions that save time next run
   **Blockers:** required if status is `blocked` — what went wrong and what's needed to unblock
   ```

   Stage this file in the same commit as your code changes so the entry is part of the sub-issue's commit (step 6). The entry you write here should match the status block you return as your final response (step 9).
6. Commit with: `{{issueIdentifier}}: <description>`
   - In the body, note key decisions, files changed, and any blockers.
   - Make sure `.afk-ralph/progress-<epic-id>.md` is included in the commit.
7. Close the issue per the CLAUDE.md session-close workflow:
   - On success: `bd close {{issueIdentifier}}`
   - If you could not finish: `bd update {{issueIdentifier}} --status blocked --notes "<why>"`
8. Push everything — the orchestrator will NOT push for you:
   ```
   git pull --rebase
   bd dolt push
   git push
   ```
   Work is not complete until `git push` succeeds. If push fails, resolve and retry until it succeeds.
9. Your final response will be used as context for the next sub-issue agent. Keep it concise; grammar is optional. It MUST begin with a status line: `**Status:** completed` if every acceptance criterion is met, or `**Status:** blocked` if you could not finish (tests failing, missing info, external dependency, unclear requirements, etc.). Be honest — do not claim completion if the work is not truly done. Then use this structure:
   **Status:** completed | blocked
   **Did:** 1-3 bullets
   **Discovered:** patterns/conventions/gotchas found in the codebase
   **For next agent:** files/commands/decisions that save time next run
   **Blockers:** required if status is `blocked` — what went wrong and what's needed to unblock
