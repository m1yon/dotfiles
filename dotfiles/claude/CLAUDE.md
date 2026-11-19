@~/.agents/AGENTS.md

## Work tracking

- When a reply finishes the work for the session's card, call `mcp__claude_ai_Todoist__find-tasks-by-date` just before you write that reply. Set `startDate` to the card's due date as `YYYY-MM-DD`. T3 Code shows the result as Todoist's task list, where Michael can check the card off. Write the reply as usual, with no mention of the list or of checking the card off. Skip this when the card has no due date.
