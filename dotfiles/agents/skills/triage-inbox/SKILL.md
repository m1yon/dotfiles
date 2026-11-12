---
name: triage-inbox
description: Drafts the triage of Michael's Todoist Inbox in batches of up to 10 cards and applies the rows he approves. Use for /triage-inbox, "triage my Inbox", or the Inbox step of the weekly review.
---

# Triage the Inbox

Work through the Inbox in batches of up to 10 top-level cards, in the order `td inbox` lists them. For each batch, draft an answer for every card, post the drafts as one table, and write to Todoist only after Michael approves. Apply the batch before you draft the next one. An Inbox of 10 cards or fewer is one batch.

## Show the reference

Once per run, at the top of the first batch's reply, show `eisenhower-triage.png` from this skill's base directory as a Markdown image with its absolute path, such as `![Inbox triage reference](<base directory>/eisenhower-triage.png)`. Don't show it again in later batches. `eisenhower.svg` is its source. After you edit the SVG, rebuild the PNG with `rsvg-convert -z 1.5 eisenhower.svg -o eisenhower-triage.png`.

## Read

1. `td inbox --json --all --full`. Draft the top-level cards. A subtask moves with its parent.
2. `td project list --json --all`. The areas are `MECA` (Meca Therapies work), `Side Projects` (other code and tooling), and `Personal` (life admin, such as booking a dentist appointment). A feature project is a child of an area. `Someday` and `Routines` are top level.

## Draft

Answer these questions for each card, in order:

1. **Actionable?** If not, the answer is Delete, Someday, or Obsidian.
2. **Under 2 minutes?** Mark it Do now. It still gets a priority and a project, for when Michael doesn't get to it.
3. **Eisenhower quadrant?** p1 is urgent and important. p2 is important but not urgent. p3 is urgent but not important. A card that is neither gets Delete.
4. **Project?** The feature project the card belongs to, or its area for a one-off. A card with a repeating date (`due.isRecurring`) gets `Routines` at p4. A new routine without a repeating date gets `Routines` at p4 and a suggested due string, such as `every day` or `every! week`. When a group of cards is one new feature with more than a week of work, suggest a new feature project under its area.
5. **Waiting?** Add `@waiting` only when Michael says a person or a third party holds the card.

A card's date is the day Michael plans to work on it, and its deadline is the day it is due. Keep both as they are, except where an answer below clears them. When Michael gives a row a planned day or a deadline, apply it with `td task update id:<id> --due <YYYY-MM-DD>` or `--deadline <YYYY-MM-DD>`.

Post the batch as one table with these columns: row number, card, suggestion, and a reason of a few words. The suggestion is the card's answer. For a Do now card, end it with "Do now", such as "🟠 p2, Personal, Do now". Start each suggestion with a dot in its Todoist priority color: 🔴 p1, 🟠 p2, 🔵 p3, ⚪ p4 (Routines and Someday), and ⚫ Delete or Obsidian. Put the Do now rows first. Above the table, write the batch number and how many cards are left after it, such as "Batch 2 of 9, 72 cards after this one". End with: "Reply `apply` to approve every row, or name a row and give its new answer."

Match this format:

```markdown
Batch 1 of 9, 71 cards after this one.

| # | Card | Suggestion | Reason |
|---|---|---|---|
| 1 | renew car registration | 🔴 p1, Personal, Do now | Due Friday, takes a minute online |
| 2 | create home repo for meca therapies github | 🟠 p2, MECA | Useful for agents, nothing due |
| 3 | send invoice to MECA | ⚪ p4, Routines | Repeats every 15th |
| 4 | look into new note app | ⚫ Delete | No reason to act |

Reply `apply` to approve every row, or name a row and give its new answer.
```

## Apply

Apply only the approved rows. `--labels` replaces a card's labels, so pass its current labels too.

| Answer | Commands |
| --- | --- |
| Delete | `td task delete id:<id> --yes` |
| Someday | `td task update id:<id> --priority p4 --no-due`, then `td task move id:<id> --project Someday` |
| Obsidian | Add the card's title and description to a note with the `obsidian-vault` skill, then delete the card. |
| p1, p2, or p3 | `td task update id:<id> --priority <p>`, then `td task move id:<id> --project id:<project id>` |
| New feature project | `td project create --name "<name>" --parent id:<area id> --json` first, then file the card into it. |
| Routines | `td task update id:<id> --priority p4`, plus `--due "<due string>"` for a new routine, then `td task move id:<id> --project Routines` |
| Waiting | `td task update id:<id> --labels <labels>,waiting --no-due` |
| Do now | Complete it with `td task complete id:<id>` once Michael says it's done. Otherwise file it by its priority and project. |

After a batch is applied, read the Inbox again and draft the next 10 cards. Skip the cards Michael held back earlier in this run. If Michael asks to stop, stop after the current batch is applied.

The triage is done when every batch is applied and `td inbox --json --all` lists only the cards Michael held back. Report the count for each answer across all batches.
