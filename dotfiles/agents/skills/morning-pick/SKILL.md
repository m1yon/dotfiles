---
name: morning-pick
description: Drafts Michael's morning pick of up to five Todoist cards, frog first, and dates the cards he approves. Runs from the weekday 9am T3 Code schedule, or when Michael types /morning-pick.
disable-model-invocation: true
---

# Morning pick

Draft the pick, post it as one message, and change nothing until Michael answers in this thread. Start every card you show with its priority dot. Until Michael approves, show 🐸 only on the frog this draft suggests, right after its priority. If the current frog is a different card, its title still starts with 🐸, so leave that 🐸 out when you show it.

## Read

1. `td today --json --full --all` lists Today, overdue cards included. A routine is a card in the `Routines` project. Every other card is a work card.
2. `td filter view Next --json --all --full` lists Next.
3. `td project list --json --all` gives project names for grouping.

An open pick is a Today card that is also in Next. Today's order is `dayOrder`, lowest first, and -1 means unordered.

## Fresh start

If Today holds a work card dated three or more days ago, offer a fresh start in its own message and wait. When Michael says yes:

1. Clear the date on each overdue work card with `td task update id:<id> --no-due`. The cards stay in their projects and show in Next again.
2. Move each overdue routine to today with `td task reschedule id:<id> today`, which keeps any repeat.
3. Read Today and Next again, and draft the pick below with no work cards on Today.

When he says no, draft the pick below as usual.

## Draft

Post one message with these parts, in order:

1. **Carried over.** Each open pick dated before today, with a suggestion to keep it or clear its date. A kept card counts toward the five, and a cleared card goes back to Next. Flag each card that has carried over three mornings in a row, and suggest splitting it, handing it off, or dropping it. A card carries over the third morning when it is overdue now and was kept on each of the two weekdays before today. A keep is an event in `td activity --since <date 7 days ago> --type task --event updated --json` for the card whose `extraData.lastDueDate` and `extraData.dueDate` are both set and whose `dueDate` is the later one. Page with `--cursor` until `nextCursor` is null.
2. **Next.** The Next cards not on Today, grouped by project, with cards whose deadline is within two days first.
3. **Frog.** The oldest p2 card by `addedAt`, kept picks included. Michael chooses the frog.
4. **Today.** Up to five cards, frog first, counting the kept picks and the open picks Michael planned for today. Routines don't count.

End with: "Reply `approve`, or name the changes: a different frog, or cards in or out."

## Apply

1. If the approved picks come to more than five, ask once whether to swap one out or keep them all, and wait for the answer before any write.
2. Date each kept and each new pick with `td task update id:<id> --due today`. Clear each dropped pick with `td task update id:<id> --no-due`.
3. Move the `frog` label and the 🐸 title prefix to the frog. `td task list --filter "@frog" --json --all` lists the cards that have the label.
   - For each of those cards other than the frog, remove the label and strip the leading `🐸 ` from its title. Run `td task update id:<id> --labels <other labels> --content "<title without 🐸>"`, or `--no-labels` when none are left.
   - For the frog, add the label if it is missing. When its title lacks the prefix, set `--content "🐸 <title>"`. One call can carry both, as in `td task update id:<frog> --labels <labels>,frog --content "🐸 <title>"`.
   - `--labels` replaces a card's labels, so pass its current labels too.
4. Order Today with `td day-order id:<frog> id:<pick> ...`, listing every open pick, frog first.
5. Read `td today --json --full --all` and check that the frog has the lowest `dayOrder` of the open picks, has the `frog` label, and has a title that starts with `🐸 `. `td day-order` reports success even for an unknown id, so this read is the proof. Then run `td task list --filter "@frog" --json --all` and check that it returns only the frog.
6. Reply with the final picks in order, frog first.
