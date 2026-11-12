---
name: pick-next
description: Dates one card from Michael's Todoist Next filter for today, suggested or named. Use for /pick-next, /pick-next <card>, "pick another card", or the "Add it to Today" answer when a request matches no Today card.
---

# Pick next

Date one card for today. Michael asked for it, so write without a separate approval. Start every card you show with its priority dot (🔴 p1, 🟠 p2, 🔵 p3, ⚪ p4) and leave out the priority label, as in `🟠 Fix appointment sync retries`. Put 🐸 after the dot on the frog, as in `🟠 🐸 Fix appointment sync retries`.

## Read

1. `td today --json --full --all` lists Today. `td filter view Next --json --all --full` lists Next.
2. An open pick is a Today card that is also in Next. Today's order is `dayOrder`, lowest first, and -1 means unordered. The frog is the open pick with the `frog` label.

## Choose the card

- **`/pick-next` with no text.** List the open picks, then suggest up to three Next cards that aren't on Today, each with a one-line reason. Order the suggestions by deadline within two days, then p1, then the oldest p2 by `addedAt`, then p3. Show them in the suggestion format below, and wait for Michael's choice.
- **`/pick-next <text>`.** Match the text to a card title in Next, then in the Inbox (`td inbox --json --all`), then in every open card (`td task list --json --all --full`). Ask when several cards match. A card planned for a later day is already filed. Name its planned day, and date it for today only if Michael says so.
  - A card in the Inbox isn't filed yet. Ask for its priority and project in one question, with a suggestion for each. Then file it with `td task update id:<id> --priority <p>` and `td task move id:<id> --project id:<project id>`.
  - When no card matches, offer to add one with `td task add "<title>"`. Then file and date it the same way.

### Suggestion format

List the open picks by priority, highest first, and keep `dayOrder` within a priority. Age is whole days from `addedAt` to today, written as `9d`, or `today` for a card created today. Keep the reason to one sentence, and don't repeat the age in it.

```markdown
## Today

You have **<n> of 5** picks open:

- <dot> <🐸 if frog> <open pick title>

## Suggested next picks

<One sentence on how you ordered them, such as "Nothing in Next is due in the next two days, so these are the three p1 cards, oldest first.">

| # | Card | Age | Why now |
|---|------|-----|---------|
| 1 | <dot> **<title>** | <age> | <one-sentence reason> |

Reply with a number, or name another Next card.
```

## Date it

1. Count the open picks. If five or more are open, ask once whether to swap one out or add one more. To swap one out, clear its date with `td task update id:<id> --no-due`.
2. Date the card with `td task update id:<id> --due today`.
3. Run `td day-order` with the open picks in their current order and the new card last. Then read `td today --json --full --all` and check the order.
4. Show the card's title, its description, and the links in its description and comments (`td comment list id:<id> --json --all`), so Michael can start.
