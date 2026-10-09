## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Rules
- NEVER commit PHI or HIPAA data to git.

## pstack model configuration

Use these model and reasoning effort overrides for pstack roles. Pass each `@<level>` suffix as `spawn_agent`'s `reasoning_effort`. Values without a suffix use `default effort`. The aliases `inherit-parent` and `auto` omit the model override. Panel entries each count as one agent; the arena cross-judge pool supplies one model choice. On Codex, the model sheet lives in `$CODEX_HOME/pstack-models.md`, or `~/.codex/pstack-models.md` when `CODEX_HOME` is unset. A native plugin reads its session hook setting there. The shared bootstrap installs standing routing in global `AGENTS.md` for skills-only environments.

feature, refactoring: gpt-6.1-sol @high
bug-fix: gpt-6-astra @xhigh
perf-issue: gpt-6-astra @xhigh
hillclimb: gpt-6-astra @xhigh
judgment and prose: gpt-6.1-sol @medium
strongest judgment: gpt-6-astra @xhigh
how explorer: gpt-6.1-sol @medium
how explainer: gpt-6.1-sol @medium
why investigators: gpt-6.1-sol @high
why synthesizer: gpt-6.1-sol @high
reflect tooling: gpt-6.1-sol @low
reflect judgment, divergent, synthesizer: gpt-6.1-sol @high
arena runners: gpt-6.1-sol @high, gpt-6-astra @high, gpt-6-luna @high
arena cross-judge pool: gpt-6.1-sol @xhigh, gpt-6-astra @xhigh, gpt-6-luna @xhigh
swarm workers: gpt-6.1-sol @medium
architect runners: gpt-6.1-sol @xhigh, gpt-6-astra @xhigh, gpt-6-luna @xhigh
interrogate reviewers: gpt-6.1-sol @xhigh, gpt-6-astra @xhigh, gpt-6-luna @xhigh

default effort: medium
