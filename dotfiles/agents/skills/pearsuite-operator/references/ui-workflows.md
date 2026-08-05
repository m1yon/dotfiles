# UI workflows

This file began from a successful agentic Pear Suite session supplied by the user and was checked against the signed-in production UI on 2026-08-05.

## Questions and data IDs

Questions live under **Data Management -> Questions**, not under Templates.

To create a question:

1. Search `By Data ID or Title` and inspect every exact data-ID match. Treat a row as reusable only when its title, question text, type, and options also match.
2. Select `Create Question`.
3. In `Select or Write Data ID`, type the exact data ID and choose the custom `+ Create {ID}` option when the data record does not exist.
4. Enter the Question Title and rich-text Question Text. Add tags only when requested.
5. Select the answer type and configure its answers.
6. Create, reload, search again, and verify all fields.

Custom dropdown options may render outside the dialog. When text matches are ambiguous, scope to the visible `[role="listbox"]` and the active option. Do not click a same-named item elsewhere on the page.

Observed answer types:

```text
True/False
Choose One
Choose Many
Number
Decimal
Text
Date
Read Only Text
```

For `Choose One`, add every answer through `Add Item -> enter text -> Save`. Preserve requested capitalization and order. Verify the rendered answers after reload.

## Flows

Flows live under **Templates -> Flows**. The creation dialog currently offers `Assessment`, `Script`, and `Journey`.

To build or update a question flow:

1. Search for the exact flow title. Expand version rows when necessary; do not assume the visible version is the intended editable version.
2. Create or locate each question by exact data ID and semantic match.
3. Drag each question card from the right Questions panel onto the React Flow canvas.
4. Connect Start and question nodes by dragging source handles to target handles.
5. Configure question or answer actions from the corresponding action control.
6. Select `Fit View`, save, reload, and verify the graph, node order, connections, answers, and actions.

The flow builder exposes `Save Changes`, `Zoom In`, `Zoom Out`, and `Fit View`. A disabled `Save Changes` button is not proof of persistence.

### Schedule an activity from an answer

```text
Answer action
-> Schedule Activity
-> Select activity template
-> Add Action
```

Match the activity by exact production title. Pause if the sandbox and production dependency names differ.

## Activities

Activities live under **Templates -> Activities**.

The activity editor currently contains:

- Title and Description
- `Allow members to perform this activity directly`
- `Enable billing on template`
- `Allow cross-organization scheduling`
- Optional Review Request on Completion, Calculations on Completion, and Tags
- Tasks and Member Reminders

To create an activity:

1. Search production `By Title` for the exact title and inspect any match.
2. Open `Add Activity Template` only when no equivalent template exists.
3. Enter the requested fields without changing optional settings unless specified.
4. Add tasks in dependency order and attach the exact template.
5. Save once, reload, reopen by exact title, and verify every task and setting.

Adding a task defaults its Type to `Assessment`. Explicitly change it to `Script` when attaching a script flow. Current task-type options are:

```text
Email
Assessment
Script
Journey
Group Event
```

The create page may label its persistent button `Update Activity Template`; verify the route and record existence rather than trusting the verb.

## Cross-environment migration

1. Inventory the source object's title, type, questions/data IDs, answers, graph connections, actions, and activity dependencies without editing the source.
2. Switch to the target environment and re-run every exact-match search there.
3. Build missing questions/data IDs first, then the flow, then the activity.
4. Pause on any title, answer, type, version, locked-state, or dependency-name mismatch.
5. Reload and verify each dependency before creating its consumer.

Never assume identically positioned rows or similarly named dependencies are equivalent across environments.
