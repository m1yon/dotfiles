# Read-only operations

Read-only work is open-ended and does not require user approval. It may inspect Pear Suite configuration in sandbox or production except Organization Settings.

## Allowed

- Identify the environment from the URL and displayed organization selector label.
- Navigate to safe Pear Suite areas and inspect existing activities, flows, versions, questions, data IDs, answers, actions, dependencies, and visible template configuration.
- Search, filter, paginate, expand rows, open existing objects, zoom, and use `Fit View` when these actions do not alter persistent state.
- Compare sandbox and production configuration and report mismatches, quality concerns, risks, or a proposed migration manifest.
- Capture relevant non-sensitive screenshots when requested or useful for a read-only report.

## Read-only boundary

Do not select Create, Copy, Import, Export, Retire, Delete, Save, Update, Submit, Add Action, or another control that may persist or transmit data. Do not fill creation or edit forms, change toggles, reorder tasks, drag nodes, connect handles, or modify answer controls.

Opening an existing detail or builder page for inspection is allowed. If an editor exposes editable controls, inspect their displayed state without interacting with them. Search boxes, filters, tabs, pagination, zoom, and Fit View remain allowed when they do not persist configuration.

If the task changes from inspection to mutation, return to the top-level router. Proceed only if the requested mutation exactly matches a registered workflow; otherwise stop.

## Report

State the environment and objects inspected, distinguish observations from inferences, and flag uncertainty. Do not imply that a proposed change was made. Avoid member-level pages and do not include personal, clinical, authentication, or unrelated organization data.
