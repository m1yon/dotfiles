# Run your day

## Pick a frog and up to five cards each morning

The morning pick takes about five minutes. The **Morning pick** routine reminds you each workday. Run `/pick`, or follow these steps by hand:

1. Open Today. For each card left from yesterday, keep it or clear its date.
2. Open the Next filter. Look first at cards with a deadline in the next two days.
3. Choose the frog, a p2 card. `/pick` suggests the oldest p2 card, because fun work keeps pushing that one back.
4. Date cards for today until Today holds five or fewer cards from Next, counting the ones you kept. Put the frog first.

Only cards from Next count toward the five. Routines don't count.

If you've been away for a few days, `/pick` offers a fresh start before the pick. See [`/pick`](skills.md#pick).

## Work from Today

Group Today by project, so routines sit in their own group.

- Start with the frog. After that, switch between Today cards freely.
- Do routines whenever they fit in the day.
- When a card is done, complete it and take the next Today card. In an agent session, the agent offers to complete the card and names the next one.
- When your picks are done, the plan for the day is done. If you want more work, take one card from Next on purpose.

## Send new ideas to the Inbox

When a new idea comes up, add it to the Inbox and keep going. In an agent session, run `/inbox <idea>`.

If you ask an agent for work that isn't on a Today or `@waiting` card, it asks once: "Not on Today. Inbox it, or start anyway?" Either answer is fine, and it doesn't ask again in that session.

## Handle the edge cases

| If | Then |
| --- | --- |
| A picked card isn't done by evening | It shows as overdue the next morning. At the pick, keep it, which counts toward the five, or clear its date so it goes back to Next. |
| The same card carries over three mornings in a row | Split it, hand it off, or drop it. `/pick` asks. |
| You miss a routine | Complete it when you get to it. Todoist moves an overdue `every` card to its next future date, so missed days don't stack up. To skip a day, postpone it to tomorrow. |
| A card has a real due date | Set a Deadline, not a date. `/pick` lists it first from two days before the deadline. |
| Something must happen on a given day | Set a Deadline for that day. |
| Something happens at a set time | Put it in your calendar, not in Todoist. |
| An urgent p1 arrives mid-day | Add it to Today. It may take you past five, because the limit covers planned work. |
| A card is `@waiting` | It doesn't count toward the five. |
| A personal one-off comes up, like booking a dentist appointment | It goes through Next like any card and counts toward the five. |
| It's the weekend | Do routines only. The Morning pick routine repeats on workdays. |
