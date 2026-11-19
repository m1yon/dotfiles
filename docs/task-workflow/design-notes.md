# Design notes

## Guardrails ask instead of block

Agents make starting work nearly free, so most new work begins in an agent session. That is where the juggling starts, and it is where the guardrails sit. Each guardrail is one question with an answer that lets you continue. "Start now" always works, and nothing records how often you chose it. A guardrail that blocks you or keeps score gets switched off, and then it protects nothing. A question at the moment of choice keeps the choice deliberate without making it costly.

## Agents write only to the Inbox

An earlier setup let automation create cards, and the list filled with work nobody chose. Now every card an agent makes in a session lands in the Inbox at p4, with no date. Next shows only p1 to p3 cards, and Today shows only dated cards, so nothing an agent creates in a session reaches either one until you triage it. "Add it to Today" goes through the Inbox too. The agent adds the card there, and `/pick-next` files and dates it with your answer.

This rule is a block, not a question. The `agent-guard` hook stops any agent command that adds a card outside the Inbox or adds one with a priority or a date. The case for asking instead of blocking is about guardrails on you. An agent in a session never needs to put a new card anywhere else, so a hard block costs nothing.

A scheduled job that needs your input is the one exception. It adds a job card to `Routines`, dated today, and completes the card when you're done. A recurring routine card was the other option, but it follows the calendar instead of the job. A job card is on Today only while a thread waits for you. `td job-card` keeps one open card for each job title. The card sits in `Routines`, so it stays out of Next and out of the five picks. The `agent-guard` hook still blocks every other command that adds a card outside the Inbox.

The AI jobs follow the same idea. The morning pick changes nothing until you approve. The weekly review adds one job card on its own.

## The morning pick is the only limit

Earlier drafts capped active projects at three, split projects into active and parked, and asked for a short note at every task switch. Each cap added upkeep without helping focus. The switch notes added work at the moment attention is lowest. This design keeps one limit. At most five open cards from Next sit on Today, with a frog first, and you switch between them freely. Completing a card frees a slot. `/pick-next` fills it, and it names the frog first if the frog is still open, so more work is always a deliberate choice.

Routines sit outside the limit. Meditating or doing the budget repeats on its own schedule and doesn't compete with project work, so counting routines would only shrink the room for the work the limit protects. An earlier draft capped the day at three cards and counted everything on Today, which left it unclear what the number meant.

Agent work sits inside the limit. You start the agent, steer it, and review what it makes, so a card an agent works on is a card you work on. `@waiting` is only for work that a person or a third party holds.

## Dates mean the day you plan to do it

A date on a work card is the day you plan to work on it. The pick skills date cards for today, and you can plan a card for a later day yourself. The Deadline field holds the hard deadline, the day the card is due. As a result, an overdue card is always one you planned and didn't finish, and the next morning pick settles it. A card planned for a later day stays out of Next until its morning, when it is on Today and counts toward the five. A deadline within two days brings it back into Next early. Today doubles as the in-progress list. A card on Today for a second morning is multi-day work you're still on, so there's no separate in-progress state to keep current.

## This version tracks no PRs

An earlier setup ran an orchestrator service that watched GitHub. It moved cards between columns, labeled cards whose PRs were ready for review, completed cards when their PRs merged, and created cards for PRs that had none. This version turns the service off and links no PRs to cards. A PR is part of its card's work, so the card stays on Today and keeps its slot until you complete it. An agent reviews your PRs, so a PR rarely waits long. T3 Code already shows each PR and its review, and a second copy in Todoist added upkeep. PR automation can come back later, built on this design.

## Projects only organize

A feature project groups its cards, so Next shows them together. It says nothing about what to work on. Priority and the morning pick decide that.

## Skills come with reminders

A skill helps only if you remember to run it. So the two skills tied to a time of day run on their own. T3 Code scheduled tasks start `/morning-pick` at 9am each weekday and `/weekly-review` at 9am on Friday, so the drafts are ready when you open each thread. The weekly review also adds a card to Today when it posts its draft, so Today shows that the thread waits for you. `/pick-next` is the exception, because you run it the moment you want more work. The session-start hook follows the same idea. It loads Today into each agent session, so no agent has to remember to look.

## The review lists the oldest cards

An earlier version marked a card `@stale` after 21 days with no activity in its log. Agents edit cards too, so the log mixed your decisions with automated moves and label changes. One bulk move kept every card fresh for three weeks. Telling the two apart took a command that read about 2,000 events and still had to guess.

The Friday review now lists the 10 oldest cards that have no date. Age needs nothing but the card. A date works as a snooze, because a dated card leaves the list until its day. A card you leave without a date shows again the next Friday, and that repeat is the nudge to decide.

## Left out on purpose

- **Hard blocks on work that isn't on Today.** They'd be turned off within a week.
- **Streaks, or a count of "start now" answers.** A count turns slips into guilt, and nothing in the flow uses the number.
- **A cap on parallel agent sessions.** The five-card pick already limits active work, because a card an agent works on counts toward the five.
- **Agents that start p3 cards on their own.** For now, p3 is a label you read during the pick. Handing p3 cards to agents can come later.
- **A Doing state or an `@doing` label.** You'd update it at every start and pause, which is the per-switch upkeep this design avoids. Today already shows what's in progress.
- **Sizing cards, as in the 1-3-5 rule.** Sizing every card is upkeep that doesn't change which cards get picked.
- **A break timer.** A phone Pomodoro timer handles breaks, outside Todoist.
- **An impact and effort matrix.** It added a second scoring step to triage without changing which cards get picked.
- **A custom app or an AI assistant that plans the day.** The morning pick stays yours, and an app is one more thing to maintain.
- **A link to the thread in a job card.** T3's `t3-thread://` links have no registered handler on nixbook, so the link would be dead in Todoist.
- **A limit on `td job-card` to scheduled runs.** Nothing in the environment marks a scheduled run reliably.
