---
name: setup-pstack
description: Configure Codex model and reasoning preferences for pstack roles. Use for pstack setup, budget changes, or per-role model choices.
metadata:
  upstream: https://github.com/cursor/plugins/tree/fae2c6ed95821bd85f614a73e4842e13229fa5e5/pstack/skills/setup-pstack
  codex-port: "true"
---

# Setup pstack

Read [Codex runtime](references/codex-runtime.md) before following this workflow.

Configure optional role preferences in `models.md` beside this file. This file is read by pstack skills; it is not a Codex system rule. When the skill directory is managed by Nix or symlinked to a repository, edit the maintained source.

1. Inspect the current agent tool schema for supported model IDs and reasoning efforts. Keep the parent model and effort by default. Model IDs and reasoning efforts are separate fields.
2. Read an existing `models.md`. Preserve current preferences unless the user requests a change. Missing roles inherit the parent.
3. If the request leaves a meaningful choice unresolved, use `request_user_input_async` when available, or a concise question in chat. Offer parent inheritance first. Set only the models and budgets the user chooses. A panel list determines the number of independent reviewers, within the concurrency limit.
4. Validate every explicit model and effort against the exposed tools. Use `inherit-parent` or `auto` to omit both overrides. If a requested model is unavailable, explain that and offer the available choices. Do not substitute silently.
5. Write the complete configuration idempotently. Each role occupies one line, with comma-separated panel entries. An explicit entry uses `model-id@reasoning-effort`; the effort suffix is parsed and passed separately to the tool. Example defaults:

```text
feature, refactoring: inherit-parent
bug-fix: inherit-parent
perf-issue: inherit-parent
hillclimb: inherit-parent
judgment and prose: inherit-parent
hardest tasks: inherit-parent
how explorer: inherit-parent
how explainer: inherit-parent
why investigators: inherit-parent
why synthesizer: inherit-parent
reflect tooling: inherit-parent
reflect judgment, divergent, synthesizer: inherit-parent
arena runners: inherit-parent, inherit-parent, inherit-parent
arena cross-judge pool: inherit-parent
swarm workers: inherit-parent
architect runners: inherit-parent, inherit-parent, inherit-parent
interrogate reviewers: inherit-parent, inherit-parent, inherit-parent
```

6. Report the saved path, changed roles, and whether reviewers inherit one model or use distinct supported models. Do not change the main chat's model or unrelated Codex settings.

If the user also wants a project verification skill, use `$create-verification-skill`.
