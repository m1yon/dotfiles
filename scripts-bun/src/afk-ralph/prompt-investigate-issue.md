# PRD: {{prdTitle}}

{{prdDescription}}
{{progressSection}}
# Issue: {{issueIdentifier}} — {{issueTitle}}

{{issueDescription}}

{{issueComments}}

# Instructions

This is an **investigation task**. Do NOT modify files in the repo and do NOT make git commits.

1. Check if any available skills are relevant to this issue. If so, use the Skill tool to invoke them.
2. Carry out {{issueIdentifier}} as described above. Meet every acceptance criterion.
3. If the issue requires updating beads (creating/editing issues, adding comments, changing labels, etc.), use the `bd` CLI directly (`bd create`, `bd update`, `bd comment add`, `bd close`, etc.).
4. Your final response will be appended verbatim to the PRD's progress document — context for the next sub-issue agent. Keep it concise; grammar is optional. It MUST begin with a status line: `**Status:** completed` if every acceptance criterion is met, or `**Status:** blocked` if you could not finish (missing info, external dependency, unclear requirements, etc.). Be honest — do not claim completion if the work is not truly done. Then use this structure:
   **Status:** completed | blocked
   **Did:** 1-3 bullets
   **Discovered:** patterns/conventions/gotchas found in the codebase
   **For next agent:** files/commands/decisions that save time next run
   **Blockers:** required if status is `blocked` — what went wrong and what's needed to unblock
