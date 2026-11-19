---
name: weekly-review
description: Runs Michael's Friday review of Todoist. Marks stale cards, then drafts the Inbox triage, the stale and waiting answers, and the feature projects to archive. Runs from the Friday 9am T3 Code schedule, or when Michael types /weekly-review.
disable-model-invocation: true
---

# Weekly review

Mark stale cards first. That is the only change this skill makes without asking. Then post every draft in one message, and apply only the answers Michael approves in this thread. Start every card you show with its priority dot, and put 🐸 after the priority on the frog.

`--labels` replaces a card's labels, so pass its current labels too.

## Mark stale cards

A card is stale when all of these hold:

- It is open, outside `Someday`, and has no repeating date (`due.isRecurring`).
- It was added more than 21 days ago (`addedAt`).
- It had no edits, comments, or completed subtasks in the last 21 days.

Two kinds of edit don't count, because jobs make them without a decision about the card:

- A move made outside the Todoist apps. Agent moves are bulk runs or triage. A triage move comes with a priority change, and that change counts.
- A label change that only adds `stale`, adds `frog`, or removes `frog`. Removing `stale` counts, because that is the Keep answer.

1. Run `todoist-stale`. It applies this rule and prints the stale cards as a JSON array of `id`, `content`, and `labels`.
2. Add `stale` to each listed card that lacks it with `td task update id:<id> --labels <labels>,stale`.

## Draft

Post one message with these parts, in order:

1. **Inbox.** Follow the Read and Draft sections of [triage-inbox](../triage-inbox/SKILL.md), and include the table for its first batch.
2. **Stale cards.** One table of `@stale` cards, each with a suggestion: keep, Someday, or delete.
3. **Waiting cards.** Each `@waiting` card with how long it has waited, and a suggestion: complete it, follow up, or take it back. The wait starts at the `updated` activity event whose `extraData.labels` has `waiting` and whose `lastLabels` doesn't. When the log doesn't reach that event, write "over N days" for the span the log covers.
4. **Projects to archive.** Each feature project, a child of `MECA`, `Side Projects`, or `Personal`, with no open cards.

End with: "Reply `apply` to approve every draft, or name a row and give its new answer."

## Apply

| Answer | Commands |
| --- | --- |
| Inbox rows | The Apply section of [triage-inbox](../triage-inbox/SKILL.md). After the other answers are applied, post its remaining batches one at a time. |
| Keep | Remove `stale` with `td task update id:<id> --labels <other labels>`, or `--no-labels` when none are left. |
| Someday | Remove `stale` as above, run `td task update id:<id> --priority p4 --no-due`, then `td task move id:<id> --project Someday`. |
| Delete | `td task delete id:<id> --yes` |
| Complete | `td task complete id:<id>` |
| Follow up | Nothing in Todoist. Michael follows up himself. |
| Take it back | Remove `waiting` with `td task update id:<id> --labels <other labels>`, or `--no-labels` when none are left. |
| Archive | `td project archive id:<id>` |

The review is done when every approved answer is applied. Report the count for each answer.
