---
name: pearsuite-operator
description: Safely inspect, create, and update Pear Suite activity and flow templates through signed-in Chrome tabs. Use when working with Pear Suite sandbox or production environments, activities, scripts, assessments, flow maps, questions, data IDs, answer types, actions, dependencies, or template migrations.
---

# Pear Suite Operator

Operate Pear Suite only through the user's already-open, signed-in Chrome tab. Invoke and follow `chrome:control-chrome`; do not substitute another browser surface. If no suitable Pear Suite tab is open or authentication is missing, stop and ask the user to open or sign in to Pear Suite in Chrome.

## Run the operation

1. Read [safety-and-verification.md](references/safety-and-verification.md) before every task. Identify the environment before any write.
2. Read [platform-map.md](references/platform-map.md) to choose the correct route and scope locators to the visible tabpanel or dialog.
3. Read [ui-workflows.md](references/ui-workflows.md) for questions/data IDs, flows, activities, and migrations. Create dependencies in this order:

   ```text
   Questions/data IDs -> Flow -> Activity
   ```

4. Inspect first. Reuse exact-title or exact-data-ID matches when they are semantically identical; pause on collisions, ambiguity, locked objects, cross-environment naming differences, or subscription warnings.
5. Require explicit user approval immediately before every persistent change in every environment, including Create, Save, Update, Retire, scheduling, and action changes. Name the environment, object, and exact change. Do not treat an earlier general request as action-time approval; approval may cover only a precisely enumerated batch.
6. For every production change, capture a relevant before screenshot before requesting approval. After approval and the write, reload, verify persistence, and capture a comparable after screenshot. Follow Chrome's screenshot guidance and retain both images for the final response. If safe evidence cannot be captured, stop before writing.

## Report the result

State the environment, object titles/data IDs, whether a write occurred, and the reload-based verification result. For a production write, attach or render the two retained images under clear `Before` and `After` labels; the After image must show the reloaded persisted state. Call out anything that remains ambiguous or blocked. Do not expose member data, authentication state, session identifiers, or unrelated organization information.

## Maintain this skill

Read [maintenance.md](references/maintenance.md) when the task reveals reusable Pear Suite behavior that is missing, changed, or contradicted here. Apply verified documentation-only updates before finishing when safe and permitted. Never weaken safety rules automatically.

Use [regression-fixtures.md](references/regression-fixtures.md) only when validating IBCLC behavior or testing future revisions to this skill.
