# PRD: {{prdTitle}}

{{prdDescription}}
{{progressSection}}
# Issue: {{issueIdentifier}} — {{issueTitle}}

{{issueDescription}}

{{issueComments}}

# Instructions

1. Check if any available skills are relevant to this issue. If so, use the Skill tool to invoke them.
2. Solve {{issueIdentifier}}. Meet every acceptance criterion.
3. Run the tests, linter, and type-checker. Fix any errors.
4. Commit with: `{{issueIdentifier}}: <description>`
   - In the body, note key decisions, files changed, and any blockers.
5. Your final response will be appended verbatim to the PRD's progress document — context for the next sub-issue agent. Keep it concise; grammar is optional. Use this structure:
   **Did:** 1-3 bullets
   **Discovered:** patterns/conventions/gotchas found in the codebase
   **For next agent:** files/commands/decisions that save time next run
   **Blockers:** (optional) anything unresolved

Do NOT push to git — the orchestrator handles that.
