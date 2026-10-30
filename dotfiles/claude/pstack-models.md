# pstack model configuration

Per-role model overrides for pstack skills. Each pstack SKILL.md names its defaults in a Models section; the values here override those defaults. Delete a line to fall back to the skill default. A value of `inherit-parent` or `auto` runs that role on the parent session's model (the `Agent` call omits `model`); an alias entry in a panel list still counts toward that panel's fan-out. A model may carry a reasoning effort, as in `opus @xhigh` (levels: low, medium, high, xhigh, max); the role's subagent then runs at that level, each entry of a panel list on its own. `default effort` sets the level for a value without one; `session` keeps the parent session's effort. `session hook: off` stops the Claude Code or Codex SessionStart hook, or the pstack Pi extension, from injecting the poteto-mode mandate; any other value, or no line, leaves it on.

This sheet mixes Claude and GPT models, and every session runs in T3 Code. Start an entry from the session's own provider with the native tool: in Claude sessions, `Agent` with the bare name (`opus`, `fable`, `sonnet`, `haiku`) and the `@level` as its effort; in Codex sessions, `spawn_agent` with the `gpt-*` name and the `@level` as `reasoning_effort`. Start an entry from the other provider with T3's `delegate_task`: provider `claudeAgent` with model `claude-opus-5-5`, `claude-fable-5-1`, `claude-sonnet-5-5`, or `claude-haiku-5-5` and option `effort`; or provider `codex` with the `gpt-*` model and option `reasoningEffort`. A panel still runs one subagent per entry, whichever tool starts it.

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

default effort: session
session hook: on
