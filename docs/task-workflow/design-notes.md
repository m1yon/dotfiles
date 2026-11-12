# Design notes

## Guardrails ask instead of block

Agents make starting work nearly free, so most new work begins in an agent session. That is where the juggling starts, and it is where the guardrails sit. Each guardrail is one question with an answer that lets you continue. "Start anyway" always works, and nothing records how often you chose it. A guardrail that blocks you or keeps score gets switched off, and then it protects nothing. A question at the moment of choice keeps the choice deliberate without making it costly.

## Agents write only to the Inbox

An earlier setup let automation create cards, and the list filled with work nobody chose. Now every card an agent makes lands in the Inbox at p4, with no date. Next shows only p1 and p2 cards, and Today shows only dated cards, so nothing an agent creates reaches either one until you triage it. The AI jobs follow the same idea. Each job may change one thing: one digest card, or one label.

## The morning pick is the only limit

Earlier drafts capped active projects at three, split projects into active and parked, and asked for a short note at every task switch. Each cap added upkeep without helping focus. The switch notes added work at the moment attention is lowest. This design keeps one limit at one decision point a day. Three dated cards cap the juggling, and you switch between them freely.

## Projects only organize

A feature project groups its cards, so Next shows them together. It says nothing about what to work on. Priority and the morning pick decide that.

## Skills come with reminders

A skill helps only if you remember to run it. The two skills tied to a time of day, `/pick` and `/weekly-review`, each have a recurring Todoist card. The card shows up in Today and names the skill. The session-start hook follows the same idea. It loads Today into each agent session, so no agent has to remember to look.

## Left out on purpose

- **Hard blocks on work that isn't on Today.** They'd be turned off within a week.
- **Streaks, or a count of "start anyway" answers.** A count turns slips into guilt, and nothing in the flow uses the number.
- **A cap on parallel agent sessions.** The three-card pick already limits active work, and delegated p3 cards are meant to run without you.
- **A break timer.** A phone Pomodoro timer handles breaks, outside Todoist.
- **An impact and effort matrix.** It added a second scoring step to triage without changing which cards get picked.
- **A custom app or an AI assistant that plans the day.** The morning pick stays yours, and an app is one more thing to maintain.
