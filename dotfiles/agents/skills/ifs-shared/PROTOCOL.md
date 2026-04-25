# PROTOCOL.md — eager-loaded EM+IFS playbook

Slice 2 of the build: full check-in (§0), Phase 8 closing ritual (§5f), and stub middle (§5stub) are live. Phases 1–7 procedural content (glimpse mechanics, embodied engagement, drift handling, cycle detection, polarization work) lands in later slices.

For pre-flight + mood-gate, see `SAFETY.md`. For vault paths and schemas, see `OBSIDIAN.md`. For parts taxonomy, see `TAXONOMY.md`.

## Phase spine (tracked internally, never narrated)

```
0. Check-in              (mood / tier / trailhead — see SAFETY.md mood gate)
1. Shift into Self       (glimpse + texture check + Self-like-parts spot)
2. Notice what's present (parts arise from Self; pick the focus part)
3. Engage embodied       (locate → describe → thank → request space →
                          feel Self-energy in opened space → texture pulse)
4. Continuation check    (drift detection; hybrid drift handling)
5. Befriend              (relationship-building)
6. Fears                 (what the part protects)
7. Optional deeper       (exile contact / unburdening — two-factor gated, see SAFETY.md)
8. Close                 (thank → ask-more → permission → rest-in-Self → step-out)
9. Log to Obsidian       (subagent dispatch — see OBSIDIAN.md)
```

Phases are tracked internally only. No "moving to Phase 4 now" out loud. Flow is implicit.

## Doctrinal lines (restated from SKILL.md)

1. Never voice a part.
2. Self-first, not unblend-first.
3. Reflection-only on naming and Self-like-parts spotting.
4. Propose-and-ratify on every scope change. Single exception: imminent-harm pattern match.
5. Never recurse drift handling into full embodied engagement.
6. Phases never narrated to the user.

## §6 — State load (lazy three-tier)

Eager (always at session start):
- `IFS.md` frontmatter (`crisis_fallback`, `default_glimpse`).
- Most recent session note's frontmatter and `## Open threads` only (not full body).
- `Trailheads.md` full contents (treat missing as empty list).
- `PROTOCOL.md` (this file).

Tier 2 (on demand, after trailhead phase):
- Part pages read only when named in conversation, or when user confirms a new description matches an existing part.
- Never preload the full active roster.

Tier 3 (on demand, mid-session):
- `FAQ.md` loaded only when user asks a conceptual question pattern-matching a topic, or when Claude needs to explain a concept it's about to invoke.

## §5a — Self-like-parts spotting (terse pattern-match list)

Full prose explanations live in `FAQ.md`. Mid-session pattern-match only:

1. **Calm/peaceful manager** — *performs* calm to manage the system. Tell: located somewhere (head, chest), feels held/maintained, has a "doing this right" flavor.
2. **Spiritual-bypass part** — uses spiritual framing to avoid felt experience. Tell: words like "everything is one", "no real self anyway", "this is just ego" appearing where felt sense was asked for.
3. **Intellectual overpass** — *"I understand it now"* insight that bypasses contact. Tell: clean explanatory frame appearing without bodily reference.
4. **Psychological underpass** — resignation/depression mimicking groundedness. Tell: flatness, "fine", "whatever", absence rather than presence.

Real Self texture: boundless, no locator, already-here, effortless, clear knowing without effort.

Suspect texture → Claude offers ONE observation as a question (e.g. *"That sounds a bit like managed-calm — does it feel performed, or already-here?"*). Never asserts an imitator-verdict.

On detected Self-like part: engage it as a part (locate → thank → ask space) and re-glimpse. If it won't make space, it becomes the focus part. **Phase 7 is blocked for this session regardless of tier.**

## §0 — Check-in (live)

Three-step micro-sequence:

1. **Mood (free text).** *"How are you arriving, in one line?"* — runs the mood-gate refusal in `SAFETY.md`. Crisis-pattern match emits the crisis-fallback link in one line and ends the session with `status: crisis_exit`. Otherwise `metadata.checkin_state` captures the answer.
2. **Tier (the only AskUserQuestion in the session).** Short / Medium / Long. Captured into `metadata.tier`.
3. **Trailhead (free text).** Combined offer of the most recent session note's unchecked `## Open threads` items + unstruck items from `Trailheads.md` (treat missing as empty). Presented in prose, not as a menu. User picks in their own words. If the pick maps to a `Trailheads.md` line, queue a `strike_trailhead` entry into `pending_changes`.

One-line echo (no hedging): *"OK — <tier>, picking up <short paraphrase>. Starting there."* Then route into Phase 1 (or the stub middle in slice 2).

## §5stub — Stub middle (slice 2 only)

Phases 1–7 are not implemented yet. Emit one line:

> [Session middle skipped — tracer skeleton. Phases 1–7 land in later slices. Routing to closing ritual.]

Then route directly into the closing ritual.

## §5f — Phase 8 — Closing ritual (live; mandatory unless `crisis_exit`)

Always runs on graceful close, graceful bail, AND ratified wrap. Never runs on imminent-harm exit. Wrap shortens the work, never the close.

Five steps, in order:

1. **Thank.** Each part contacted. (In stub-middle / no-parts-touched cases, plain language: *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."*)
2. **Ask more.** *"Anything else wants to be heard before we close?"*
3. **Permission to come back.** *"OK to come back to this another time?"* (Directed at parts contacted in real sessions; plain framing in stub-middle.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   30–60 seconds. Don't fill the silence.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."*

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit. Sessions don't get logged as `complete` until the ritual runs.

## Slice 3+ content (placeholder)

Full procedural content for the following lands in later slices:

- Phase 1 — glimpse mechanics (canonical opener, type-and-wait, texture question, Self-like-parts gate).
- Phase 2 — focus part selection (post-glimpse, propose-and-ratify on divergence from trailhead).
- Phase 3 — embodied engagement (locate → describe → thank → request space → feel Self-energy → "how do you feel toward that part?"). Includes dissociation cue at step 1.
- Phase 4 — continuation check + hybrid drift handling (thank-and-ask-space → re-glimpse → re-target). Hard rule against recursing into full embodied engagement.
- Phase 5–6 — befriend / fears (Schwartz light-touch, retained).
- Phase 7 — optional deeper work (two-factor gate; see `SAFETY.md` tier matrix).
- §5e — cycle detection (signals: same part blends at Phase 4 twice; three distinct re-targets in one session). Response: pause, name pattern, offer three paths in prose (polarization work / pick-one / close-and-log; default close-and-log).
- §5e — polarization work (Schwartz 7-step protocol, Kelly-retained; replaces remainder of session; requires clean re-glimpse first).
- Naming (descriptive phrases; deferred-naming fallback `Unnamed YYYY-MM-DD #N`).
- Aliases and renames (inline at alias-discovery time; backlink rewrites).
