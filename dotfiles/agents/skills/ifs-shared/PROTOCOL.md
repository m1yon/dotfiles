# PROTOCOL.md — eager-loaded EM+IFS playbook

Phase procedures (§0–§8), drift handling, cycle detection, polarization work, naming, rename mechanics, tier wrap clock, closing ritual.

For pre-flight + mood-gate, see `SAFETY.md`. For vault paths and schemas, see `OBSIDIAN.md`. For parts taxonomy, see `TAXONOMY.md`. For conceptual reference (the glimpse prompt, EM vs. Schwartz), see `FAQ.md`.

## Phase spine (tracked internally, never narrated)

```
0. Check-in              (tier / mood / trailhead — see SAFETY.md mood gate)
1. Shift into Self       (glimpse — point-at-the-door, no follow-up question)
2. Notice what's present (parts arise from Self; pick the focus part)
3. Engage embodied       (locate → describe → thank → request space →
                          feel Self-energy in opened space → 8 C's pulse)
4. Continuation check    (drift detection; thank-and-ask-space → ratified re-target)
5. Befriend              (relationship-building)
6. Fears                 (what the part protects)
7. Optional deeper       (exile contact / unburdening — two-factor gated, see SAFETY.md)
8. Close                 (thank → ask-more → permission → rest-in-Self → step-out)
9. Log to Obsidian       (subagent dispatch — see OBSIDIAN.md)
```

Doctrinal lines live in SKILL.md. Phases tracked internally; never narrated.

## §6 — State load (lazy three-tier)

Eager (always at session start):
- `IFS.md` frontmatter (`crisis_fallback`).
- Most recent session note's frontmatter and `## Open threads` only (not full body).
- `Trailheads.md` full contents (treat missing as empty list).
- `PROTOCOL.md` (this file).

Tier 2 (on demand, after trailhead phase):
- Part pages read only when named in conversation, or when user confirms a new description matches an existing part.
- Never preload the full active roster.

Tier 3 (on demand, mid-session):
- `FAQ.md` loaded only when user asks a conceptual question pattern-matching a topic, or when Claude needs to explain a concept it's about to invoke. Read back the relevant section in plain prose, not by reading the whole file aloud.

## §0 — Check-in

Three-step micro-sequence:

1. **Tier.** Ask open-endedly — *"Short, medium, or long today?"* — and let the user answer in their own words. Map the reply to short / medium / long and capture into `metadata.tier`. Asked first so the wrap clock has its bound before any free-text exchange.
2. **Mood (free text).** *"How are you arriving, in one line?"* — runs the mood-gate refusal in `SAFETY.md`. Crisis-pattern match emits the crisis-fallback link in one line and ends the session with `status: crisis_exit`. Otherwise `metadata.checkin_state` captures the answer.
3. **Trailhead (free text).** Combined offer of the most recent session note's unchecked `## Open threads` items + unstruck items from `Trailheads.md` (treat missing as empty). Presented in prose, not as a menu. User picks in their own words. If the pick maps to a `Trailheads.md` line, queue a `strike_trailhead` entry into `pending_changes`.

One-line echo (no hedging): *"OK — <tier>, picking up <short paraphrase>. Starting there."* Then route into Phase 1.

## §1 — Phase 1 — Shift into Self

Self-first opener. The session's architectural foundation. Runs immediately after the check-in's one-line echo. Never narrated as "entering Phase 1."

### §1a — Glimpse delivery (point-at-the-door)

Open with a brief settling preamble, then the glimpse prompt in italics, then a brief pause line — do **not** walk the glimpse itself through stepwise, do not break it into sub-steps, do not narrate what should be happening *during* the glimpse. The preamble warms the room; the glimpse itself stays untouched.

Shape:

> Let yourself arrive for a moment. Nothing to do here, nothing to manage — just a moment of noticing.
>
> *"What is here when there is no problem to solve?"*
>
> Take a moment with that.

Wait. Let the silence work. The user's next turn — anything from "ok" to a paragraph — is the signal to proceed to Phase 2. Do **not** ask a follow-up question about the glimpse (no "did that land?", no texture question). Trust the user; never make them intellectualize the experience.

**Re-glimpse** is the §1a prompt re-issued (briefer form acceptable: *"Let's notice again — what's here when there's no problem to solve?"*). It auto-triggers nowhere outside Phase 1. It remains available when (a) the user explicitly requests a moment to re-settle, (b) §4-polarization-work step 1 invokes it as a structural restart. Each invocation increments `re_glimpses`.

## §2 — Phase 2 — Notice what's present + focus part selection

Runs after Phase 1's glimpse settles (user's response to §1a is the readiness signal). Single conversational beat, no narration.

### §2a — Open the field

Verbatim:

> *"What's surfacing now — anything in the body, any feeling, anything asking for attention?"*

Wait. Capture the user's verbatim phrase as `focus_part.surfaced_phrase`.

### §2b — Focus part selection (propose-and-ratify on divergence)

Compare to the trailhead picked at check-in:

