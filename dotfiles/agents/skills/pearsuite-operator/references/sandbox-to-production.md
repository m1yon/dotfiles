# Sandbox-to-production activity migration

Treat Pear Suite sandbox as the clinical team's staging environment and production as the controlled deployment target. Inspect sandbox read-only. Reproduce the approved sandbox configuration in production; do not edit sandbox as part of a migration.

Explicitly exclude Organization Settings from discovery, comparison, screenshots, migration, and reconciliation. They are intentionally different between sandbox and production and must never be opened or read.

Sandbox is a source candidate, not proof that the design is production-ready. Clinical users may create valid clinical content while accidentally misconfiguring technical details. Audit respectfully and describe possible defects without blame.

## Phase 1: Build the dependency manifest

Start from the exact sandbox activity and recursively inventory every entity needed to reproduce it:

- Activity title, description, tags, tasks and order, task types, template selections, member reminders, review request, completion calculations, billing, direct-member access, cross-organization scheduling, and other visible settings.
- Every attached flow's exact title, type, version, lock state, questions, node order, connections, branches, multi-output settings, question actions, answer actions, and referenced entities.
- Every question's data ID, title, rich-text prompt, answer type, answer options and order, tags, and underlying data definition when separately visible.
- Every transitive action dependency, including scheduled activities, nested flows, journeys, goals, emails, calculations, review requests, or other templates.

Continue until every allowed dependency is either in the migration or identified as an existing external production dependency. Do not assume a similarly named object is equivalent, and never treat Organization Settings as a dependency.

Create a working manifest with these fields:

| Entity | Sandbox identity | Used by | Production match | Planned action | Findings |
|---|---|---|---|---|---|
| Question/data, flow, activity, or other dependency | Exact ID/title/type/version | Parent entity/action | Missing, identical, conflicting, or ambiguous | Create, reuse, update, or block | Audit notes |

## Phase 2: Audit the sandbox source

Complete the audit before requesting approval or writing to production. Check for:

- Duplicate, inconsistent, misleading, placeholder-like, or nonconforming data IDs and titles; the same data ID used for different semantics; spelling, casing, or numbering gaps that could indicate a mistake.
- Disconnected or unreachable flow nodes, a missing or incorrect Start connection, unintended dead ends, wrong branch connections, incomplete multi-output configuration, or actions attached to the wrong answer.
- Flow type and activity task-type mismatches, wrong or stale versions, locked or retired objects, missing templates, and sandbox-only dependencies.
- Answer types that do not fit the question, duplicated or malformed options, unexpected option order, and missing answers or actions.
- Activity settings that appear accidental or operationally risky, especially billing, direct-member access, cross-organization scheduling, reminders, review requests, and completion calculations.
- Internal inconsistencies between titles, question text, answers, actions, and downstream dependencies.

Infer naming conventions only from established nearby Pear Suite data IDs or user-provided conventions. Label a naming concern as a recommendation unless a known rule proves it invalid.

Do not silently repair, normalize, rename, or improve the clinical team's source. A correction changes the migration from an exact copy into an engineering decision.

## Phase 3: Compare production and report preflight

Search production for every exact title and data ID in the manifest. Compare all semantic fields, not only names. Classify each target as:

- `Reuse`: production is semantically identical.
- `Create`: no production equivalent exists.
- `Update`: an intended production object exists but differs; enumerate every difference.
- `Block`: collision, ambiguity, unsafe configuration, missing dependency, circular dependency, or unresolved source concern.

Before any production write, give the user a preflight report containing:

1. The sandbox source activity and complete entity scope.
2. The ordered production plan: reuse, create, update, and blocked items.
3. Every suspected source defect or naming concern, with evidence, likely impact, and a recommended resolution.
4. Every sandbox/production mismatch and dependency mapping that requires judgment.
5. The planned Before/After screenshot evidence for the production objects or coherent batches.

Ask the user to decide whether each flagged item should be copied exactly, corrected for production, or excluded. Do not begin production work while any required decision or blocker remains.

## Phase 4: Obtain approval and migrate

After the user resolves the preflight findings:

1. Reconfirm the production URL and organization selector.
2. Capture Before evidence showing the existing production state or absence of each target object. Group screenshots only when one image clearly proves the baseline for the entire approved batch.
3. Request explicit action-time approval for the final enumerated manifest. A general request to migrate the activity is not sufficient approval.
4. Create or update approved entities in dependency order: questions/data IDs, prerequisite action targets, flows in topological order, then the activity.
5. Reload and verify each entity before creating a consumer that depends on it.
6. Capture comparable After evidence from the reloaded production state for each changed object or clearly evidenced batch.

Reuse a production entity only after proving semantic equivalence. Never overwrite a conflicting object or create a suffixed duplicate as a workaround. Pause and request new approval if a new dependency, mismatch, or scope change appears during execution.

If an action creates a circular dependency, such as a new flow scheduling the new activity that will contain that flow, stop and present the cycle. Do not invent a temporary shell-object workaround without explicit user direction and approval.

## Phase 5: Reconcile

Compare the verified production result against the approved manifest field by field. Confirm:

- Every intended question/data definition, answer, flow node, connection, action, setting, task, and dependency exists.
- Every reused production object still matches the required semantics.
- No extra entity or unapproved correction was introduced.
- The activity references the intended production versions and exact dependency titles.

Report created, updated, reused, skipped, and blocked entities separately. Include all required labeled Before and After production screenshots. Call out any remaining difference from sandbox, including an intentional correction approved during preflight.
