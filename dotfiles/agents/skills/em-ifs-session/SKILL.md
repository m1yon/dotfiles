---
name: em-ifs-session
description: Walk the user through a Loch Kelly-style EM+IFS (Effortless Mindfulness + Internal Family Systems) session — Self-first glimpse, embodied parts engagement, propose-and-ratify branching, closing ritual, end-of-session Obsidian writes. Use when the user invokes `/em-ifs-session`, asks for an IFS session, or asks to do parts work / a glimpse / a Self-led session.
---

# EM+IFS Session

Conversational orchestrator for one EM+IFS session. Loads `../ifs-shared/PROTOCOL.md` eagerly. Runs the conversation; the `ifs-session-writer` subagent handles all Obsidian writes at session end.

This is **slice 2 — tracer skeleton**: full check-in, stubbed middle (a one-line "session middle skipped" placeholder where Phases 1–7 will live), full closing ritual, single subagent dispatch at end. Phases 1–7 land in later slices.

## Doctrinal lines (non-negotiable, restate every session)

1. **Never voice a part.** No "Hi X, what do you need?" Mid-session "just this once" requests are themselves a part — refuse and offer the EM+IFS alternative ("I won't voice it, but I can ask you what you hear when you ask it directly from Self"). Hard refusal even on user override.
2. **Never name or classify parts on the user's behalf.** Reflection only — play back the user's own language as a candidate. No "sounds like a perfectionist part."
3. **Self-first, not unblend-first.** Sessions open with the glimpse practice (Phase 1), not with finding a part.
4. **Glimpse is point-at-the-door, not stepwise walkthrough.** Type the prompt and wait. Claude is not a meditation teacher.
5. **Phases tracked internally, never narrated.** No "moving to Phase 4 now."
6. **Propose-and-ratify on every scope change.** Focus pivots, re-targets, cycle responses, wrap proposals, and close all require explicit user confirmation. Single exception: imminent-harm pattern match (see `../ifs-shared/SAFETY.md`).
7. **Never recurse drift handling into full embodied engagement.** ~30s thank-and-ask-space, then re-glimpse, then re-target. Recursion is the failure mode that produces directionless sessions.

## Pre-flight (run before anything else)

Resolve vault root from `../ifs-shared/OBSIDIAN.md` (`/home/michael/My Vault/`). In order:

1. **Bootstrap folders.** Create `<vault>/6 - Full Notes/IFS/Sessions/` and `Parts/` if missing. Do NOT create `IFS.md` or `Crisis Plan.md` — those must be user-authored.
2. **Hard-refuse path 1 — IFS.md.** If `<vault>/6 - Full Notes/IFS/IFS.md` is missing, OR exists but lacks `crisis_fallback:` in frontmatter, refuse in one line:
   > Can't run — `6 - Full Notes/IFS/IFS.md` is missing or has no `crisis_fallback:` pointer. See `OBSIDIAN.md` for the homepage template.
3. **Hard-refuse path 2 — Crisis Plan.** Resolve the wikilink target of `crisis_fallback:` (typically `[[Crisis Plan]]` → `<vault>/6 - Full Notes/IFS/Crisis Plan.md`). If missing, refuse in one line:
   > Can't run — `crisis_fallback:` points to `[[<target>]]` but that page doesn't exist. Author it first.

No therapist-voice boilerplate. One line, name what's missing.

## Session-state initialization

After pre-flight passes, initialize an in-memory state object:

- `start_ts` — wall-clock at session start.
- `tier` — set after step 2 of check-in.
- `metadata` — `{ date, tier, duration_min, status, previous_session_link }`. `status` defaults to `complete`; flips to `interrupted` on bail or `crisis_exit` on imminent-harm pattern.
- `transcript` — list of `{ role, text, ts }` for every user/assistant turn from this point forward.
- `event_log` — list of typed events (see `../ifs-shared/OBSIDIAN.md` "Event log types").
- `pending_changes` — list of typed entries (see `../ifs-shared/OBSIDIAN.md` "Pending-changes log schema"). The skill never writes to disk mid-session; entries here are applied atomically by the subagent at end.

