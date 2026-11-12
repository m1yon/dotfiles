# AI jobs

Two jobs run on a schedule. Each one changes one narrow thing, so automation can't fill Todoist with cards you didn't choose.

| Job | Schedule | Changes | Never |
| --- | --- | --- | --- |
| Sentry triage | Every 2 hours, during work hours | Rewrites the one "Sentry digest" card in the Inbox | Creates a second card |
| Stale sweep | Thursday night | Adds `@stale` to cards with no activity for 21 days | Deletes, moves, or creates cards |

## Sentry triage

- The job keeps exactly one card, titled "Sentry digest". It rewrites the card's description with the new and spiking issues since you last completed the card.
- A large spike makes the card p1 and due today. The threshold is set when the job is built.
- When you've read the digest, complete it. The job reopens the same card when new issues arrive, so the card shows up only when there's something new.

## Stale sweep

- The sweep runs Thursday night, so the Review filter is current for the Friday review.
- No activity means no edits, comments, or completed subtasks for 21 days.
- The sweep skips cards in `Someday` and recurring cards.