- **Aligned** (surfaced thing is plausibly the trailhead): proceed silently to Phase 3. No question, no narration.
- **Diverged** (something else came up more strongly): propose-and-ratify per doctrinal line 4. One line, plain prose, no menu:

  > *"You came in with <trailhead paraphrase>, but <surfaced paraphrase> is what's here now. Which one?"*

  Trust the user's pick at face value:
  - **Picks surfaced**: trailhead returns to `## Open threads` of the new note (skill sets `trailhead_returned_to_open_threads = true`). If trailhead was queued as `strike_trailhead`, drop that pending entry.
  - **Picks trailhead**: trailhead becomes focus; the surfaced phrase is acknowledged with Self-energy and logged to `## Open threads`.

### §2c — One focus part per session

Other parts surfacing during Phase 3 (or anytime after) get acknowledged with Self-energy in plain prose — never silently re-anchored:

> *"I hear that one too — I'll come back. For now we're staying with <focus phrase>."*

Surface them via `## Open threads` of the new session note. The skill never starts engaging a second part; the discipline is one focus per session.

## §3 — Phase 3 — Engage embodied

Six steps, free-text after Step 1. Run unchanged from Loch Kelly's published protocol. Pulse-check at entry per §4-pulse (full continuation check at this high-risk transition).

### §3-1 — Locate in body (with dissociation cue)

> *"Sense where in the body the part lives — chest, head, throat, somewhere else? Take your time. And — can you still feel the chair, your feet, the room?"*

Wait. Capture body location.

**Dissociation cue handling**: if user reports they CAN'T feel chair / feet / room, OR describes themselves as "floating", "above", "far away", "not in my body" — hard-close-no-deeper-contact. Set `metadata.status = "interrupted"`, log `dissociation_cue_caught`, route directly to closing ritual. Do not push.

### §3-2 — Describe

> *"What does it look like, sound like, feel like? Shape, size, color, tone, texture — whatever shows up."*

Wait. Capture verbatim into `focus_part.description`.

### §3-3 — Thank

> *"Take a moment to thank it for what it's been doing — for showing up, for the work it's been holding."*

Wait. Beat is enough — no required answer shape.

### §3-4 — Request space

> *"Now, gently, ask if it's willing to give a little space — not go away, just step back enough for something else to come through."*

Wait.

### §3-5 — Feel Self-energy in opened space

Critical: this is where Self lands in the field with the part rather than around it.

> *"What's here in the space that opened?"*

Wait. Capture the user's verbatim answer (warmth, openness, curiosity, quiet, clarity — or the opposite, e.g. "still tight" — whatever shows up). Feeds `## What Self noticed` synthesis.

### §3-6 — How do you feel toward that part?

The 8 C's pulse.

> *"From where you are now, how do you feel toward the part?"*

Wait. Listen for:

- **8 C's tone** (curious / compassionate / calm / connected / clear / confident / courageous / creative — or close synonyms): Self is in the chair. Note state in user's own words.
- **Drift signal** (passive): if the answer is "I want to fix it / get rid of it / understand it / ignore it", that's a part-toward-part response. Offer ONE light reflection: *"That sounds like another part has come in. Want to ask it to give space too, or stay with what's here?"* Take user's pick at face value; no recursion. (Phase 4 owns full drift handling if the user picks "ask it to give space.")

After §3-6, route to §3-naming.

## §3-naming — Naming (end of Phase 3)

Lands here so the descriptive-phrase title is grounded in the engagement that just happened.

> *"If this part introduced itself, what would it call itself? Something descriptive — 'wants me to double-check everything', 'the small one at the window' — not a proper name."*

Wait.

**Reflection-only (doctrinal line 3)**: if the user already used a vivid phrase mid-Phase-3, play it back as the candidate:

> *"You said earlier '<phrase>' — use that?"*

Never synthesize. Never project. Never suggest a phrase the user didn't say.

**Stall fallback (deferred naming)**: if user can't name (says "I don't know" / "nothing yet" / stalls):

> *"OK — we'll log it as 'Unnamed <YYYY-MM-DD> #N' for now and come back to the name later."*

`#N` increments per Unnamed-this-date.

**Existing-part check**: if working title plausibly matches an existing part page, ask in one line:

> *"This sounds like '<existing title>' from <previous-session-link>. Same as that one, or new?"*

Trust the user's answer. If "same": `is_new = false`, working_title = existing title, queue `update_last_seen` (+ `append_alias` if surfaced phrase differs). If "new": `is_new = true`, queue `create_part`. If unsure, ask once; if user demurs, treat as new.

Pending-changes queued at end of naming step:

- `is_new = true` → `create_part { title, initial_frontmatter: { type: part, part_type: unknown, status: active, aliases: [], first_met: <date>, last_seen: <date>, age_felt: null, protects: [], polarized_with: [], allies: [], tags: [ifs, part] } }`
- `is_new = false` → `update_last_seen { part_ref: working_title, date: <date> }` (+ `append_alias { part_ref: working_title, new_phrase: surfaced_phrase }` if different)

`part_type` defaults to `unknown` — never set automatically by the skill. User-supplied or Phase 5–6-elicited sets it via `set_part_type`. `record_protects` is queued only when a clear protector→exile relationship surfaces (see §6-4).

### §3-naming-rename — Inline collaborative rename offer

