---
name: pearsuite-operator
description: Route safe Pear Suite work through a signed-in Chrome tab. Use for open-ended read-only inspection of sandbox or production activities, flows, questions, data IDs, actions, dependencies, and configuration, or for an explicitly registered mutation workflow such as promoting a complete activity and its dependency graph from sandbox to production. Deny mutations that do not match a registered workflow.
---

# Pear Suite Operator

Act as a router. Permit flexible read-only inspection, but permit persistent mutation only through a workflow registered in this file.

Operate only through the user's already-open, signed-in Chrome tab. Invoke and follow `chrome:control-chrome`; do not substitute another browser surface. If no suitable tab is open or authentication is missing, ask the user to open or sign in to Pear Suite in Chrome.

Read [safety-and-verification.md](references/safety-and-verification.md) before every task. Never open, inspect, read, compare, copy, export, or edit Organization Settings. The displayed organization selector label may be read only to identify the active environment.

## Route the request

1. Classify the request by its intended side effects before interacting with Pear Suite.
2. For read-only work, read [read-only-operations.md](references/read-only-operations.md). Use [platform-map.md](references/platform-map.md) and [ui-reference.md](references/ui-reference.md) only as needed. Read-only work is open-ended and does not require approval.
3. For any persistent mutation, require an exact match in the Approved mutation workflows registry below. Read that workflow file completely and follow only its authorized scope.
4. If no workflow matches, stop before filling forms, changing toggles, dragging graph nodes, or opening a create/copy action. Explain that the mutation is not registered. User approval cannot override a missing workflow.
5. Use [maintenance.md](references/maintenance.md) for verified documentation updates. Never add or broaden an approved mutation workflow automatically.

A persistent mutation is any action that creates, updates, retires, deletes, copies, imports, schedules, connects, submits, or otherwise persists Pear Suite data or configuration. Approval is necessary inside a registered workflow, but approval alone is never sufficient.

## Approved mutation workflows

| Workflow | Match only when | Workflow file | Authorized mutation boundary |
|---|---|---|---|
| Promote activity from sandbox to production | The user asks to move, copy, promote, migrate, or recreate a specific sandbox activity and its dependencies in production | [workflow-sandbox-to-production.md](references/workflow-sandbox-to-production.md) | Create or update the approved production dependency graph required by that activity; no sandbox writes, deletes, retires, member-record changes, Organization Settings, or unrelated production changes |

Do not infer new workflows from similarity. A one-off production edit, standalone create, direct sandbox edit, retirement, deletion, bulk cleanup, or other mutation is prohibited until the user explicitly asks to add an appropriate workflow to this skill and the registry is updated.

## Report the result

For read-only work, report what was inspected, the environment, and findings. For a registered mutation workflow, follow its evidence and reporting requirements. Always state whether a mutation occurred. Do not expose member data, authentication state, session identifiers, or unrelated organization information.

Use [regression-fixtures.md](references/regression-fixtures.md) only for read-only validation of documented behavior.
