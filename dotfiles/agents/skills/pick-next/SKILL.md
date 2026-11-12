---
name: pick-next
description: Dates one card from Michael's Todoist Next filter for today, suggested or named. Use for /pick-next, /pick-next <card>, "pick another card", or the "Pick it" answer to "Not on Today".
---

# Pick next

Date one card for today. Michael asked for it, so write without a separate approval. Start every card you show with its priority dot.

## Read

1. `td today --json --full --all` lists Today. `td filter view Next --json --all --full` lists Next.
2. An open pick is a Today card that is also in Next. Today's order is `dayOrder`, lowest first, and -1 means unordered. The frog is the open pick with the `frog` label.

## Choose the card

- **`/pick-next` with no text.** If the frog is still open, say so first. Then suggest up to three Next cards that aren't on Today, each with a one-line reason. Order them by deadline within two days, then p1, then the oldest p2 by `addedAt`, then p3. Wait for Michael's choice.
- **`/pick-next <text>`.** Match the text to a card title in Next, then in the Inbox (`td inbox --json --all`), then in every open card (`td task list --json --all --full`). Ask when several cards match. A card planned for a later day is already filed. Name its planned day, and date it for today only if Michael says so.
  - A card in the Inbox isn't filed yet. Ask for its priority and project in one question, with a suggestion for each. Then file it with `td task update id:<id> --priority <p>` and `td task move id:<id> --project id:<project id>`.
  - When no card matches, offer to add one with `td task add "<title>"`. Then file and date it the same way.

## Date it

1. Count the open picks. If five or more are open, ask once whether to swap one out or add one more. To swap one out, clear its date with `td task update id:<id> --no-due`.
2. Date the card with `td task update id:<id> --due today`.
3. Run `td day-order` with the open picks in their current order and the new card last. Then read `td today --json --full --all` and check the order.
4. Show the card's title, its description, and the links in its description and comments (`td comment list id:<id> --json --all`), so Michael can start.