Fires only on the existing-part "same as X" path, AFTER `append_alias` has been queued (i.e. `surfaced_phrase` differs from the existing `working_title` and an alias was appended). One inline question, no follow-ups:

> *"Does '<existing working_title>' still fit, or want to rework it?"*

Wait. Trust the user's answer.

- **"Still fits"** (or any plain affirmative / silence-as-keep): no action. The alias was appended; the canonical title stays. Proceed to Phase 4.
- **"Want to rework"** (or any signal of openness): enter the collaborative rename loop below.

**Reflection-only collaborative rename loop (doctrinal line 3)**: never synthesize a name. Surface as candidates ONLY phrasings the user themselves has used in this session (across `surfaced_phrase`, `description`, mid-engagement asides, `befriend_notes`, `fears`) plus the existing aliases on the part page:

> *"You've used '<phrase A>' and '<phrase B>' this time, and the page already has '<alias>'. Anything in there closer, or something fresh?"*

Wait. Routes:

- **Picks one of the user's own phrasings** OR **offers a fresh phrasing**: `new_title = <picked / fresh phrase>`. Confirm step.
- **Demurs / "actually never mind"** OR **stalls**: no rename. Proceed to Phase 4.

**Confirm step**: *"Switching '<old_title>' to '<new_title>' — and the old phrasing stays as an alias. OK?"* Wait for affirmative.

On confirm, queue:

- `rename_part { old_title: <existing>, new_title: <picked phrase>, reason: <one-line user-language summary if offered, else null> }`

AND atomically update `pending_renames[<old_title>] = <new_title>` (the local pending-state view per OBSIDIAN.md "Pending-changes log schema"). Also update the live session-state in place:

- `focus_part.working_title = <new_title>`.
- For any `re_targeted_parts[]` entry with `working_title === <old_title>` or `re_targeted_from === <old_title>`, rewrite to `<new_title>`.

Earlier `pending_changes` entries referencing `<old_title>` as `part_ref` are NOT retroactively rewritten by the skill — the subagent's `part_ref` resolver walks `pending_renames` at write time.

Reflect verbatim phrasings only — even paraphrasing a user phrase is synthesis. Aliases are append-only; the old canonical title becomes the most recent alias entry on rename.

End-of-session mechanics (file rename + alias append + session-note backlinks become `[[New|old phrase]]` + other-part-page backlinks become plain `[[New]]`) live in `dotfiles/claude/agents/ifs-session-writer.md`.

## §4 — Phase 4 — Continuation check + hybrid drift handling

Runs after §3-naming completes. Two responsibilities:

1. **Continuation check** — verify Self is still in the chair before continuing.
2. **Drift handling** — if Self isn't, route through the hybrid escalation: thank-and-ask-space → re-glimpse → ratified re-target. Never recurse.

### §4-pulse — Pulse cadence

**Light pulse** at every phase transition: one line — *"Still here and oriented? Want to continue?"* Yes → continue. Anything else (no / "I'm done" / "actually I'm checking out a bit" / silence indicating exit) → branch to bail handling (closing ritual, `status: interrupted`).

