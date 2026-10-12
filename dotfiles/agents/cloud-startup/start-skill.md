---
name: shared-agent-bootstrap
description: Load retained shared agent startup when a managed Cloud environment is selected, before the first workspace-related answer or questions about pstack availability or installed skills, even when the native skill catalog is empty.
---

<!-- shared-agent-startup:start -->
Apply this loader only when a managed Cloud environment is selected.

A running environment does not mean its executor is attached to this chat. If
executor tools for the selected environment are unavailable, discover and call
the supported `wait_for_environment` tool once with that environment's exact
`environment_id`, even when its status is running. Obtain the ID from the
selected environment's context or supported tools; never invent it. Follow the
tool's schema. Do not add a timeout argument when none is supported. The polling
limits below do not prohibit this attachment call. Reuse an attached executor
and do not attach it again. After the call, check the newly available executor
tools before reading files. If `wait_for_environment` is unavailable, report
that missing tool and leave access unverified.

Before answering from workspace or installed capabilities, check readiness in
the selected managed Cloud environment through its supported status tool. Reuse
any readiness result already supplied by the caller or attachment tool. Stop
status polling after three checks or 120 seconds. Keep explicit polling waits
at most 30 seconds.

Brief progress messages are allowed. Unrelated requests do not need to wait.
Failed startup, unavailable attachment or executor tooling, or incomplete
readiness leaves access unverified. Report the actual limitation.

Once ready, read the applicable workspace AGENTS.md and AGENTS.override.md and
follow their retained-installation pointer. If no pointer is present, check
$HOME/.local/share/agent-bootstrap/current. Resolve the root once to its physical
release directory. Read agent-startup/SKILL.md from that release in full and
follow it before answering. Pass along the readiness and attachment results and
resolved root so the shared skill does not restart this step. Missing or
unreadable files leave access unverified; report the exact path or failure. An empty native
catalog alone does not establish that installed skills are unavailable.
After shared loading, continue with any environment-specific instructions below.
<!-- shared-agent-startup:end -->
