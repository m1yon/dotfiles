# IFS Skill — Subagent Architecture

Companion to `research/ifs-skill-design.md`. Records decisions about when
and how `/ifs-session` uses Opus subagents.

## Summary

- Conversation runs in the main session as a skill (Sonnet, low effort).
- Exactly **one** Opus-xhigh subagent dispatch per session, at the end.
- That subagent owns synthesis **and** all Obsidian file writes.
- Mid-session is pure-read; writes are batched into a pending-changes log
  and applied atomically by the subagent.
- Both graceful bails (§4e) and imminent-harm exits (§4d) dispatch.

---

## 1. Conversation lives in the skill, not a subagent

Considered hosting the whole session inside an Opus-pinned subagent so that
`model:` / `effort:` frontmatter could enforce Sonnet-low regardless of the
main session's model. Rejected — **subagents are fire-and-forget with
respect to the user.** The Agent tool dispatches a subagent that runs to
completion and returns a single message. There is no mechanism for free-text
back-and-forth with the user from inside a subagent. `AskUserQuestion`
works in subagents but only for structured prompts, and the design uses
that exactly once (§4b tier selection).

So the conversational skill must live in the main session. The user is
responsible for being on Sonnet-low when they invoke `/ifs-session`. **No
soft check at session start** — model choice is a UX/pacing concern, not
a safety one (cf. §4a `crisis_fallback`, which *is* a safety hard-refuse).

Skill location: `~/.claude/skills/ifs-session/SKILL.md`. Skills do not
support `model:` / `effort:` frontmatter — only agents do.

## 2. Exactly one Opus-xhigh dispatch — post-closing session-write

Walked the protocol looking for moments that need deep reasoning.
Almost none qualified, because §3 ("Claude reflects, never synthesizes")
deliberately keeps Claude out of the interpretive loop:

| Moment | Sonnet-low | Why |
|---|---|---|
| Mood safety gate (§4b) | yes | Phrase pattern matching |
| Imminent-harm pattern match (§4d) | yes — and **must be** | Latency rules out any subagent dispatch on a crisis signal |
| 8 C's check at F4 | yes | Closed vocabulary |
| Cycle detection (§5b) | yes | State counters |
| Polarization observation | yes | Triggered mechanically; offer is a script |
| Role-play-request detection (§3) | yes | Behavior is hard refusal regardless of motive |
| Naming candidates (§7a) | yes | Design *forbids* synthesis — playback only |
| Alias "same as X?" check (§7b) | yes | Trust user's answer |
| Trailhead surfacing (§4b) | yes | List combination |

Where deep reasoning actually pays off — and where latency is invisible
because the user has already stepped out — is the **session-note write-up**:
the `## Arc` prose, `## Parts encountered` sub-sections, `## What Self
noticed`, `## Open threads`. One dispatch, after the closing ritual.

The split is **temporal** (during session vs writing the artifact), not
difficulty-based. There is no mid-session escalation logic, no decision
boundary about *when* to call Opus.

## 3. Subagent owns synthesis + all file ops

Considered "synthesis-only" — subagent returns markdown, main session
writes files. Rejected on **context-budget grounds**: the structural
knowledge in §7 (rename mechanics, alias accumulation), §8 (part page
schema), §9 (session note schema), and §10 (Trailheads format) is
substantial and has nothing to do with running the conversation. Letting
that knowledge live in the subagent's system prompt keeps `SKILL.md`
focused on §3-§5 (Claude's role, safety, the 6 F's).

Tradeoff: the subagent gets a wider tool surface (`Read`, `Write`,
`Edit`, `Glob`) and partial-failure handling has to be reported across
the dispatch boundary. Acceptable — the subagent runs once per session,
with bounded scope defined by its system prompt.

## 4. Pure-read mid-session; pending-changes log batched to session-end

Naive design has writes happening at multiple points: alias appends
when a new phrase surfaces (§7b), renames (§7c), new-part page creation
on first contact, plus the session-end batch.

Rejected. Mid-session is pure-read. The conversational skill maintains an
in-memory **pending-changes log**. Every would-be write becomes a log
entry. At closing-ritual end, one Agent dispatch hands transcript +
event log + pending-changes log to the subagent, which executes
everything atomically.

Reasons:

1. **Doubles down on §3.** §7-§8 schema knowledge stays out of `SKILL.md`.
2. **One transactional boundary.** All writes succeed-together or fail-
   together; one return value to inspect.
3. **Mid-session register.** Inline writes drag toward administrative
   manager-energy. "We'll note that down at the end" matches the
   closing-ritual frame.

