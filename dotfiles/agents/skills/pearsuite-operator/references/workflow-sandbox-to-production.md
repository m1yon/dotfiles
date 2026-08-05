# Approved workflow: Promote activity from sandbox to production

This is a registered mutation workflow. Use it only when the top-level router matches a request to reproduce a specific sandbox activity and its complete dependency graph in production.

## Authorized scope

Inspect sandbox read-only. In production, create or update only the approved questions/data definitions, prerequisite action targets, flows, activity, and directly required referenced templates discovered for the selected activity.

This workflow does not authorize sandbox writes, deletes, retires, member-record changes, Organization Settings, unrelated production cleanup, or standalone production edits. Stop if the requested or discovered work crosses that boundary.

## Phase 1: Build the dependency manifest

Start from the exact sandbox activity and recursively inventory:

- Activity title, description, tags, tasks and order, task types, template selections, member reminders, review request, completion calculations, billing, direct-member access, cross-organization scheduling, and other visible settings.
- Every attached flow's title, type, version, lock state, questions, node order, connections, branches, multi-output settings, question actions, answer actions, and referenced entities.
- Every question's data ID, title, rich-text prompt, answer type, answer options and order, tags, and separately visible data definition.
- Every transitive action dependency, including scheduled activities, nested flows, journeys, goals, emails, calculations, review requests, or other templates.

Explicitly exclude Organization Settings. Continue until every allowed dependency is in the migration or identified as an existing external production dependency.

Use this manifest shape:

| Entity | Sandbox identity | Used by | Production match | Planned action | Findings |
|---|---|---|---|---|---|
| Question/data, flow, activity, or allowed dependency | Exact ID/title/type/version | Parent entity/action | Missing, identical, conflicting, or ambiguous | Create, reuse, update, or block | Audit notes |

## Phase 2: Audit the sandbox source

Before any production write, check for:

- Duplicate, inconsistent, misleading, placeholder-like, or nonconforming data IDs and titles; one data ID used for different semantics; suspicious spelling, casing, or numbering gaps.
- Disconnected or unreachable nodes, missing or wrong Start connections, unintended dead ends, incorrect branches, incomplete multi-output configuration, or actions attached to the wrong answer.
- Flow and task-type mismatches, stale versions, locked or retired objects, missing templates, sandbox-only dependencies, or circular dependencies.
- Answer types that do not fit their questions, duplicated or malformed options, unexpected order, and missing answers or actions.
- Activity settings that appear accidental or risky, especially billing, direct-member access, cross-organization scheduling, reminders, review requests, and completion calculations.
- Internal inconsistencies between titles, prompts, answers, actions, and downstream dependencies.

Treat naming concerns as recommendations unless a known convention proves them invalid. Explain suspected clinical-source defects plainly and without blame. Never silently repair, normalize, rename, or improve the source.

## Phase 3: Compare production and report preflight

Search production for every exact title and data ID. Compare semantic fields, not only names. Classify each entity:

- `Reuse`: semantically identical.
- `Create`: no equivalent exists.
- `Update`: the intended object exists but differs; enumerate every difference.
- `Block`: collision, ambiguity, unsafe configuration, missing dependency, circular dependency, or unresolved source concern.

Give the user a preflight report with the full entity scope, ordered production plan, all source-quality findings, every environment mismatch, required decisions, and planned screenshot evidence. Ask the user to choose copy-as-is, approved correction, or exclusion for each finding.

Do not begin production mutation until every blocker is resolved and the final manifest is stable.

## Phase 4: Capture evidence and obtain approval

1. Reconfirm the production URL and organization selector label without opening Organization Settings.
2. Capture Before evidence showing the current production state or absence of each target. Group objects only when one image clearly establishes the full batch baseline.
3. Request explicit action-time approval for the final enumerated manifest. A general request to migrate is not approval.
4. If approval changes or discoveries expand the scope, stop, update the manifest, and request new approval.

## Phase 5: Migrate and verify

1. Create or update only approved entities in dependency order: questions/data IDs, prerequisite action targets, flows in topological order, then the activity.
2. Reload and verify each entity before creating a consumer that depends on it.
3. Never overwrite an ambiguous object or create a suffixed duplicate as a workaround.
4. Stop on a circular dependency; do not invent a shell-object workaround without a separately registered workflow.
5. Capture comparable After evidence from the reloaded production state for every changed object or clearly evidenced batch.

## Phase 6: Reconcile and report

Compare production against the approved manifest field by field. Confirm all intended questions/data definitions, answers, nodes, connections, actions, settings, tasks, versions, and dependencies; confirm no extra entity or unapproved correction was introduced.

Report created, updated, reused, skipped, and blocked entities separately. Include labeled Before and After production screenshots. The After evidence must show the reloaded persisted state. Call out every intentional approved difference from sandbox and any remaining uncertainty.
