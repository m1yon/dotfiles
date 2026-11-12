# Agent rules

Three pieces shape what agents do with Todoist: a section in the shared instruction file, a hook that loads the day's plan, and an `agent-guard` check that keeps new cards in the Inbox.

## The AGENTS.md section

This section goes in `dotfiles/agents/AGENTS.md`, which Claude Code and Codex share. It replaces the current `## Work tracking` section. It keeps that section's two privacy rules and drops the rest, including every rule about PRs.

````markdown
## Work tracking
Todoist is Michael's only task tracker, and it is private. Use the `td` CLI. Never use Linear.
- Never mention Todoist, a card, or a card link in a PR, commit, branch name, or code.
- Never put member names, IDs, or other member data in a card.
- Start each card you show Michael with its priority dot: 🔴 p1, 🟠 p2, 🔵 p3, or ⚪ p4, as in `🟠 p2 Fix appointment sync retries`. Put 🐸 after the priority on the frog, the card with the `frog` label, as in `🟠 p2 🐸 Fix appointment sync retries`.

The rules below apply only to sessions Michael starts. Skip them in a scheduled run or a delegated child session.
- Michael's plan for the day is his Today cards. At session start, match the request to a Today or `@waiting` card. The session-start hook lists those cards and the open-pick count. An open pick is a Today card that is also in Next. If the hook's output isn't in context, run `td today --json --full --all`, `td filter view Next --json --all --full`, and `td task list --filter "@waiting" --json`. If nothing matches, ask once with this menu, with `<n>` set to the open-pick count:

  ```text
  I don't see a Today card for this. You have <n> of 5 picks open. Reply with a number or in your own words.
  1. Add it to Today. I'll ask for a priority and a project.
  2. Save it to the Inbox and stop here.
  3. Start now without a card.
  ```

  At 5 or more open picks, leave out "Add it to Today" and number the other two choices from 1. For "Add it to Today", add the card to the Inbox, then run `/pick-next` for it. For "Save it to the Inbox", add the card to the Inbox and stop. Accept any answer, and don't ask again this session.
- Create cards only in the Inbox, at p4, with no date. Change a card's priority, date, or project only when Michael approves.
- List side work you notice at the end of your reply, and ask once whether to Inbox it.
- When the session's card is done, offer to complete it and name the next Today card. If Today has no open picks left, say so and mention `/pick-next`. Don't suggest a card yourself.
````

## The session-start hook

The hook gives each agent session the day's plan before the first prompt, so no agent has to remember to look it up.

- **Event.** `SessionStart`.
- **Commands.** `td today --json --full --all`, `td filter view Next --json --all --full`, `td task list --filter "@waiting" --json --all`, and `td project list --json --all`, run in parallel. In a test, the hook took about 1.3 seconds. The Next call is the slowest, at about 1.2 seconds on its own.
- **Filter.** The hook keeps cards in `MECA`, `Side Projects`, and their child projects. `Personal` and `Routines` cards stay out.
- **Output.** The hook prints the cards in Today's order, so the frog comes first. The frog's line starts with 🐸. Today's order is each card's `dayOrder`, which `/morning-pick` sets with `td day-order`. A card nobody ordered goes last. Each line ends with the card's id, so an agent can complete the card without looking it up. The hook also prints the open-pick count, which covers every Today card that is also in Next, Personal cards included.
- **Failure.** If a `td` command fails, the hook prints nothing, and the rule that matches the request to a card has the agent run `td` itself.
- **Location.** `system/todoist-today.sh`, wired up in `system/agents.nix` next to `agent-guard`. That file sets hooks in the Claude Code managed settings and the Codex `requirements.toml`. `checks.todoist-today` runs the hook against a fake `td`.

Example output:

```text
Today:
1. 🐸 Fix appointment sync retries [p2] (MECA › Appointment sync) id:a1b2c3
2. Answer the billing export question [p1] (MECA) id:d4e5f6
Open picks: 3 of 5
Waiting:
- Get the vendor's answer on export limits [p3] (MECA) id:g7h8i9
```

## `td day-order`

`td` 5.10.0 has no command for the order of cards in Today, so the `td` wrapper in `home/shared/programs/todoist-cli.nix` adds one. `td day-order id:a id:b` puts card a, then card b, at the top of Today. It sends the Sync API command `item_update_day_orders`. The API reports success even for an unknown id, so `/morning-pick` reads Today back to check the order.

## `td` JSON priorities

The Todoist API numbers priority backward: 4 is p1 and 1 is p4. `td task update --priority` and the Todoist app use p1 to p4. Agents mixed the two up, so the `td` wrapper rewrites every numeric `priority` and `lastPriority` in `--json` and `--ndjson` output to `"p1"` through `"p4"`. If `jq` can't parse the output, the wrapper prints it unchanged.

## The agent-guard check

`system/agent-guard.sh` runs before each agent shell command. This check replaces its `from-agent` and `approved` check, because the new section uses neither label.

- It blocks `td task add` when the command sets `--project` to anything but the Inbox, or sets `--section`, `--parent`, `--priority`, `--due`, or `--deadline`.
- It blocks `td add`, `td task quickadd`, and `td task qa` outright, because quick-add text can carry a project, a priority, or a date.
- The block message tells the agent to add the card to the Inbox at p4 with no date, and to ask Michael before it changes the card.
- Picking and triage change cards with `td task update` and `td task move`, so the check doesn't affect them.
- `checks.agent-guard` tests the check. The build also updates the matching row in the rules table of this repo's `AGENTS.md`.
- The check doesn't see the Todoist MCP tools.
