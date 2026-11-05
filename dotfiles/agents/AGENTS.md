## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Rules
- NEVER commit PHI or HIPAA data to git.
- Use the `pstack:unslop` skill for any prose you write, including every reply to the user. Invoke it before your first reply in a session, and again if it is no longer in context.

## Work tracking
Todoist is the only task tracker, and it is private. Use the `td` CLI, and write every task ref as `id:<id>`. Never use Linear.
- Never mention Todoist, a task id, or a task link in a PR, commit, branch name, or code. The link goes one way, from the task to the PR.
- Every PR has its own task. Plans, steps and commits never become tasks.
- Starting a task: `td task move id:<id> --section "In Progress"`. In a project with no sections the move fails, so skip it there. Only move top-level tasks. Never move a subtask. A subtask has the same status as its parent.
- One PR covers the work: use the task itself. Add no subtasks.
- More PRs are needed: before your first commit, add one subtask per planned PR with `td task add "<PR title>" --parent id:<id>`. Add them all together. A PR you did not plan gets its subtask before you open it.
- Before you add a subtask, check that the parent is open: `td task view id:<id> --json --full` must show `"checked": false`. A subtask added under a closed parent silently becomes a top-level task. If the parent is closed, treat it as no task named, so make a new top-level task and use that.
- Work that must still happen after the last PR and needs no PR: split the task as above, and add that work as one more subtask, so the parent stays open.
- Open every PR with this one command, so the link is always the real URL: `url=$(gh pr create <args>) && td comment add id:<id> --content "PR: $url"`. `<id>` is that PR's own task. When the work is split, it is the subtask. Never type a PR URL by hand.
- Out-of-scope work, whether you noticed it or were told about it: `td task add "<title>" --project Inbox --labels from-agent`, before you finish. Do not do that work.
- No task was named: before your first commit, make a new top-level task and use that id as the task above. In a repo in the `Meca-Therapies` GitHub org: `td task add "<title>" --project MECA --section "In Progress" --json`. In any other repo: `td task add "<title>" --project "Side Projects" --json`. A session that changes no code creates nothing.
- Ask Michael before you create any project.
- Never complete a task that has a PR, and never complete a parent. Merging does that.
- Never put member names, IDs or other member data in a task.

## pstack model configuration

Use these model and reasoning effort overrides for pstack roles. Values without a suffix use `default effort`. The aliases `inherit-parent` and `auto` omit the model override. Panel entries each count as one agent; the arena cross-judge pool supplies one model choice. On Codex, the model sheet lives in `$CODEX_HOME/pstack-models.md`, or `~/.codex/pstack-models.md` when `CODEX_HOME` is unset. A native plugin reads its session hook setting there.

These rows mix Claude and GPT models, and every session runs in T3 Code. Start an entry from the session's own provider with the native tool: in Claude sessions, `Agent` with the bare name (`opus`, `fable`, `sonnet`, `haiku`) and the `@level` as its effort; in Codex sessions, `spawn_agent` with the `gpt-*` name and the `@level` as `reasoning_effort`. Start an entry from the other provider with T3's `delegate_task`: provider `claudeAgent` with model `claude-opus-5-5`, `claude-fable-5-1`, `claude-sonnet-5-5`, or `claude-haiku-5-5` and option `effort`; or provider `codex` with the `gpt-*` model and option `reasoningEffort`. A panel still runs one subagent per entry, whichever tool starts it.

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