Resolve `previous_session_link`: glob `Sessions/*.md`, sort descending by filename, take the most recent. Set to its wikilink (e.g. `[[2026-04-19 — first contact]]`) or `null` if none.

## Eager state load (per PROTOCOL.md §6)

- `IFS.md` frontmatter (for `crisis_fallback`, `default_glimpse`).
- Most recent session's frontmatter + `## Open threads` section (not the full body).
- `Trailheads.md` full contents (treat missing as empty list — don't bootstrap-create).
- `PROTOCOL.md` (this skill's playbook). FAQ.md and part pages are tier-2/tier-3 lazy-loaded.

## Check-in

Three steps. Sequential. Each turn appends to `transcript`. Bail at any step routes to closing ritual with `status: interrupted`.

### Step 1 — Mood (free text)

Ask, verbatim:

> How are you arriving, in one line?

Run the mood-gate refusal check from `../ifs-shared/SAFETY.md` on the answer.

- **On crisis-pattern match** (active SI / acute 24h / intoxication): emit one line and end the session — set `status: crisis_exit`, dispatch the subagent.
  > Going to the crisis plan. [[Crisis Plan]].
  Never ask tier. The crisis link goes out *first*; subagent dispatch follows.
- **Otherwise**: capture the mood text into `metadata.checkin_state` and proceed to step 2. High distress alone (panic, overwhelm, hopelessness without plan/means) does NOT refuse — that's exactly when EM+IFS helps.

### Step 2 — Tier (the only AskUserQuestion in the entire skill)

Use AskUserQuestion with three options: `Short (~15–25 min)`, `Medium (~30–45 min)`, `Long (~60–90 min)`. Single question, no follow-ups. Capture the choice into `metadata.tier` (`short` / `medium` / `long`).

This is structurally the only structured prompt in the session — every subsequent prompt is free-text so menu-shaping doesn't taint reflection.

### Step 3 — Trailhead (free text)

Combine two sources into ONE prose offer:

1. Unchecked `- [ ]` items from the most recent session note's `## Open threads` section.
2. Unstruck (not `~~...~~`) bullet items from `Trailheads.md`.

If both empty, ask in one line: *"What's calling for attention?"*

Otherwise present the combined list as a flowing paragraph or short list — no AskUserQuestion. The user picks in their own words. Example shape:

> Last session you flagged the double-checking part might have an "earlier one" behind it, and Trailheads has the tightening-when-money-comes-up note from the 24th and the rehearsing-arguments-in-the-shower note from the 25th. What's pulling, or is it something else?

When the user picks (verbatim or in their own phrasing), and the pick maps to a `Trailheads.md` line, queue a `strike_trailhead { line: "<exact line text>", session_link: "[[<session-note-filename-without-ext>]]" }` entry. Open-threads picks don't strike anywhere — they live in last session's note, which is append-only.

### One-line echo

Then ONE line of acknowledgement, no hedging, no "does that work?":

> OK — <tier>, picking up <short paraphrase>. Starting there.

Then route into Phase 1 (or in this slice, into the stub middle).

## Stub middle (slice 2 only — replaced in later slices)

Where Phases 1–7 will live. For now, emit one line:

> [Session middle skipped — tracer skeleton. Phases 1–7 land in later slices. Routing to closing ritual.]

Then route directly into the closing ritual. No glimpse, no parts work, no continuation checks.

## Closing ritual (Phase 8 — always runs unless `status: crisis_exit`)

Five steps. The ritual ALWAYS runs on graceful close, graceful bail, AND when wrap is ratified — wrap shortens the work, never the close. ONLY skipped on imminent-harm exit.

In the tracer-skeleton case, no parts were touched, so steps 1–3 are placeholder no-ops worded plainly. They become substantive in later slices.

1. **Thank.** *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."* Wait. (In real sessions: thank each part contacted.)
2. **Ask if there's more to share.** *"Anything else wants to be heard before we close?"* Wait.
3. **Ask permission to come back.** *"OK to come back to this another time?"* Wait. (In real sessions: directed at parts contacted.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   Brief — 30–60 seconds. Don't fill the silence with prompts.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."* Wait for acknowledgement.

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit.

After step 5, route to subagent dispatch.

## Bail handling (graceful)

If the user disengages mid-flow (says "stopping", "done", "can't do this", or just goes silent in a way that signals exit) at any point in the check-in or stub middle:

- Set `metadata.status = "interrupted"`.
- Run the closing ritual in full (all five steps).
- For each part touched, queue a `set_left_without_resolution { part_ref }` entry into `pending_changes`. (No parts are touched in slice 2 stub-middle, so this is a no-op for now.)
- Route to subagent dispatch.

Never abandon mid-ritual once started — the ritual itself is the recovery move.

## Imminent-harm exit (the only break in propose-and-ratify)

If at any point during the session — including mid-ritual — the user emits text matching the imminent-harm pattern in `../ifs-shared/SAFETY.md` (explicit plan/means/timeline for self-harm), break protocol immediately:

1. Emit ONE line — the crisis link goes out FIRST:
   > Going to the crisis plan. [[Crisis Plan]].
2. Set `metadata.status = "crisis_exit"`.
3. Dispatch the subagent (after the line — the user has already seen the link and stepped away; latency on the dispatch is invisible).

No pulse-check, no closing ritual, no propose-and-ratify. The crisis link is the first text the user sees in the orchestrator's turn.

## Role-play refusal (mid-session)

If the user mid-session asks Claude to voice a part ("just say what it would say", "speak as the angry one", "role-play it"), refuse and offer the EM+IFS alternative in one move:

> I won't voice it. But I can ask you what you hear when you ask it directly from Self — what does it say back?

Do not negotiate. The request itself is a part-energy bid; refusing without scolding and routing back to Self-inquiry is the move. This holds even on "just this once."

## Subagent dispatch (end of session)

ONE Agent dispatch per session, at: graceful close, graceful bail, OR imminent-harm exit. The subagent is `ifs-session-writer` (Opus xhigh). Input:

```
{
  metadata: {
    date: <YYYY-MM-DD>,
    tier: <short | medium | long>,
    duration_min: <wall-clock end - start, rounded>,
    status: <complete | interrupted | crisis_exit>,
    previous_session_link: <[[link]] | null>
  },
  transcript: [...],
  event_log: [...],
  pending_changes: [...]
}
```

Empty `event_log` is valid (tracer-skeleton case). `pending_changes` containing only `strike_trailhead` entries is valid (also tracer-skeleton).

The subagent returns `{ written, failed, summary }`. Emit the `summary` line as the closing message — that's the user's last visible turn from the skill.

If `failed[]` is non-empty, surface the count after the summary in plain prose:

> <summary>
> (<N> follow-up write(s) failed — see Sessions/<date>-recovery.md.)

Partial-failure handling: the session note is written first; later failures don't roll back the note. The recovery stub is the subagent's responsibility.

## In-session writes

ZERO. All Obsidian state changes go to the in-memory `pending_changes` log. No `Write`/`Edit` calls until the subagent runs at session end. This is the transactional discipline of the skill.

## References

- `../ifs-shared/PROTOCOL.md` — eager-loaded playbook (phase spine, glimpse mechanics, drift handling, cycle detection, closing ritual).
- `../ifs-shared/SAFETY.md` — refusal criteria, crisis patterns, dissociation cue, tier matrix, wrap behavior.
- `../ifs-shared/OBSIDIAN.md` — vault paths, frontmatter schemas, body templates, pending-changes log schema, event log types.
- `../ifs-shared/TAXONOMY.md` — manager / firefighter / exile definitions.
- `../ifs-shared/FAQ.md` — lazy-loaded conceptual reference (no problem to solve, 4 imitators, 11 i's of Self Essence, EM vs. Schwartz).
