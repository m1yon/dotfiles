---
name: weekly-review
description: Runs Michael's Friday review of Todoist. Drafts the Inbox triage, answers for the oldest cards and the waiting cards, and the feature projects to archive. Runs from the Friday 9am T3 Code schedule, or when Michael types /weekly-review.
disable-model-invocation: true
---

# Weekly review

Post every draft in one message, and apply only the answers Michael approves in this thread. The job card is the only change this skill makes without asking. Start every card you show with its priority dot.

`--labels` replaces a card's labels, so pass its current labels too.

## Draft

First run `td job-card add "weekly review"`. It puts a card on Today while the draft waits for Michael, and it changes nothing when that card is already open. Then post one message with these parts, in order:

1. **Inbox.** Follow the Read and Draft sections of [triage-inbox](../triage-inbox/SKILL.md), and include the table for its first batch.
2. **Oldest cards.** One table of the 10 cards with the earliest `addedAt` from `td task list --filter "no date & !#Inbox & !#Someday & !@waiting & !subtask" --json --all --full`. Show how many days ago each card was added, and suggest one answer: date it, Someday, delete, or leave it. For "date it", suggest the date.
3. **Waiting cards.** Each `@waiting` card with how long it has waited, its follow-up date when it has one, and a suggestion: complete it, follow up on a day, or take it back. The wait starts at the `updated` activity event whose `extraData.labels` has `waiting` and whose `lastLabels` doesn't. When the log doesn't reach that event, write "over N days" for the span the log covers.
4. **Projects to archive.** Each feature project, a child of `MECA`, `Side Projects`, or `Personal`, with no open cards.

End with: "Reply `apply` to approve every draft, or name a row and give its new answer."

## Apply

| Answer | Commands |
| --- | --- |
| Inbox rows | The Apply section of [triage-inbox](../triage-inbox/SKILL.md). After the other answers are applied, post its remaining batches one at a time. |
| Date it | `td task update id:<id> --due "<date>"`. The card leaves the oldest list until that day. |
| Someday | `td task update id:<id> --priority p4`, then `td task move id:<id> --project Someday` |
| Leave it | Nothing. The card shows again next Friday unless it gets a date. |
| Delete | `td task delete id:<id> --yes` |
| Complete | `td task complete id:<id>` |
| Follow up on `<day>` | `td task update id:<id> --due <today or YYYY-MM-DD>` |
| Take it back | Remove `waiting` and clear the date with `td task update id:<id> --labels <other labels> --no-due`, or `--no-labels --no-due` when none are left. The card goes back to Next. |
| Archive | `td project archive id:<id>` |

The review is done when every approved answer is applied. Then run `td job-card complete "weekly review"` and report the count for each answer.
