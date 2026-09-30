---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
metadata:
  upstream: https://github.com/cursor/plugins/tree/fae2c6ed95821bd85f614a73e4842e13229fa5e5/pstack/skills/reflect
  codex-port: "true"
---

# Reflect

Read [Codex runtime](../setup-pstack/references/codex-runtime.md) before following this workflow.


Mine the current conversation for durable learnings, then route them into skill edits.

## When to invoke

Invoke when the user says "reflect" or "$reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Gather current conversation evidence

Use the current conversation, or retrieve the specific chat with `read_thread` when available. Confirm project and chat identity before reading. Include relevant user corrections and tool receipts in a compact digest. If only summaries are available, label them as summaries and report any claims that need missing full receipts. Pass this digest or a confirmed transcript export to the reviewers.

### 2. Spawn three reviewers in parallel

Three `spawn_agent` calls within the available concurrency limit, a scoped brief with the required skill paths, with `model` set as below, agent mode (a brief permitting the necessary lookups). Reviewers need MCP access for context lookups (tickets, chat threads, observability traces referenced in the transcript). Read-only scope is an instruction in the brief; it does not remove tool access.

Each reviewer and the synthesizer name a role line in the `setup-pstack/models.md` configuration and a default. Set `model` to that line's value, or to the default if the rule or the line is missing. Leave `model` unset when the value is `auto` or `inherit-parent`. If a configured model is unavailable, omit the override, inherit the parent model, and report the fallback. See the Codex runtime reference for model and reasoning fields.

| Lens | Role line | Default `model` | Prompt template |
|---|---|---|---|
| Judgment | `reflect judgment, divergent, synthesizer` | `inherit-parent` | `references/judgment-reviewer.md` |
| Tooling | `reflect tooling` | `inherit-parent` | `references/tooling-reviewer.md` |
| Divergent | `reflect judgment, divergent, synthesizer` | `inherit-parent` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Reviewers return findings in the `spawn_agent` response body.

### 3. Synthesize

One `spawn_agent` call, a scoped brief with the required skill paths, with `model` from the `reflect judgment, divergent, synthesizer` line (default `inherit-parent`), agent mode (a brief permitting the necessary lookups). The synthesizer's quality check includes spot-verifying citations, which can require MCP access. Read-only scope is an instruction in the brief; it does not remove tool access. Use `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. The synthesizer returns a structured Accepted / Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the synthesizer's Accepted list. For any item that would be enforced more reliably by a lint rule, script, metadata flag, or runtime check, move it from Accepted to Backlog. See the **principle-encode-lessons-in-structure** principle skill.

### 5. Apply

Before applying any Accepted edit, present the synthesizer's full Accepted/Rejected/Backlog output to the user and wait for explicit approval. The user picks which subset to apply and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

Return backlog items as recommendations. File them in an external tracker only when the user has authorized that write.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): parent does directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): hand to Codex's `skill-creator` skill and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): hand to `skill-creator` and run its description-optimization loop.
- `new skill via skill-creator: <kebab-name>`: hand creation to `skill-creator`. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done. Skip this step if it doesn't.

### 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
