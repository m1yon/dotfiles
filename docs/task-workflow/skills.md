# Skills

Each skill is a folder with a `SKILL.md` in `dotfiles/agents/skills`, so Claude Code and Codex both load it. `/inbox` and `/pick-next` do exactly what you ask for, so they write without a separate approval. Every other skill shows its changes and waits for your approval before it writes to Todoist.

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

## `/morning-pick`

Drafts the morning pick. A T3 Code scheduled task starts it at 9am every weekday. See [AI jobs](ai-jobs.md#morning-pick) and [Run your day](daily.md).

- Lists yesterday's unfinished picks, each with a suggested answer: keep it, or clear its date.
- Shows Next, grouped by project, with cards whose deadline is within two days first.
- Suggests the oldest p2 card as the frog. You choose the frog.
- Suggests up to five cards for today, counting the ones you keep, with the frog first. Routines don't count.
- Flags each card that has carried over three mornings in a row, and suggests splitting it, handing it off, or dropping it. It counts carry-overs from the card's activity log. Confirm that `td activity` records date changes before you rely on this count.
- Posts all the drafts in one message and waits. It dates the cards you approve in the thread. If you choose a sixth card, it asks once whether to swap one out or keep six.

If you miss the 9am run, run `/morning-pick` yourself.

### Fresh start

If Today holds work cards that are three or more days overdue, `/morning-pick` offers a fresh start before the pick. With your approval, it does these steps:

1. Clears the dates on overdue work cards. The cards stay in their projects, and the p1 and p2 cards show up in Next again. Overdue routines move to today, so their repeat schedules stay intact.
2. Adds `@stale` to cards with no activity for 21 days, by the same rule as `/weekly-review`.
3. Drafts the normal pick with no work cards on Today.

## `/pick-next`

Adds one card from Next to Today, whenever you want one. Use it after you finish your picks, or when you want to start a particular card.

- `/pick-next` with no text suggests up to three cards from Next, each with a one-line reason. Cards with a deadline within two days come first, then p1 cards, then the oldest p2 cards. If the frog is still open, it says so before it suggests anything.
- `/pick-next <text>` finds the card that matches the text and dates it for today. If the card isn't in Next yet, it asks for the card's priority first, in one question. If no card matches, it offers to add one to the Inbox.
- It counts the open cards from Next on Today. Completing a card frees a slot. If five are already open, it asks once whether to swap one out or go to six.
- It shows the picked card's description and links, so you can start.

## `/weekly-review`

Runs the Friday review. A T3 Code scheduled task starts it every Friday at 9am. See [AI jobs](ai-jobs.md#weekly-review) and [Run the Friday review](weekly-review.md).

- Adds `@stale` to cards with no activity for 21 days. This is the only change it makes without asking.
- Runs `/triage-inbox` to draft the Inbox triage.
- Shows the `@stale` cards in one table, each with a suggested answer: keep, Someday, or delete.
- Checks the PR linked on each agent-held `@waiting` card with `gh`. It reports whether the PR merged, is open, or has stalled, and offers to complete the cards whose PR merged.
- Lists feature projects with no open cards, and offers to archive them.
- Posts all the drafts in one message and waits. It applies the answers you approve in the thread.

The name avoids `/review`, which is already a code review command.
