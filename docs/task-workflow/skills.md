# Skills

Each skill is a folder with a `SKILL.md` in `dotfiles/agents/skills`, so Claude Code and Codex both load it. `/inbox` only adds Inbox cards, so it writes without asking. Every other skill shows its changes and waits for your approval before it writes to Todoist.

## `/inbox`

Adds a card to the Inbox without leaving the current work.

- `/inbox <idea>` adds one card at p4 with no date. The description holds the repo, the branch, and one sentence of context from the session.
- `/inbox` with no text adds the side work listed at the end of the agent's last reply, one card per item.
- The skill asks no questions. The agent goes back to the current work.

## `/triage-inbox`

Drafts the daily triage. See [Triage the Inbox](triage.md).

- Reads every Inbox card.
- Drafts an answer for each card: actionable or not, under 2 minutes or not, a priority, and a project.
- Shows the drafts as one table, with the under-2-minute cards first.
- Applies the rows you approve. "apply" approves every row. To change a row, name it and give the new answer.
- Adds `@waiting` to p3 cards. For an Obsidian answer, it adds the card's text to a note with the `obsidian-vault` skill, then deletes the card.

## `/pick`

Runs the morning pick. See [Run your day](daily.md).

- Shows yesterday's unfinished cards and asks whether to keep each one.
- Shows Next, grouped by project.
- Suggests the oldest p2 card as the frog.
- Dates cards for today until Today holds three or fewer, and puts the frog first.
- If you choose a fourth card, it asks once whether to swap one out or keep four.

### Fresh start

If Today holds cards that are three or more days overdue, `/pick` offers a fresh start before the pick. With your approval, it does these steps:

1. Clears the dates on overdue cards. The cards stay in their projects, and the p1 and p2 cards show up in Next again.
2. Adds `@stale` to cards with no activity for 21 days, by the same rule as the stale sweep.
3. Runs the normal pick on an empty Today.

## `/weekly-review`

Runs the Friday review. See [Run the Friday review](weekly-review.md).

- Runs `/triage-inbox` to empty the Inbox.
- Shows the `@stale` cards in one table, each with a suggested answer: keep, Someday, or delete.
- Checks the PR linked on each agent-held `@waiting` card with `gh`. It reports whether the PR merged, is open, or has stalled, and offers to complete the cards whose PR merged.
- Lists feature projects with no open cards, and offers to archive them.

The name avoids `/review`, which is already a code review command.
