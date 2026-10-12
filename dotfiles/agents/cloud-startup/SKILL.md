---
name: agent-startup
description: Load shared policy, model overrides, and installed pstack skills before the first workspace-related answer in a Cloud environment, including questions about available skills.
---

Before answering from workspace or installed capabilities, complete this loading
step. Brief progress messages are allowed. Unrelated requests do not need to wait
for the environment.

If the calling Start skill already checked readiness, keep that result and its
resolved retained release. Do not restart readiness checks. Otherwise check the
selected managed environment through its supported status tool. Stop after three
status checks or 120 seconds total. Keep individual waits at most 30 seconds and
use only waits whose timeout can be bounded. Failed startup, unavailable tooling,
or incomplete readiness leaves access unverified. Report the observed limitation.

Read the applicable workspace `AGENTS.md` and `AGENTS.override.md`. Use the
retained-installation pointer in those instructions. If no pointer is present,
check the installer's default `$HOME/.local/share/agent-bootstrap/current`.
Resolve that root once to its physical release directory and keep all reads
within that release.

Read these files in full before the first capability or workspace answer:

- `policy-block.md`.
- `pstack-models.md`.
- `skills-index.md`.
- `routing.md`.
- `pstack/skills/poteto-mode/SKILL.md`.
- `pstack/skills/poteto-mode/references/codex-tools.md`.

Apply the retained policy and routing. The retained `pstack-models.md` governs
model selection and reasoning effort for every pstack role, even when a skill
names a different or transient `CODEX_HOME` sheet.

Select workflows from the complete descriptions in `skills-index.md`. Read the
selected full `SKILL.md` files before following them. Resolve indexed resources
from the physical release root and each skill's relative references from its own
directory. Use filesystem reads when native discovery omits pstack. An empty
native catalog does not establish that the installed skills are unavailable.
Load other full skill bodies only when their workflows apply.

Missing or unreadable required files leave loading unverified. Report the exact
path or access failure. Do not reinstall packages or inspect credentials as part
of this loading step. Before answering about a child repository, read its
applicable instructions. Continue with any environment-specific startup
instructions supplied by the calling Start skill after shared loading completes.
