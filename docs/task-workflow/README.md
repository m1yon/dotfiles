# Task workflow

> Be professional with my time.

This is a personal task workflow built on Getting Things Done (GTD) and the Eisenhower Matrix. It runs in plain Todoist, with no custom app. Agents help at a few fixed steps, and nothing an agent creates reaches Next or Today until you triage it.

![The workflow from capture to the Friday review](workflow.svg)

Diamonds are decisions, yellow boxes are Todoist lists, and dashed boxes are scheduled AI jobs. Purple tags mark the skill that helps at each step. Blue arrows loop back.

## Two rules hold it together

- **Three cards a day, frog first.** Each morning, date up to three cards from Next. The frog is a p2 card, the important work that never feels urgent, and it goes first.
- **Ideas wait in the Inbox.** A new idea goes to the Inbox, even when an agent could start it in seconds. Triage decides whether it ever starts.

Projects only organize cards, and nothing asks for a note when you switch tasks.

## Pages

How-to guides:

- [Triage the Inbox](triage.md)
- [Run your day](daily.md)
- [Run the Friday review](weekly-review.md)

Reference:

- [Todoist setup](todoist-setup.md) lists the projects, priorities, labels, filters, and recurring cards.
- [AI jobs](ai-jobs.md) describes the scheduled Sentry triage and stale sweep.
- [Agent rules](agent-rules.md) holds the `AGENTS.md` section and the session-start hook.
- [Skills](skills.md) describes `/inbox`, `/triage-inbox`, `/pick`, and `/weekly-review`.

Explanation:

- [Design notes](design-notes.md) covers why the guardrails ask instead of block, and what was left out on purpose.

## Build status

None of this is built yet. The diagram and these pages are the design. Build it in this order:

1. Set up Todoist, so the filters, labels, and recurring cards exist.
2. Add the agent rules and the session-start hook. They're the only pieces that run in every agent session, and agent sessions are where new work starts.
3. Write `/pick` and `/inbox`.
4. Write `/triage-inbox` and `/weekly-review` after you've used the daily steps for two weeks.
5. Build the two AI jobs.

## Edit the diagram

The diagram is a hand-written SVG, [workflow.svg](workflow.svg). A comment at its top describes the layout grid and what to move when you add a step, so an agent can edit it without other context. Render it and look at the result before you commit.
