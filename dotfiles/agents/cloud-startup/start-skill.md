---
name: shared-agent-bootstrap
description: Load the shared agent startup skill before the first workspace-related answer, including questions about installed skills, even when the native skill catalog is empty.
---

<!-- shared-agent-startup:start -->
Before answering from workspace or installed capabilities, check readiness in
the selected managed environment through its supported status tool. Stop after
three status checks or 120 seconds total. Keep waits at most 30 seconds and use
only waits whose timeout can be bounded. Brief progress messages are allowed.
Unrelated requests do not need to wait. Failed startup, unavailable tooling, or
incomplete readiness leaves access unverified. Report the actual limitation.

Once ready, read the applicable workspace AGENTS.md and AGENTS.override.md and
follow their retained-installation pointer. If no pointer is present, check
$HOME/.local/share/agent-bootstrap/current. Resolve the root once to its physical
release directory. Read agent-startup/SKILL.md from that release in full and
follow it before answering. Pass along the readiness result and resolved root
so the shared skill does not restart this step. Missing or unreadable files
leave access unverified; report the exact path or failure. An empty native
catalog alone does not establish that installed skills are unavailable.
After shared loading, continue with any environment-specific instructions below.
<!-- shared-agent-startup:end -->
