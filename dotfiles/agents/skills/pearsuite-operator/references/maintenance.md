# Maintenance protocol

Keep the skill current when a Pear Suite task reveals stable, reusable UI knowledge.

## Update automatically

Make a documentation-only self-update when all are true:

1. The fact was observed directly in the current signed-in Pear Suite UI or verified after reload.
2. It is reusable across future tasks, not member-specific or a one-off transient state.
3. It does not include personal, clinical, authentication, session, or secret data.
4. It fits an existing reference file without weakening a safety rule.

Examples: changed route, renamed control, new answer type, new task type, a newly verified persistence failure, or a locator-scoping requirement.

## Route the change

- Navigation, routes, tables, and control locations -> `platform-map.md`
- Question, flow, activity, or migration procedures -> `ui-workflows.md`
- Environment gates, blockers, and persistence checks -> `safety-and-verification.md`
- Stable test cases -> `regression-fixtures.md`
- Core orchestration or trigger scope -> `SKILL.md`

Split a growing workflow into a new one-level reference file when a section becomes hard to scan. Add the new file directly to `SKILL.md`; do not create nested reference chains.

## Evidence and conflict handling

- Add `Verified in <environment> on YYYY-MM-DD` for environment-sensitive observations.
- Prefer correcting an existing statement over appending a duplicate.
- If a new observation conflicts with an older one, re-check after reload. If still unresolved, preserve both observations with environment/date labels and report the conflict.
- Do not generalize from sandbox to production or from one flow type to another without verification.
- Do not change the environment gate, approval behavior, production screenshot evidence requirement, stop conditions, or protected-data rules automatically. Propose those changes to the user.

After a self-update, run the skill validator when `SKILL.md` or metadata changed. Briefly report which reference changed and why.
