# Design notes

## Guardrails ask instead of block

Agents make starting work nearly free, so most new work begins in an agent session. That is where the juggling starts, and it is where the guardrails sit. Each guardrail is one question with an answer that lets you continue. "Start anyway" always works, and nothing records how often you chose it. A guardrail that blocks you or keeps score gets switched off, and then it protects nothing. A question at the moment of choice keeps the choice deliberate without making it costly.

## Agents write only to the Inbox

An earlier setup let automation create cards, and the list filled with work nobody chose. Now every card an agent makes lands in the Inbox at p4, with no date. Next shows only p1 and p2 cards, and Today shows only dated cards, so nothing an agent creates reaches either one until you triage it. The AI jobs follow the same idea. Each job may change one thing: one digest card, or one label.

## The morning pick is the only limit

Earlier drafts capped active projects at three, split projects into active and parked, and asked for a short note at every task switch. Each cap added upkeep without helping focus. The switch notes added work at the moment attention is lowest. This design keeps one limit at one decision point a day. Five cards from Next, with a frog first, cap the juggling, and you switch between them freely.

Routines sit outside the limit. Meditating or doing the budget repeats on its own schedule and doesn't compete with project work, so counting routines would only shrink the room for the work the limit protects. An earlier draft capped the day at three cards and counted everything on Today, which left it unclear what the number meant.

## Dates mean planned for today

A date on a work card means you plan to work on it today, and only the morning pick sets one. Real due dates go in the Deadline field. As a result, an overdue card is always one you picked and didn't finish, and the next morning pick settles it. Today doubles as the in-progress list. A card on Today for a second morning is multi-day work you're still on, so there's no separate in-progress state to keep current.

## Projects only organize

A feature project groups its cards, so Next shows them together. It says nothing about what to work on. Priority and the morning pick decide that.

## Skills come with reminders

A skill helps only if you remember to run it. `/pick` has a recurring Todoist card that shows up in Today and names the skill. `/weekly-review` goes a step further. A T3 Code scheduled task runs it at 9am on Friday, so the drafts are ready when you open its thread. The session-start hook follows the same idea. It loads Today into each agent session, so no agent has to remember to look.

## The stale sweep runs inside the weekly review

An earlier draft ran the stale sweep as its own Thursday-night job. Its only purpose was to feed the Friday review. Running it as the first step of the review removes a job and a schedule, and the `@stale` labels are minutes old when you see them.

## Left out on purpose

- **Hard blocks on work that isn't on Today.** They'd be turned off within a week.
- **Streaks, or a count of "start anyway" answers.** A count turns slips into guilt, and nothing in the flow uses the number.
- **A cap on parallel agent sessions.** The five-card pick already limits active work, and delegated p3 cards are meant to run without you.
- **A Doing state or an `@doing` label.** You'd update it at every start and pause, which is the per-switch upkeep this design avoids. Today already shows what's in progress.
- **Sizing cards, as in the 1-3-5 rule.** Sizing every card is upkeep that doesn't change which cards get picked.
- **A break timer.** A phone Pomodoro timer handles breaks, outside Todoist.
- **An impact and effort matrix.** It added a second scoring step to triage without changing which cards get picked.
- **A custom app or an AI assistant that plans the day.** The morning pick stays yours, and an app is one more thing to maintain.