Log every pulse to `event_log` as `pulse_check { result: "continue" | "bail" | "drift_detected" }`. (`drift_detected` is only emitted by §4-detect's behavioral signals during ongoing engagement, not by the light pulse itself.)

### §4-detect — Drift detection signals

After Phase 3 (or any time mid-engagement past Phase 3), watch for:

- **Part-toward-part framing** at the §3-6 "how do you feel toward the part?" answer — fix-it / get-rid-of-it / understand-it / ignore-it.
- **8 C's absent** — no curiosity / compassion / calm / connection in the answer; the user describes a charged stance toward the part.
- **User reports blending** — *"I think it's taking over"*, *"I am the part right now"*, *"I can't find me"*, or similar self-report of identification with the part.

If any signal trips:

1. Log `blend_at_f4 { blended_part_ref: <current focus working_title> }` to `event_log`.
2. Increment `cycle_state.blend_counts[<current focus working_title>]`.
3. **Check cycle signal 1** (repeat blend at Phase 4): if `cycle_state.blend_counts[<current focus>] >= 2`, route to §4-cycle (cycle handler) — do NOT run §4-handle. Identify the cycle pair best-effort: `[<blended part>, <previous focus this part re-targeted from, OR last surfaced "other part" from transcript context, OR null>]`. Set `cycle_state.cycle_detected = true`, `cycle_state.cycle_pair = <pair>`.
4. Otherwise route into §4-handle.

If no signals trip, continue (no narration; just keep going).

### §4-handle — Drift handling (two escalating moves, never recursive)

**Hard rule (doctrinal line 5)**: drift handling **never** runs a full embodied engagement on the blending part. No locate → describe → thank → ask space → Self-energy → 8 C's loop on the *blending* part. That recursion is the failure mode that produces directionless sessions where the part-doing-the-handling becomes the new focus and the original work disappears.

Two moves, in order. If thank-and-ask-space succeeds (space opens, the original focus is reachable again), continue with the original focus. If it fails, escalate to ratified re-target.

#### §4-handle-1 — Thank-and-ask-space (~30 seconds)

The blending part gets a brief acknowledgement and a request, in plain prose. Two micro-steps:

1. *"Take a moment to thank that part for showing up — it's been working hard."*
2. *"Now, gently, ask if it would be willing to give a little space — not go away, just step back enough for `<focus_part.working_title>` to come through again."*

Then attend to Self-energy in the opened space:

3. *"What's here in the space that opened?"*

Wait. Log `light_touch_step_back { success: true | false }` to `event_log`. Increment `unblending_events` regardless of success (the drift + attempted step-back is the count).

- **Success** (space opened, user reports softening / room / stepping back): continue with the original focus part. Do not re-narrate where you are.
- **Failure** (user can't sense space opening, the blending part stays loud): escalate to §4-handle-2.

This is **NOT** a full Phase 3. No "describe the part", no naming, no "how do you feel toward it" — those would be recursion. One thank, one ask-space, one Self-energy check. Done.

#### §4-handle-2 — Ratified re-target (propose-and-ratify, doctrinal line 4)

Thank-and-ask-space failed. The blending part is the real focus right now. Propose-and-ratify a pivot. Plain prose, three options:

> *"This part isn't stepping back, and re-glimpse didn't restore Self contact. We can pivot the session to it, come back to `<focus_part.working_title>` next time, or close here. Which?"*

Wait. Trust the user's pick at face value:

- **User picks "pivot to it"**:
  - Log `re_target { from: <original focus working_title>, to: <new phrase / placeholder if unnamed> }` to `event_log`. Increment `re_targets`.
  - Increment `cycle_state.re_targets_distinct` IF the new target hasn't been a focus before this session (track by working_title / surfaced_phrase across `focus_part` + `re_targeted_parts[]`).
  - **Check cycle signal 2** (re-target pile-up): if `cycle_state.re_targets_distinct >= 3`, set `cycle_state.cycle_detected = true`, `cycle_state.cycle_pair = [<original focus.working_title>, <new target's working_title or surfaced_phrase>]` (bookends). Route to §4-cycle. Do NOT run Phase 3 on the new focus.
  - **Otherwise**: append a new entry to `re_targeted_parts[]` (`re_targeted_from: <previous focus working_title>`); the new target becomes the current focus. Run Phase 3 → Phase 4 again on it. Re-targets stack linearly until signal 1 or signal 2 trips.

- **User picks "come back next time" or "close here"** (or silently disengages): `metadata.status = "interrupted"`, route to closing ritual. Bail handling queues `set_left_without_resolution` for every touched part.

### §4-stack — Re-target stacking semantics

- Original `focus_part` keeps its Phase-3 data with `state_at_end = "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"` (or close-paraphrase). On further re-targets, intermediate parts' `state_at_end` updates to mention the next re-target.
- Each new focus appends to `re_targeted_parts[]` with full Phase-3 data and `re_targeted_from: <previous focus working_title>`. Current focus is always the last entry; pulse-checks and drift detection target it.
- Subagent renders each part as its own `### [[<working_title>]]` sub-section under `## Parts encountered`. Re-targeted parts carry a body-line note from `re_targeted_parts[<N>].re_target_note`.

### §4-postphase — Post-Phase-4 routing

After Phase 4 completes (no drift detected, OR drift handled with current focus restored, OR drift handled with re-target → new Phase 3 → Phase 4 stable, OR cycle handled via `pick_one_and_commit`), route into Phase 5 (Befriend). The current focus = `re_targeted_parts[-1]` if non-empty, else `focus_part`.

### §4-cycle — Cycle detection

Triggered when `cycle_state.cycle_detected` flips `true` from §4-detect step 3 (signal 1: same part blended at Phase 4 twice) OR §4-handle-2 cycle-trip (signal 2: three distinct re-targets). The cycle handler **replaces** the rest of Phase 4 — no remaining §4-handle moves, no Phase 3 on a new focus.

Log `cycle_detected { signal: "repeat_blend" | "re_target_pile_up", parts: <cycle_pair as list> }` to `event_log`.

#### Step 1 — Pause and name the pattern (one line, prose)

Pattern-match the call-out by signal:

- **Signal 1** (repeat blend, `cycle_pair = [X, Y]`):
  > *"`<X>` and `<Y>` keep cycling — likely polarized. Pausing here."*
  (If `Y` is `null` — couldn't identify the other end: *"`<X>` keeps coming back — the system seems to be cycling around it. Pausing here."*)
- **Signal 2** (re-target pile-up):
  > *"The system seems too activated to land anywhere today — three different parts have come forward."*

One line. No therapist-voice. No softening.

#### Step 2 — Three-option offer (PROSE — never AskUserQuestion)

> *"Three ways from here: (i) work the polarization between `<a>` and `<b>` directly — different protocol, replaces the rest of the session. (ii) pick one of them to commit to today and let the others go to open threads. (iii) close and log the cycle, come back fresh next time. Which?"*

Wait. Trust the user's pick. Set `cycle_state.cycle_resolution`:

- **"polarization" / "(i)"**: → §4-polarization-work.
- **"pick one" / "(ii)"**: → §4-cycle-pick-one (resume Phase 5 on the committed focus).
- **"close" / "(iii)"**: → §4-cycle-close-and-log.
- **Disengages / silent / can't decide**: default to (iii) close-and-log.

#### §4-cycle-pick-one — Pick-one-and-commit

Plain prose, one line:

> *"If you had to work with just one of them today, which?"*

Wait. The picked part becomes the **current focus** for the rest of the session. Mutate `re_targeted_parts[]` so the picked part is the current focus (or, if it's the original `focus_part`, clear later re-targets so resolution lands there). The other parts in `cycle_pair` (and any other previously-current re-targets) go to `## Open threads` of the new note.

Queue `record_polarization { pair: <cycle_pair> }` in `pending_changes` (mirrored `polarized_with:` — even on pick-one path, the cycle observation is recorded across both pages).

Route to Phase 5 (per §4-postphase) on the committed focus.

#### §4-cycle-close-and-log — Close-and-log

Plain prose, one line:

> *"OK — logging the cycle. Closing here."*

Queue `record_polarization { pair: <cycle_pair> }` in `pending_changes`. Set `metadata.status = "complete"` (graceful close — the cycle was named, no further phase work). Skip remaining unworked phases. Route directly to §7-pre-close + closing ritual.

Subagent populates `## What Self noticed` with prose like *"`<a>` and `<b>` cycled — likely polarized. Closed and logged."*

### §4-polarization-work — Polarization work (Schwartz 7-step, Kelly-retained)

Activated when `cycle_state.cycle_resolution === "polarization_work"`. **Replaces remainder of session** — no Phase 5, no Phase 6, no Phase 7 on either polarized part. After step 7, route directly to §7-pre-close + closing.

Set `polarization_state.entered = true`, `polarization_state.pair = cycle_state.cycle_pair`.

**Hard rules**:

- Polarization work is entered with a re-glimpse (structural restart). User-bail at the post-glimpse light pulse falls back to §4-cycle-close-and-log.
- Polarization work is NOT: (a) full embodied engagement on each part — no locate → describe → thank → ask-space → Self-energy on either side; (b) a resolution attempt — the move is externalize / surface protections / ask cooperation / log; (c) role relinquishment — neither part is asked to step aside; both stay present.
- Doctrinal line 1 holds throughout. Never voice either part. All questions are Self-directed (asked of the user).

#### Step 1 — Re-glimpse + light pulse

> *"Before we work between them — let's notice again. What's here when there's no problem to solve?"*
>
> Take a moment with that.

Wait. Increment `phase1_state.re_glimpses`. Then light pulse: *"Ready to keep going?"* Log `pulse_check { result }`.

- **Continue**: proceed to step 2.
- **Bail / silence-as-exit**: *"OK — letting it be, logging the cycle, closing here."* Fall through to §4-cycle-close-and-log queueing + closing.

#### Step 2 — Name the polarization

> *"From where you are now — `<a>` and `<b>` seem tied up with each other. Does that feel right?"*

Wait. Trust the user's confirmation / refinement / denial:

- **Confirms**: proceed to step 3.
- **Refines pair** (e.g. *"actually it's `<b>` and `<c>`"*): update `polarization_state.pair` and `cycle_state.cycle_pair` to match user's reframe, proceed.
- **Denies cycle entirely** (*"I just couldn't find Self"*): polarization work is not the right move. Fall back to §4-cycle-close-and-log.

#### Step 3 — Externalize

Both parts visible simultaneously, externalized in front of the user. Both stay present (neither is asked to step back) — that's the structural difference from drift handling.

> *"Let `<a>` and `<b>` both be present in front of you — like you're seeing them across the room, not inside you. Can you sense them both?"*

Wait. If user can't externalize them (gets pulled back into one), gently restate once: *"Take your time — just enough distance to see them both at once."* If still can't, fall back to §4-cycle-close-and-log (externalization is load-bearing; without it, the rest doesn't work).

#### Step 4 — Self curious toward both, equally

> *"From Self, what does each of them need?"*

Wait. Capture user's verbatim reply (transcript context — no new pending-changes entry).

The phrasing is critical: *"what does each of them need"* (asked of the user, plural, equal weight). Never *"what does `<a>` say to `<b>`"* (that would invite voicing them at each other — doctrinal line 1 violation).

#### Step 5 — Surface what each protects

> *"And what does each of them protect — what would happen if it stopped?"*

Wait. Capture into `polarization_state.what_each_protects` as `[<verbatim for a>, <verbatim for b>]`. (Empty-string fallback if user only lands one side — don't push.)

If a clear protector→exile relationship surfaces for either side that wasn't already captured in §6-4, optionally queue `record_protects` per the same rules.

#### Step 6 — Ask for cooperation, not merger

> *"Would both of them be willing to let Self lead for a bit — not to merge, not to switch, just to make space for each other?"*

Wait. Trust user's report:

- **Both agree**: `polarization_state.cooperation_agreed = true`.
- **One declines / both decline / partial / unclear**: `polarization_state.cooperation_agreed = false`. The polarization is named and surfaced; cooperation is not enforceable. The work has happened.

Either way, proceed to step 7. Do NOT loop back asking again.

#### Step 7 — Log

`polarization_state.completed = true`. Log `polarization_work { pair: <polarization_state.pair> }` to `event_log`.

Queue `record_polarization { pair: <polarization_state.pair> }` in `pending_changes`. Subagent mirrors `polarized_with:` on both part pages.

Route to §7-pre-close + closing. Polarization work **replaces** remainder of session — no Phase 5, no Phase 6, no Phase 7 on either polarized part.

Closing ritual targets the **current focus** (last entry in `re_targeted_parts[]` if any, else `focus_part`). The original focus and any intermediate re-targets are addressed in `## Parts encountered` body sections only — closing's permission-to-return question targets the most-engaged-most-recently part. If user wants to grant permission for multiple, they say so in plain prose; the skill defaults to current-focus-only for `permission_granted` frontmatter.

## §5 — Phase 5 — Befriend

Runs after Phase 4 settles (no drift, OR drift handled with current focus restored, OR drift handled with re-target → new Phase 3 → Phase 4 stable). Schwartz-orthodox relationship-building, Kelly-retained: the user gets to know the part better from Self. Always Self-directed; never role-played; doctrinal line 1 holds.

Current focus = last entry in `re_targeted_parts[]` if non-empty, else `focus_part`. Phase 5 prompts target the current focus's `working_title`.

### §5-1 — Light pulse on transition

Phase 4 → Phase 5 is a phase transition (not high-risk). Light pulse only:

> *"Still here and oriented? Want to continue?"*

Wait. Yes → §5-2. Anything else → bail handling (closing ritual, `status: interrupted`).

### §5-2 — Relationship-building (Self-directed)

The canonical Schwartz/Kelly Phase 5 question, verbatim:

> *"What does it want you to know?"*

Wait. The user listens to the part from Self and reports what surfaces in their own words. Capture verbatim into `current_focus.befriend_notes` (append).

Optional follow-up if the user lands a substantive answer and signals "more is here" (or after a pause, if more seems present):

> *"What would help it relax?"*

Wait. Append to `current_focus.befriend_notes`. Two-question max in a clean run; in free-text exchanges the user may volunteer more — capture each turn.

Set `phase5_state.befriend_complete = true` once any substantive answer lands. Log `befriend_complete { part_ref: <current_focus.working_title> }` to `event_log`.

### §5-3 — Reflection-only stance (doctrinal line 3)

Claude **never tells the user** what the part wants or what would help it. Reflection only. If the user asks "what do you think it wants?":

> *"That's for it to tell you. Take a moment — listen, and see what comes back."*

Never synthesize. Never project. Never paraphrase the part's "voice." Playing back the user's own vivid phrase once is acceptable (e.g. user says *"it says it's tired"* → Claude may reply *"Tired — OK."*); anything beyond that is interpretation.

### §5-4 — Propose-and-ratify Phase 5 → Phase 6 transition

Phase 5 → Phase 6 is a real scope change (different relational vector — relationship-building → fears). Propose-and-ratify per doctrinal line 4. Plain prose, one line:

> *"There's a question that often comes next — what would happen if it stopped doing what it's doing? OK to ask, or stay here a bit?"*

Wait. Trust the user's pick:

- **"Ask"** (or any plain affirmative): set `phase5_state.transition_to_phase_6_ratified = true`. Route to §6.
- **"Stay here"** (or wants more time / another follow-up): loop back to §5-2 with another open turn. After the user signals settled, re-offer the transition. If user declines transition entirely, route directly to §7-0 (skip Phase 6) once user signals done with befriend; Phase 7's gate evaluation handles whether deeper work runs or routes to §7-block + §7-pre-close.
- **"Close" / disengages**: bail handling. Silence under propose-and-ratify defaults to "close here."

## §6 — Phase 6 — Fears

Runs after Phase 5's transition is ratified. The canonical Schwartz "what does it fear if it stopped its job?" move. Surfaces what the part protects. Self-directed; never voiced.

### §6-1 — Light pulse on transition

> *"Still here and oriented? Want to continue?"*

Wait. Yes → §6-2. Anything else → bail handling.

### §6-2 — Wrap-clock check

Run `wrap_check()` (§wrap) at the entrance of Phase 6.

- If a soft or firm wrap fires AND the user ratifies "wrap": route directly to §7-pre-close + closing (Phase 6 deferred).
- If user picks "keep going" at the soft wrap (silenced for ~10 min) OR no trigger fires: proceed to §6-3.

### §6-3 — Fear question

Verbatim:

> *"What does it fear would happen if it stopped doing its job?"*

Wait. Capture verbatim into `current_focus.fears` (append).

Set `phase6_state.fears_surfaced = true` once a substantive answer lands. Log `fears_surfaced { part_ref: <current_focus.working_title> }` to `event_log`.

### §6-4 — Protector → exile capture (optional)

If the fear-answer reveals a clear protector→exile relationship — e.g. *"if it stopped, the small one inside would be alone again"*, *"there's a younger one underneath"* — capture it. Reflection-only verification, one line:

> *"You named '<exile descriptor>' just now. Should I log that as what this part is protecting?"*

Wait. Trust the answer:

- **Confirms**: queue `record_protects { part_ref: <current_focus.working_title>, exile_ref: <exile descriptor or [[<existing-exile-title>]]> }`. Set `current_focus.protects_ref = <exile descriptor>`. Set `phase6_state.protector_relationship_captured = true`.
  - `exile_ref` may be a **description-only placeholder** (e.g. `"the small one inside"`) when the exile hasn't been contacted yet. Phase 7 is where exile contact happens; Phase 6 just captures the relationship.
  - If the descriptor exactly matches a known part page (best-effort skill-side glob over `Parts/`), use the wikilink form `[[<existing title>]]`.
- **Denies / unsure**: don't queue. The fear text stays captured in `current_focus.fears`; the relationship can land in a later session.

If no protector→exile relationship surfaces (the fear is impersonal, e.g. *"chaos would break out"*, *"I'd lose my job"*), don't probe.

### §6-5 — One follow-up (optional)

If the first fear-answer was brief and more seems present, offer one follow-up:

> *"Anything else it's holding?"*

Wait. Append to `current_focus.fears`. Don't loop more than once — Phase 6 is single-question with at most one follow-up. Going deeper is Phase 7.

### §6-6 — Body sections at end of Phase 6

After Phase 6 settles, the part page body sections `## Role` / `## Fears` / `## What it needs from Self` are populated by the subagent from `befriend_notes` + `fears` + (if applicable) `protects_ref`. The skill does NOT write any of this directly. No additional pending-changes type needed; the part page is touched via `update_last_seen` (or `create_part`) and the subagent Edits the body sections at write time. `## Burdens` may be inferred lightly when fear patterns suggest a burden, but full burden work is Phase 7 — typically `## Burdens` stays as the empty-heading template line.

## §7 — Phase 7 — Optional deeper work

Optional deeper work — exile contact and (optionally) unburdening. **Two-factor gated** (tier + protector permission). Doctrinal line 7 governs: stable Self bears the unbearable; the protector-permission step is the safety floor (a protector won't release its exile when Self isn't holding).

Runs after Phase 6 settles, IF the gate passes. If either gate fails, Phase 7 is blocked and the session routes to §7-pre-close, then closing.

### §7-0 — Wrap-clock check + light pulse

Run `wrap_check()` (see §wrap below) at the entrance of Phase 7. If a wrap fires AND the user ratifies "wrap", route directly to §7-pre-close + closing — Phase 7 is skipped. If user picks "keep going", emit the standard transition light pulse: *"Still here and oriented? Want to continue?"* Bail → graceful bail (`status: interrupted`). Continue → §7-1.

### §7-1 — Tier permits check (factor 1)

Set `phase7_state.gates_evaluated = true`.

- **Short tier**: factor 1 fails. `gates_block_reason = "tier_short"`. Route to §7-block.
- **Medium tier**: factor 1 requires explicit user request earlier in session. If `phase7_state.explicit_request === true`: pass. Else: `gates_block_reason = "tier_medium_no_explicit_request"`. Route to §7-block. Do NOT prompt the user for a deeper-work request — the protocol leaves it to the user to surface.
- **Long tier**: factor 1 passes by default.

### §7-2 — Protector permission check (factor 2)

The current focus = `re_targeted_parts[-1]` if non-empty, else `focus_part`. The current focus is the protector. Plain prose, one line:

> *"Before reaching the part it's protecting — does `<current_focus.working_title>` give permission to go to that one?"*

Wait. Trust the answer:

- **Confirms**: pass. Set `current_focus.permission_granted = true`. Set `phase7_state.gates_passed = true`.
- **Denies / unsure**: `gates_block_reason = "no_protector_permission"`. Route to §7-block.

### §7-3 — Exile contact

All four gates pass. Set `phase7_state.exile_contact = true`. Log `exile_contact { part_ref: <exile_ref> }`.

`exile_ref` defaults to `current_focus.protects_ref` if Phase 6 step 4 captured one, else collected fresh from the user. Set `phase7_state.exile_ref`.

Sequence (free-text, wait at each, never voice):

1. **Locate.** *"Now — gently — let `<current_focus.working_title>` step aside, and ask if the part it's protecting is willing to be felt. Where is it in the body?"* Wait.
2. **Describe.** *"What does it look like, sound like, feel like? Take your time — this part has been waiting."* Wait.
3. **Thank.** *"From Self, take a moment with this part — let it know you see it, and that you're here."* Wait.
4. **Self-presence.** *"What's here in the space, between you and it?"* Wait. Feeds `## What Self noticed`.
5. **What it needs.** *"What does this part need from you right now? Not what it needs to do, but what it needs to receive."* Wait.

Reflection-only stance (doctrinal line 3). Never voice the exile (doctrinal line 1). Play back the user's own words once if helpful; no more.

### §7-4 — Unburdening (optional)

Propose-and-ratify per doctrinal line 4, plain prose, one line:

> *"There's a move that often comes next, if it's ready — letting it release the extreme thing it's been carrying. Want to offer that, or stay with what's here?"*

Wait. Trust the answer:

- **Confirms**: proceed.
- **Stay here / not yet**: skip unburdening. Phase 7 ends. Route to §7-pre-close.
- **Close / disengages**: bail handling.

Unburdening protocol (Schwartz-orthodox, Kelly-retained, Self-directed):

1. *"Ask this part what it's been carrying — not what its job is, but what it's been holding that isn't really its."* Wait.
2. *"Where does it want to release it — to light, to water, to earth, to wind, to someone, somewhere else? It chooses."* Wait.
3. *"Take your time — let it release, in its own way. Let me know when it has."* Wait.
4. *"What's here now, in the space where the burden was?"* Wait.
5. *"What does it want to invite in instead — what quality, what feeling, what sense?"* Wait.

Once step 5 lands a substantive answer: set `phase7_state.unburdening = true`. Log `unburdening { part_ref: <exile_ref> }`. Queue `set_status { part_ref: <exile_ref>, status: unburdened }` IF `exile_ref` is a `[[<existing-title>]]` wikilink (descriptor-only placeholders are NOT queued for `set_status` — there's no part page to update).

After unburdening (or after declining), route to §7-pre-close.

### §7-block — Phase 7 blocked routing

Emit ONE line, plain prose, no apology, no therapist-voice:

> Holding deeper work for next time.

Route to §7-pre-close.

### §7-pre-close — Pre-close light pulse

Always runs after Phase 7 settles (whether full, blocked, or wrap-skipped).

> *"Still here and oriented? Want to close cleanly, or anything else surfacing?"* — wait. Log `pulse_check`.

- **Continue**: route to closing (§5f).
- **Bail**: graceful bail. Closing still runs.

The closing ritual targets the **current focus**. Permission-to-return targets the current focus by working title.

## §wrap — Tier wrap clock

Silently track `elapsed_min = now - start_ts` against `wrap_state.tier_upper_min` (set at check-in step 1: `short → 25`, `medium → 45`, `long → 90`). Wrap-clock checks fire at every phase transition AND mid-phase between user turns when the elapsed time changes — **never mid-prompt-wait**. Wrap proposals NEVER cut a phase mid-step; if elapsed crosses a threshold mid-engagement, finish the current phase's contact, then propose at the next natural seam.

`wrap_check()` decision tree (called at every phase transition + every Phase 7 sub-step entrance):

1. Compute `elapsed_min = now - start_ts`. Read `wrap_state.tier_upper_min`.
2. **Crisis pattern override**: imminent-harm pattern matches close immediately regardless of `wrap_state` — see `SAFETY.md` imminent-harm. The wrap clock is silent in that path.
3. **Firm wrap** (`elapsed_min >= tier_upper_min` AND NOT `firm_wrap_proposed`):
   - Set `firm_wrap_proposed = true`, `last_wrap_propose_at = now`.
   - One line, plain prose:
     > *"We're at your time. Heading to close now."*
   - **Affirms / silent ~30s**: route to closing. `wrap_ratified = true`.
   - **Pushes back** ("a few more minutes"): allow brief landing, then re-propose closing immediately after the user's next substantive answer. Firm wrap doesn't honor extension as re-set.
4. **Soft wrap** (`elapsed_min >= tier_upper_min - 5` AND NOT `soft_wrap_proposed` AND (`wrap_silenced_until_at` null OR `now >= wrap_silenced_until_at`)):
   - Set `soft_wrap_proposed = true`, `soft_wrap_proposed_at = now`, `last_wrap_propose_at = now`.
   - One line, plain prose:
     > *"We're near your time — want to close, or keep going?"*
   - **Close / wrap / let's stop**: `wrap_ratified = true`. Skip remaining unworked phases. Route to §7-pre-close + closing.
   - **Keep going / continue / a few more minutes**: `wrap_silenced_until_at = soft_wrap_proposed_at + 10min`. Continue. Extension is **ad-hoc** — never pre-declared at check-in; no "how much more?" question.
   - **Silence / disengages**: silence under propose-and-ratify defaults to "close here." `wrap_ratified = true`, route to §7-pre-close + closing.
5. **No trigger**: silent no-op.

Closing ritual once started runs to completion — no `wrap_check()` inside the ritual. Even firm wrap routes through §5f closing; only imminent-harm exit skips it.

**Mid-Phase-7 wrap behavior**: if wrap crosses a threshold while the user is mid-answer at e.g. unburdening step 3 ("let it release"), let them land step 4 ("what's here now"), then propose at the next natural seam (before step 5). "Wrap never cuts mid-phase" means complete the phase's *contact*.

Wrap proposals are propose-and-ratify; only imminent-harm pattern match overrides.

## §5f — Phase 8 — Closing ritual (mandatory unless `crisis_exit`)

Runs on graceful close, graceful bail, and ratified wrap. Five steps, in order:

1. **Thank.** Each part contacted. (In stub-middle / no-parts-touched cases, plain language: *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."*)
2. **Ask more.** *"Anything else wants to be heard before we close?"*
3. **Permission to come back.** *"OK to come back to this another time?"* (Directed at parts contacted in real sessions; plain framing in stub-middle.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   30–60 seconds. Don't fill the silence.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."*

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit. Sessions don't get logged as `complete` until the ritual runs.

