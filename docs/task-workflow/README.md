# Task workflow

> Be professional with my time.

This is a personal task workflow built on Getting Things Done (GTD) and the Eisenhower Matrix. It runs in plain Todoist, with no custom app. Agents help at a few fixed steps, and nothing an agent creates reaches Next or Today until you triage it.

![The workflow from capture to the Friday review](workflow.svg)

Diamonds are decisions, yellow boxes are Todoist lists, and dashed boxes are scheduled AI jobs. Purple tags mark the skill that helps at each step. Blue arrows loop back.

## Two rules hold it together

- **Five open cards, frog first.** Each morning, pick a frog and date up to five cards from Next. The frog is a p2 card, the important work that never feels urgent, and it goes first. A card counts whether you work on it yourself or through an agent. Completing a card frees a slot for `/pick-next`. Routines, like meditating, don't count toward the five.
- **Ideas wait in the Inbox.** A new idea goes to the Inbox, even when an agent could start it in seconds. Triage decides whether it ever starts.

Projects only organize cards, and nothing asks for a note when you switch tasks.

## Pages

How-to guides:

- [Triage the Inbox](triage.md)
- [Run your day](daily.md)
- [Run the Friday review](weekly-review.md)

Reference:

- [Todoist setup](todoist-setup.md) is the target layout: the projects, priorities, labels, filters, dates, and routines.
- [AI jobs](ai-jobs.md) describes the two scheduled jobs, the morning pick and the weekly review.
- [Agent rules](agent-rules.md) holds the `AGENTS.md` section, the session-start hook, and the `agent-guard` check.
- [Skills](skills.md) describes `/inbox`, `/triage-inbox`, `/morning-pick`, `/pick-next`, and `/weekly-review`.

Explanation:

- [Design notes](design-notes.md) covers why the guardrails ask instead of block, why this version tracks no PRs, and what was left out on purpose.

## Build status

The repo parts are built: steps 1, 4, and 5. The other steps change Todoist and T3 Code, and they run once, after the repo change merges. Build it in this order:

1. Built. Remove the pieces this design replaces. Turn off the orchestrator service in the Nix config, and keep its repo for later. Delete the `group-tasks-into-projects` skill and its scheduled run.
2. Export every open Todoist card to a backup file.
3. Make Todoist match [Todoist setup](todoist-setup.md). Create what's missing, and delete the labels and filters that the page doesn't list.
4. Built. Write `/inbox`, `/triage-inbox`, `/morning-pick`, `/pick-next`, and `/weekly-review`.
5. Built. Add the `AGENTS.md` section, the session-start hook, and the `agent-guard` check from [Agent rules](agent-rules.md).
6. Schedule `/morning-pick` and `/weekly-review` in T3 Code. See [AI jobs](ai-jobs.md).
7. Move every open card outside `Someday` to the Inbox at p4. Then delete every section, and archive every project that [Todoist setup](todoist-setup.md) doesn't list. Deleting a section deletes the cards in it, so check that each section is empty first.
8. Sort the Inbox with `/triage-inbox`.

## Edit the diagram

The diagram is a hand-written SVG, [workflow.svg](workflow.svg). A comment at its top describes the layout grid and what to move when you add a step, so an agent can edit it without other context. Render it and look at the result before you commit.
