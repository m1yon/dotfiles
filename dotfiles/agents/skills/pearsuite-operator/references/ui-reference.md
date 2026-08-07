# UI reference

Reference only: this file describes controls and mechanics but does not authorize mutation. A persistent action may use these instructions only when the top-level router selected a registered workflow whose scope includes that action.

Verified against the signed-in production UI on 2026-08-05.

## Questions and data IDs

Questions live under **Data Management -> Questions**, not under Templates.

The question creation form contains:

- `Select or Write Data ID`
- Question Title
- Rich-text Question Text
- Tags
- Answer Type

When a registered workflow creates a question:

1. Search `By Data ID or Title` and inspect every exact data-ID match. Reuse only when title, question text, type, and options also match.
2. In `Select or Write Data ID`, type the exact data ID and choose the custom `+ Create {ID}` option when the data record does not exist.
3. Enter the approved title, prompt, tags, answer type, and answers without normalization.
4. Create, reload, search again, and verify every field.

Custom dropdown options may render outside the dialog. Scope ambiguous matches to the visible `[role="listbox"]` and active option.

When exact rich-text spacing matters, create an intentional blank paragraph with two Enter presses instead of relying on pasted newline normalization. Reload the saved question and verify the rendered paragraph structure.

The question editor may display a data-ID type suffix as `undefined` even when the backing data record has a valid type. Treat this as ambiguous UI state: verify the exact data ID and type under **Data Management -> Data** before classifying or reusing it.

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

For `Choose One`, add each answer through `Add Item -> enter text -> Save`. Preserve approved capitalization and order.

## Flows

Flows live under **Templates -> Flows**. The creation dialog currently offers `Assessment`, `Script`, and `Journey`.

When a registered workflow builds a flow:

1. Search the exact title and expand versions when needed.
2. Create or locate every approved question by exact data ID and semantic match.
3. Drag question cards from the right panel onto the React Flow canvas.
4. Connect Start and question nodes from source handles to target handles.
5. Configure approved question and answer actions.
6. Collapse the Builder sidebar with the top-left arrow, use `Fit View`, save, reload, collapse the sidebar again if it reopened, and verify graph structure, answers, and actions. Use the collapsed, fitted view for comparable flow screenshots.

The builder exposes `Save Changes`, `Zoom In`, `Zoom Out`, and `Fit View`. A disabled `Save Changes` button is not proof of persistence.

Scheduling an activity from an answer uses:

```text
Answer action
-> Schedule Activity
-> Select activity template
-> Add Action
```

## Activities

Activities live under **Templates -> Activities**. The editor currently includes:

- Title and Description
- Direct-member access, billing, and cross-organization scheduling toggles
- Optional Review Request on Completion, Calculations on Completion, and Tags
- Tasks and Member Reminders

When a registered workflow builds an activity:

1. Search the exact production title and inspect any match.
2. Open `Add Activity Template` only when the approved plan classifies it as Create.
3. Enter only approved fields and settings.
4. Add tasks in approved dependency order and attach exact templates.
5. Save, reload, reopen by exact title, and verify every task and setting.

Adding a task defaults to `Assessment`. Explicitly select the approved type. Current options are:

```text
Email
Assessment
Script
Journey
Group Event
```

The create page may label its persistent button `Update Activity Template`; use route and record state rather than button wording to determine whether an object exists.
