# Agent rules

Two pieces run in every agent session: a section in the shared instruction file, and a hook that loads the day's plan.

## The AGENTS.md section

This section goes in `dotfiles/agents/AGENTS.md`, which Claude Code and Codex share. It replaces the `## Work tracking` section.

```markdown
## Focus
Michael's plan for the day is his Today cards in Todoist. Use the `td` CLI.
- At session start, match the request to a Today or `@waiting` card. If those cards aren't in context, run `td today --json` and `td task list --filter "@waiting" --json`. If nothing matches, ask once: "Not on Today. Pick it, Inbox it, or start anyway?" For "Pick it", run `/pick-next` for that card. Accept any answer, and don't ask again this session.
- Create cards only in the Inbox, at p4, with no date. Change a card's priority, date, or project only when Michael approves.
- List side work you notice at the end of your reply, and ask once whether to Inbox it.
- When you open a PR for a `@waiting` card, add the PR URL to the card as a comment.
- When the session's card is done, offer to complete it and name the next Today card. If Today has no open picks left, say so and mention `/pick-next`. Don't suggest a card yourself.
```

## The session-start hook

The hook gives each agent session the day's plan before the first prompt, so no agent has to remember to look it up.

- **Event.** `SessionStart`.
- **Commands.** `td today --json` and `td task list --filter "@waiting" --json`. In a test, `td today` took 0.7 seconds.
- **Filter.** The hook keeps cards in `MECA`, `Side Projects`, and their child projects. Personal cards stay out.
- **Output.** The hook prints the cards in Today's order, so the frog comes first.
- **Location.** `system/agents.nix`, next to `agent-guard`. That file already sets hooks in the Claude Code managed settings and the Codex `requirements.toml`. If a harness has no `SessionStart` event, the first rule in the section covers it.

Example output:

```text
Today:
1. Fix appointment sync retries [p2] (MECA › Appointment sync)
2. Answer the billing export question [p1] (MECA)
Waiting:
- Update the flake inputs [p3] (Side Projects)
```
