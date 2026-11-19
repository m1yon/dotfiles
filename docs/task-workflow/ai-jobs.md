# AI jobs

Two jobs run on a schedule. Each one makes only narrow changes on its own, so automation can't fill Todoist with cards you didn't choose. Every other change waits for your approval.

| Job | Schedule | Changes on its own | Never |
| --- | --- | --- | --- |
| Morning pick | Weekdays at 9am | Nothing | Dates, moves, or creates cards without your approval |
| Weekly review | Fridays at 9am | Adds one [job card](#job-cards) while it waits for you | Dates, deletes, or moves cards, or creates any other card, without your approval |

Both jobs are T3 Code scheduled tasks. Each run opens a new thread. The morning pick has no Todoist card, so its new thread is the reminder. The weekly review adds a card to Today while it waits for you. On Fridays, both start at 9am in separate threads.

## Morning pick

The morning pick runs [`/morning-pick`](skills.md#morning-pick).

| Setting | Value |
| --- | --- |
| Prompt | `/morning-pick` |
| Schedule | `{ "type": "fixed_time", "timeOfDay": "09:00", "weekdays": [1, 2, 3, 4, 5] }` |
| Thread | A new thread for each run (`bindToCurrentThread: false`) |

- The job drafts the pick, posts it in its thread, and waits for your answers.
- It changes nothing until you approve. If you skip the thread, Today keeps yesterday's cards, and they show as overdue.

## Weekly review

The weekly review runs [`/weekly-review`](skills.md#weekly-review).

| Setting | Value |
| --- | --- |
| Prompt | `/weekly-review` |
| Schedule | `{ "type": "fixed_time", "timeOfDay": "09:00", "weekdays": [5] }` |
| Thread | A new thread for each run (`bindToCurrentThread: false`) |

- The job adds the `weekly review` job card, drafts the review, and posts the drafts in its thread.
- It waits for your answers. When it has applied every answer you approved, it completes the card.

## Job cards

A job card puts a scheduled job on Today while the job waits for your input. A job adds its card only when it needs you, and completes the card when you are done. [Design notes](design-notes.md#agents-write-only-to-the-inbox) explains why a job doesn't use a recurring routine card instead.

- A job card is a card in `Routines`, dated today, at p4. Its description says that a scheduled job is waiting in its T3 Code thread.
- Each job has one card, named for the job. A job that runs while its card is still open adds no second card.
- Because the card is in `Routines`, it stays out of Next and out of the five-card pick. `/morning-pick` treats it as a routine, so a fresh start doesn't clear it.
- The weekly review uses the title `weekly review`. It adds the card before it posts its drafts, and completes the card when every approved answer is applied.
- The YNAB reconcile job, in the `m1yon/ynab` repo, uses the same command with its own title.

Jobs add and complete the card with `td job-card`. See [`td job-card`](agent-rules.md#td-job-card).
