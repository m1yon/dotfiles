# Agent rules

Three pieces shape what agents do with Todoist: a section in the shared instruction file, a hook that loads the day's plan, and an `agent-guard` check that keeps new cards in the Inbox.

## The AGENTS.md section

This section goes in `dotfiles/agents/AGENTS.md`, which Claude Code and Codex share. It replaces the current `## Work tracking` section. It keeps that section's two privacy rules and drops the rest, including every rule about PRs.

```markdown
## Work tracking
Todoist is Michael's only task tracker, and it is private. Use the `td` CLI. Never use Linear.
- Never mention Todoist, a card, or a card link in a PR, commit, branch name, or code.
- Never put member names, IDs, or other member data in a card.

The rules below apply only to sessions Michael starts. Skip them in a scheduled run or a delegated child session.
- Michael's plan for the day is his Today cards. At session start, match the request to a Today or `@waiting` card. If those cards aren't in context, run `td today --json` and `td task list --filter "@waiting" --json`. If nothing matches, ask once: "Not on Today. Pick it, Inbox it, or start anyway?" For "Pick it", add the card to the Inbox, then run `/pick-next` for it. Accept any answer, and don't ask again this session.
- Create cards only in the Inbox, at p4, with no date. Change a card's priority, date, or project only when Michael approves.
- List side work you notice at the end of your reply, and ask once whether to Inbox it.
- When the session's card is done, offer to complete it and name the next Today card. If Today has no open picks left, say so and mention `/pick-next`. Don't suggest a card yourself.
```

## The session-start hook

The hook gives each agent session the day's plan before the first prompt, so no agent has to remember to look it up.

- **Event.** `SessionStart`.
- **Commands.** `td today --json` and `td task list --filter "@waiting" --json`. In a test, `td today` took 0.7 seconds.
- **Filter.** The hook keeps cards in `MECA`, `Side Projects`, and their child projects. `Personal` and `Routines` cards stay out.
- **Output.** The hook prints the cards in Today's order, so the frog comes first.
- **Location.** `system/agents.nix`, next to `agent-guard`. That file already sets hooks in the Claude Code managed settings and the Codex `requirements.toml`. If a harness has no `SessionStart` event, the rule that matches the request to a card covers it.

Example output:

```text
Today:
1. Fix appointment sync retries [p2] (MECA › Appointment sync)
2. Answer the billing export question [p1] (MECA)
Waiting:
- Get the vendor's answer on export limits [p3] (MECA)
```

## The agent-guard check

`system/agent-guard.sh` runs before each agent shell command. This check replaces its `from-agent` and `approved` check, because the new section uses neither label.

- It blocks `td task add` when the command sets `--project` to anything but the Inbox, or sets `--section`, `--parent`, `--priority`, `--due`, or `--deadline`.
- It blocks `td add`, `td task quickadd`, and `td task qa` outright, because quick-add text can carry a project, a priority, or a date.
- The block message tells the agent to add the card to the Inbox at p4 with no date, and to ask Michael before it changes the card.
- Picking and triage change cards with `td task update` and `td task move`, so the check doesn't affect them.
- `checks.agent-guard` tests the check. The build also updates the matching row in the rules table of this repo's `AGENTS.md`.
- The check doesn't see the Todoist MCP tools.
