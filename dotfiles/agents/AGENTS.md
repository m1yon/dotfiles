## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Rules
- NEVER commit PHI or HIPAA data to git.
- Use the `pstack:unslop` skill for any prose you write, including every reply to the user. Invoke it before your first reply in a session, and again if it is no longer in context.

## Work tracking
Todoist is Michael's only task tracker, and it is private. Use the `td` CLI. Never use Linear.
- Never mention Todoist, a card, or a card link in a PR, commit, branch name, or code.
- Never put member names, IDs, or other member data in a card.

The rules below apply only to sessions Michael starts. Skip them in a scheduled run or a delegated child session.
- Michael's plan for the day is his Today cards. At session start, match the request to a Today or `@waiting` card. If those cards aren't in context, run `td today --json` and `td task list --filter "@waiting" --json`. If nothing matches, ask once: "Not on Today. Pick it, Inbox it, or start anyway?" For "Pick it", add the card to the Inbox, then run `/pick-next` for it. Accept any answer, and don't ask again this session.
- Create cards only in the Inbox, at p4, with no date. Change a card's priority, date, or project only when Michael approves.
- List side work you notice at the end of your reply, and ask once whether to Inbox it.
- When the session's card is done, offer to complete it and name the next Today card. If Today has no open picks left, say so and mention `/pick-next`. Don't suggest a card yourself.

## pstack model configuration

Use these model and reasoning effort overrides for pstack roles. Values without a suffix use `default effort`. The aliases `inherit-parent` and `auto` omit the model override. Panel entries each count as one agent; the arena cross-judge pool supplies one model choice. On Codex, the model sheet lives in `$CODEX_HOME/pstack-models.md`, or `~/.codex/pstack-models.md` when `CODEX_HOME` is unset. A native plugin reads its session hook setting there.

These rows mix Claude and GPT models, and every session runs in T3 Code. Start an entry from the session's own provider with the native tool: in Claude sessions, `Agent` with the bare name (`opus`, `fable`, `sonnet`, `haiku`) and the `@level` as its effort; in Codex sessions, `spawn_agent` with the `gpt-*` name and the `@level` as `reasoning_effort`. Start an entry from the other provider with T3's `delegate_task`: provider `claudeAgent` with model `claude-opus-5-5`, `claude-fable-5-2`, `claude-sonnet-5-5`, or `claude-haiku-5-5` and option `effort`; or provider `codex` with the `gpt-*` model and option `reasoningEffort`. A panel still runs one subagent per entry, whichever tool starts it.

feature, refactoring: sonnet @xhigh
bug-fix: opus @xhigh
perf-issue: opus @xhigh
hillclimb: opus @xhigh
judgment and prose: opus @xhigh
strongest judgment: opus @max
how explorer: opus @medium
how explainer: opus @high
why investigators: opus @medium
why synthesizer: opus @xhigh
reflect tooling: sonnet @high
reflect judgment, divergent, synthesizer: opus @xhigh
arena runners: opus @xhigh, sonnet @xhigh, gpt-6-astra @high, gpt-6.1-sol @xhigh
arena cross-judge pool: opus @max, gpt-6-astra @max
swarm workers: gpt-6.1-sol @xhigh
architect runners: opus @xhigh, fable @xhigh, gpt-6-astra @high, gpt-6.1-sol @xhigh
interrogate reviewers: opus @xhigh, fable @xhigh, gpt-6-astra @high, gpt-6.1-sol @xhigh
thermos reviewers: gpt-6.1-sol @xhigh
no-comments reviewer: gpt-6.1-sol @medium

default effort: session
