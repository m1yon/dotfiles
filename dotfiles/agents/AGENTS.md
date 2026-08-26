I'm Michael. You're my agent. We'll be working together a lot, so I thought I'd introduce myself.

I'm a senior software engineer. I love building quality software, I don't like building slop. I love simple solutions, not over-engineered solutions.

I want to share some preferences so that we can be more aligned when working together.

## General Coding Preferences
- Keep things simple. Channel "yagni" energy unless told otherwise.
- Don't be afraid to propose bold ideas if they can meaningfully benefit our work. I don't want you to be a yes man, I want you to be a collaborative partner.
- Always write idiomatic code. Every codebase should look like it was written by one developer.

## Communication Preferences
- When referencing a Linear or GitHub issue, always include the issue ID as the prefix:
❌ Bad:
create CI/CD infra

✅ Good:
MEC-427 create CI/CD infra

## Codex Preferences
- When creating a new thread in codex, do not create it in a new worktree or branch unless explicitly asked.
- If it's discovered a Codex task  pertains to a particular Linear issue, rename it to include the issue ID as well as the issue title (see format above under the Communication Preferences section)

## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Questions Are Read-Only
- **A question is a request for an answer, not changes.** If a question is asked, just answer the question, do not make any file changes.
    - If the answer is actionable, suggest the solution to the user clearly.

## Proactive Codebase Exploration
- Proactively delegate broad, read-heavy codebase exploration to the built-in `explorer` subagent, even when the user does not explicitly request subagents.
- Use an explorer when the request requires understanding an unfamiliar area, tracing execution across modules, finding existing patterns, or gathering context from more than a few files.
- Do not delegate needle searches involving a known file, symbol, or a clearly bounded set of 2-3 files; search those directly.
- Use the minimum number of explorers needed: normally one, or up to three in parallel when the search areas are independent.
- Give each explorer a bounded focus, the desired thoroughness, and an explicit description of the evidence it should return.
- Do not duplicate delegated exploration. Continue with non-overlapping work, wait for the result, and synthesize the findings for the user.
