# Maintenance protocol

Keep verified UI knowledge current without changing the mutation authorization model.

## Documentation self-updates

Make a documentation-only self-update when a fact is directly observed, reusable, non-sensitive, and fits an existing reference without weakening a protected rule.

Route changes as follows:

- Navigation, routes, tables, and control locations -> `platform-map.md`
- UI fields and mechanics -> `ui-reference.md`
- Read-only boundaries and inspection patterns -> `read-only-operations.md`
- Existing sandbox-to-production workflow details -> `workflow-sandbox-to-production.md`
- Environment gates, blockers, evidence, and persistence checks -> `safety-and-verification.md`
- Stable read-only test cases -> `regression-fixtures.md`

Prefer correcting an existing statement over appending a duplicate. Add environment and verification date when behavior may differ. Re-check conflicting observations after reload; preserve both with environment/date labels if unresolved.

## Protected workflow registry

Never automatically add, infer, broaden, rename, or remove a mutation workflow or change its authorized boundary. Never weaken the Organization Settings prohibition, mutation gate, action-time approval, production evidence, stop conditions, or protected-data rules.

A new mutation type remains prohibited until the user explicitly requests a skill update that:

1. Adds a dedicated `references/workflow-<name>.md` file with narrow authorized scope, discovery, approval, evidence, verification, and stop rules.
2. Registers that file in the top-level Approved mutation workflows table.
3. Updates safety routing where needed and passes validation.

Do not create and execute a new workflow within the same Pear Suite operation merely because a requested mutation lacks a route. Stop and ask the user to define or approve the skill change as a separate task.

After any self-update, validate links. Also run the skill validator when `SKILL.md` or metadata changed, and report which files changed.