Cost: in-session references to a queued rename must resolve through the
local pending-state view (so if `X → Y` is queued at minute 10 and the
user mentions the part again at minute 25, it's already `Y` from the
skill's perspective). Trivial in-memory bookkeeping. If the session
crashes ungracefully, all pending changes are lost — accepted, the user
can re-record key parts in the next session.

## 5. Both §4d and §4e dispatch the subagent

**§4e — graceful bail.** Full synthesis. `status: interrupted` in
frontmatter, every part touched flagged `left_without_resolution: true`.
Pending-changes log applied in full.

**§4d — imminent-harm exit.** Same dispatch, full §4e-style synthesis,
crisis content **included** in the prose body. Differentiator is
`status: crisis_exit` in frontmatter only.

Considered (and rejected): no dispatch at all on §4d (privacy concern —
recording crisis state in scrollable prose), and a "sanitized" middle
option that synthesizes pre-trigger work but excludes the trigger turn
itself. Decided full synthesis to preserve continuity and avoid
splitting the architecture for an edge case. Fallback if the artifact
ever feels harmful in practice: re-introduce a `crisis_exit_marker`
event in the log, instruct the subagent to truncate body synthesis
there.

Latency is acceptable on §4d because the crisis-plan link is the *first*
text the orchestrator emits in its turn; the subagent dispatch follows.
The user sees the link immediately and steps away — they don't experience
the wait.

---

## Subagent: `ifs-session-writer`

Path: `~/.claude/agents/ifs-session-writer.md`.

```yaml
---
name: ifs-session-writer
description: Compose IFS session note and apply pending-changes log to Obsidian.
model: opus
effort: xhigh
tools: Read, Write, Edit, Glob
---
```

System prompt covers design-doc §6 (Phase 2 reads), §7 (naming /
aliases / renames), §8 (part page schema), §9 (session note schema),
§10 (Trailheads.md format). Obsidian root path lives here, not in
`SKILL.md`.

### Input contract

```
{
  metadata: {
    date, tier, duration_min,
    status: "complete" | "interrupted" | "crisis_exit",
    previous_session_link
  },
  transcript: [{ role, text, ts }, ...],
  event_log: [
    { type: "anchor_selected", part_ref },
    { type: "blend_at_f4", blended_part_ref },
    { type: "light_touch_step_back", success: bool },
    { type: "re_target", from, to },
    { type: "cycle_detected", signal, parts },
    { type: "polarization_work", pair },
    { type: "pulse_check", result },
    { type: "dissociation_cue_caught" },
    { type: "exile_contact", part_ref },
    { type: "unburdening", part_ref },
    ...
  ],
  pending_changes: [...]   // see schema below
}
```

### Output contract

```
{
  written: [paths],
  failed: [{ path, error }],
  summary: "one-line user-facing closing message"
}
```

Write order: session note first; on success, part-page touches and
Trailheads.md updates. Later failures surface in `failed` but do not
roll back the note.

## Pending-changes log schema

Typed entries; subagent rejects malformed ones.

- `create_part` — { title, initial_frontmatter }
- `append_alias` — { part_ref, new_phrase }
- `rename_part` — { old_title, new_title, reason? }
- `set_part_type` — { part_ref, type }   // manager | firefighter | exile | unknown
- `set_status` — { part_ref, status }    // active | unburdened | dormant
- `update_last_seen` — { part_ref, date }
- `clear_left_without_resolution` — { part_ref }
- `record_polarization` — { pair: [a, b] }   // mirrored on both pages
- `record_protects` — { part_ref, exile_ref }
- `strike_trailhead` — { line, session_link }

`part_ref` resolves through the local pending-state view: a rename
queued earlier in the same session is already applied for refs that
follow it.

---

## Open questions

- **Partial-failure recovery.** If session note writes but part-page
  updates fail, the skill sees `failed` entries on return. Re-invoke?
  Manual fix? Tentative: surface failures inline, write a
  `<date>-recovery.md` stub the user can apply later.

- **Idempotency on retry.** If dispatch fails entirely, retry semantics
  are undefined. Probably: keep the pending log available for one retry
  attempt, then discard.

- **Initial bootstrap.** First-ever session has no `IFS.md`, no
  `Crisis Plan.md`, no `Sessions/` or `Parts/` folders. §4a hard-refuses
  on missing `IFS.md` + `Crisis Plan.md`. Folder creation on first valid
  run is unspecified — leaning skill (mechanical, pre-conversation),
  not subagent.

- **`status: crisis_exit` vs `interrupted`.** Decided to differentiate
  in frontmatter; Dataview / homepage queries on this not yet designed.
  Could be intentionally absent (cf. §11 "no parts not seen in N days
  query — chasing dormant parts is manager behavior").

- **Closing line shape.** Subagent returns `summary`. Concrete shape TBD;
  probably plain — *"Logged: 2026-04-25, 35min, 2 parts touched"* — no
  therapist-voice.

- **§4d sanitization fallback.** If full synthesis (iii) feels harmful
  in practice, fallback is option (ii) from the design grill: a
  `crisis_exit_marker` event in the log, subagent truncates prose
  synthesis there. Frontmatter and pending-changes still apply.
