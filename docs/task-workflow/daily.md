# Run your day

## Approve the morning pick

At 9am each weekday, a T3 Code scheduled task runs `/morning-pick` in a new thread. It drafts the pick and waits there for you. Open the thread, choose the frog, and approve or change the cards. The pick takes about five minutes. See [AI jobs](ai-jobs.md#morning-pick).

To pick by hand instead, follow these steps:

1. Open Today. For each card left from yesterday, keep it or clear its date.
2. Check each follow-up on Today, a `@waiting` card with a date, and answer it. See [the edge cases](#handle-the-edge-cases).
3. Open the Next filter. Look first at cards with a deadline in the next two days.
4. Choose the frog, a p2 card. `/morning-pick` suggests the oldest p2 card, because fun work keeps pushing that one back. Move the `@frog` label to the new frog, start its title with 🐸, and remove both from the old frog.
5. Date cards for today until Today holds five or fewer open cards from Next, counting the ones you kept and the ones you planned for today. Put the frog first.

Only open cards from Next count toward the five. Routines and follow-ups don't count.

If you've been away for a few days, `/morning-pick` offers a fresh start before the pick. See [Fresh start](skills.md#fresh-start).

## Work from Today

Group Today by project, so routines sit in their own group.

- Start with the frog. After that, switch between Today cards freely.
- Do routines whenever they fit in the day.
- A job card on Today, such as `weekly review`, means a scheduled job waits for you in its T3 Code thread. Open the thread and answer there. The job completes the card when you're done.
- When a card is done, complete it and take the next Today card. When an agent finishes a card's work, the last line of its reply links to the card, so you can open it in Todoist and check it off. You can also tell the agent to complete the card. Agents don't offer.

## Pick another card

Completing a card frees a slot. To fill it, run `/pick-next`. It suggests up to three cards from Next and dates the one you choose. To start a particular card, run `/pick-next <card>`. See [`/pick-next`](skills.md#pick-next).

When Today has no open picks left, the plan for the day is done. Run `/pick-next` only if you want more work.

## Send new ideas to the Inbox

When a new idea comes up, add it to the Inbox and keep going. In an agent session, run `/inbox <idea>`.

If you ask an agent for work that isn't on a Today or `@waiting` card, it asks once with a numbered menu that shows how many of your five picks are open. "Add it to Today" adds the card to the Inbox and runs `/pick-next` for it, which asks for a priority and a project and dates the card. "Save it to the Inbox" adds the card and stops. "Start now" goes ahead without a card. When five picks are already open, the menu leaves out "Add it to Today". To swap a pick out instead, run `/pick-next`. Any answer is fine, and the agent doesn't ask again in that session.

## Handle the edge cases

| If | Then |
| --- | --- |
| A picked card isn't done by evening | It shows as overdue the next morning. `/morning-pick` suggests keeping it, which counts toward the five, or clearing its date so it goes back to Next. |
| The same card carries over three mornings in a row | Split it, hand it off, or drop it. `/morning-pick` flags it. |
| You miss a routine | Complete it when you get to it. Todoist moves an overdue `every` card to its next future date, so missed days don't stack up. To skip a day, postpone it to tomorrow. |
| A card has a hard deadline | Set a Deadline. `/morning-pick` and `/pick-next` list it first from two days before the deadline. |
| You plan to do a card on a given day | Give it that date. It stays out of Next until then, unless its deadline is within two days. That morning it is on Today, and it counts toward the five. |
| Something happens at a set time | Put it in your calendar, not in Todoist. |
| An urgent p1 arrives mid-day | Add it to Today. It may take you past five, because the limit covers planned work. |
| An agent works on a card | It counts toward the five. The agent's work is your work. |
| A card's PR is open | The card stays on Today and counts toward the five. Complete it when the PR merges. |
| A person or a third party takes over a card | Add `@waiting`. Then give the card the day to check on it, or clear its date. The card leaves the five. With a date, it shows on Today that day. With no date, the Friday review checks on it. |
| A follow-up is on Today | Check on the person or third party, then answer it. If it's still waiting, follow up on a day, which can be today. If you have no day to check, clear its date, and the Friday review checks on it. If the work is done, complete it. If you do the work yourself, take it back by removing `@waiting` and its date, and the card goes back to Next. `/morning-pick` suggests following up today. |
| A personal one-off comes up, like booking a dentist appointment | It goes through Next like any card and counts toward the five. |
| You miss the 9am run | Run `/morning-pick` yourself. |
| It's the weekend | Do routines only. The morning pick runs on weekdays. Run `/pick-next` if you want a card. |
