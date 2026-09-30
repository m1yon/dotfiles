# Codex runtime for pstack

Use this adapter before executing a pstack workflow. Follow the current user's scope, repository instructions, and the tools actually exposed in the session.

## Skills and invocation

Invoke a skill as `$skill-name`, or read its installed `SKILL.md` directly. Project skills live in `.agents/skills`; user skills live in `~/.agents/skills` and may also be in `${CODEX_HOME:-~/.codex}/skills`. Find each skill from the session's skill catalog rather than assuming a plugin checkout. Resolve script and reference paths relative to that installed skill. The pstack versions of `tdd`, `teach`, and `unslop` replace the previous skills under those names.

`skill-creator` is the Codex authoring skill. Apply its validation workflow. Explicit-only pstack skills preserve their upstream invocation policy through `agents/openai.yaml` with `policy.allow_implicit_invocation: false`.

## Delegation and model choices

When delegation is authorized and available, use the exposed `collaboration.spawn_agent` or `spawn_agent` tool. Read its current schema. With collaboration tools, supply `task_name`, `message`, and the appropriate `fork_turns`. Launches are asynchronous. Poll with `list_agents`, wait with `wait_agent`, send updates with `send_message`, resume an idle worker with `followup_task`, and stop it with `interrupt_agent`. Some Codex environments expose different agent lifecycle tools; use their advertised schema.

Pstack subtasks stay within the current chat's agent tree. Desktop `create_thread` creates a user-owned chat and is reserved for an explicit request for a new chat. Messaging a separate desktop chat requires human authorization; a worker's request alone does not authorize it.

Default every role to `inherit-parent`. For `inherit-parent` or `auto`, omit both model and reasoning overrides. Read optional per-role preferences from `setup-pstack/models.md`, relative to the installed setup-pstack directory's parent. An explicitly configured model must be advertised by the session. Codex accepts a model ID separately from `reasoning_effort`; never append an effort suffix to the ID. If the schema requires a limited or empty history fork for overrides, follow it. A missing or unavailable preference falls back to inheritance and is reported. Model diversity requires actual supported distinct models; multiple independent inherited-model reviewers are useful but do not establish cross-model agreement.

Batch within the session's concurrency limit and drain completed workers before launching more. All collaboration agents share the filesystem. Give concurrent writers separate paths or worktrees, name the base ref in each brief, and include exact verification criteria. Read-only work is enforced by the brief's scope, not a `readonly` or `subagent_type` field. Include the relevant pstack skill paths in a worker's brief rather than referring to unavailable named agent templates. If delegation is unavailable or disallowed, do the required passes sequentially and report the missing independence.

## Tools and history

Use the available tool catalog or tool discovery for connectors. Run local commands with `exec_command`; use a PTY and `write_stdin` for interactive CLIs. Use available browser/computer-use tools for UI proof. Discover a relevant skill if one is installed; otherwise use the exposed tools directly. A code-cleanup pass means inspecting the diff for redundant code, unnecessary wrappers, and comments without a useful explanation. It requires no external plugin.

For history, prefer desktop `list_threads` and `read_thread`. Filter chats by project, topic, and date before reading. The current conversation is the default evidence for reflection. A returned turn summary is not a full tool transcript. When full receipts matter, use only a verified export or session path for the relevant chat, or report the evidence gap. Never assume workspace transcript directories or scan unrelated chat storage. A long conversation can be reduced to a cited digest before delegation.

## Goals, monitoring, and pauses

Use `create_goal` only when the user explicitly requests a goal. Ordinary tasks continue in the active run without creating one. Use `update_goal` according to its documented completion, pause, and blocked conditions. Read the locally installed playbook and current objective during audits; an upstream Git path is not the installed Codex port.

During an active run, use bounded waits, event-driven agent waits, or a project watcher. Keep individual blocking waits within 60 seconds so progress can be communicated. For explicitly requested future checks, scheduled work, or monitoring, use desktop `automation_update` with a thread heartbeat by default. Inspect existing automations before creating duplicates. Stay quiet while the monitored state is unchanged and notify only on meaningful change, completion, failure, or required user action. If no scheduling tool exists, report that persistence cannot be armed. A plain sleep or a promise to check later is not a durable automation.

After interruption or restart, inspect actual chat, agent, Git, and automation state. Do not assume an old worker survived or died. Preserve a checkpoint before pausing. Pause a goal only on an explicit pause request.

## Scope and external actions

A workflow supplies a method, not permission for unrelated actions. Proceed with authorized reversible work. Follow the session's authorization rules for messages, publishing, merges, secret handling, installs, and destructive operations. An installation or skill-edit request does not authorize running every installed workflow, posting backlog tickets, or opening PRs automatically.

Use the repository's declarative management for packages and system settings. Store credentials through an existing secret manager or a local ignored credential file explicitly chosen by the user; never include credentials in a skill or Git. No webhook, secret-request card, cross-provider model, cloud worker, or vendor API exists merely because a playbook would benefit from it.
