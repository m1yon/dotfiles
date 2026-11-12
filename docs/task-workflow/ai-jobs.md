# AI jobs

Two jobs run on a schedule. Each one makes a single narrow change on its own, so automation can't fill Todoist with cards you didn't choose. Every other change waits for your approval.

| Job | Schedule | Changes on its own | Never |
| --- | --- | --- | --- |
| Sentry triage | Every 2 hours, during work hours | Rewrites the one "Sentry digest" card in the Inbox | Creates a second card |
| Weekly review | Fridays at 9am | Adds `@stale` to cards with no activity for 21 days | Deletes, moves, or creates cards without your approval |

## Sentry triage

- The job keeps exactly one card, titled "Sentry digest". It rewrites the card's description with the new and spiking issues since you last completed the card.
- A large spike makes the card p1 and due today. The threshold is set when the job is built.
- When you've read the digest, complete it. The job reopens the same card when new issues arrive, so the card shows up only when there's something new.

## Weekly review

The weekly review is a T3 Code scheduled task that runs [`/weekly-review`](skills.md#weekly-review).

| Setting | Value |
| --- | --- |
| Prompt | `/weekly-review` |
| Schedule | `{ "type": "fixed_time", "timeOfDay": "09:00", "weekdays": [5] }` |
| Thread | A new thread for each run (`bindToCurrentThread: false`) |

- The job starts by marking stale cards. It adds `@stale` to cards with no edits, comments, or completed subtasks for 21 days. It skips cards in `Someday` and recurring cards.
- Then it drafts the rest of the review, posts it in its thread, and waits for your answers.
- The new thread is the reminder, so the Friday review has no Todoist card.
