---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published as Todoist tasks with td, one task for a single ticket or subtasks of one parent for several.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

Tickets live in Todoist. Publish them with the `td` CLI, following the "Work tracking" rule in your global instructions. Each ticket is one PR, so each ticket is one task.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, a task ref such as `id:<id>`, or a link), fetch it and read its full body and comments (`td task view id:<id> --json --full` and `td comment list id:<id> --all`).

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window and lands as one PR
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket; green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Also name the parent task: the task the user referenced, or a new one you will create (title and project).

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets to Todoist

One ticket is one PR, so it adds no subtask, as the Work tracking rule says. With an open source task, that task is the ticket: run `td task view id:<id> --json --full`, check that it shows `"checked": false`, then add the label with `td task update id:<id> --labels <its current labels>,ready-for-agent`, because `--labels` replaces the whole list. Change nothing else on it. With no open source task, create the ticket as one top-level task: `td task add "<ticket title>" --project <project> --labels ready-for-agent --json --stdin < <body file>`, adding `--section Todo` when that project has a Todo section. Leave off the label when the user says the ticket is not for agents. Then stop.

Two or more tickets become subtasks of one parent task.

1. **Parent.** If the source was an existing task, it is the parent. Check that it is open: `td task view id:<id> --json --full` must show `"checked": false`. If it is closed, or there was no source task, create the parent: `td task add "<feature title>" --project <project> --json`. Use the project the Work tracking rule names for this repo, and add `--section Todo` when that project has a Todo section. Never create a project.
2. **Tickets, blockers first.** Add each ticket in dependency order, so its blockers already have ids. Write the body to a file, then run `td task add "<ticket title>" --parent id:<parent id> --labels ready-for-agent --json --stdin < <body file>`. Leave off `--labels ready-for-agent` when the user says the tickets are not for agents.
3. **Blocking edges.** Todoist has no native blocking links, so each body ends with a "Blocked by" section listing each blocker as `id:<id>` and its title, or "None (can start immediately)".
4. **Read back.** `td task view id:<parent id> --include-children --json` and confirm every ticket is there with its label.

Subtasks share their parent's column, so never move a ticket or its parent. Do NOT complete or edit the parent task.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

<ticket-template>

## Parent

The parent task as `id:<id>` and its title.

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- `id:<id>` and the title of each blocking ticket, or "None (can start immediately)".

</ticket-template>

Avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.
