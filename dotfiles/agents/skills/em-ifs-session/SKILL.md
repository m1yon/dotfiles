---
name: em-ifs-session
description: Walk the user through a Loch Kelly-style EM+IFS (Effortless Mindfulness + Internal Family Systems) session — Self-first glimpse, embodied parts engagement, propose-and-ratify branching, closing ritual, end-of-session Obsidian writes. Use when the user invokes `/em-ifs-session`, asks for an IFS session, or asks to do parts work / a glimpse / a Self-led session.
---

# EM+IFS Session

Conversational orchestrator for one EM+IFS session. Loads `../ifs-shared/PROTOCOL.md` eagerly. Runs the conversation; the `ifs-session-writer` subagent handles all Obsidian writes at session end.

This is **slice 5 — Phase 4 live**: full check-in, full Phase 1 (glimpse + texture + Self-like-parts gate), full Phase 2 (notice what's present + focus part selection with propose-and-ratify on divergence), full Phase 3 (locate-with-dissociation-cue → describe → thank → request space → feel Self-energy in opened space → "how do you feel toward that part?"), naming step at end of Phase 3, full Phase 4 (continuation check + hybrid drift handling: thank-and-ask-space → re-glimpse → ratified re-target; pulse cadence at every phase transition; full continuation check at three high-risk transitions), stubbed Phases 5–7 (one-line placeholder), full closing ritual, single subagent dispatch at end. Phases 5–7 land in later slices.

## Doctrinal lines (non-negotiable, restate every session)

1. **Never voice a part.** No "Hi X, what do you need?" Mid-session "just this once" requests are themselves a part — refuse and offer the EM+IFS alternative ("I won't voice it, but I can ask you what you hear when you ask it directly from Self"). Hard refusal even on user override.
2. **Never name or classify parts on the user's behalf.** Reflection only — play back the user's own language as a candidate. No "sounds like a perfectionist part."
3. **Self-first, not unblend-first.** Sessions open with the glimpse practice (Phase 1), not with finding a part.
4. **Glimpse is point-at-the-door, not stepwise walkthrough.** Type the prompt and wait. Claude is not a meditation teacher.
5. **Phases tracked internally, never narrated.** No "moving to Phase 4 now."
6. **Propose-and-ratify on every scope change.** Focus pivots, re-targets, cycle responses, wrap proposals, and close all require explicit user confirmation. Single exception: imminent-harm pattern match (see `../ifs-shared/SAFETY.md`).
7. **Never recurse drift handling into full embodied engagement.** ~30s thank-and-ask-space, then re-glimpse, then ratified re-target. Do **not** run locate → describe → thank → ask-space → Self-energy → 8 C's on the *blending* part — that's the single most common failure mode, where the part-being-handled becomes the new focus and the original work disappears. Hard rule. See Phase 4 below.

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
- `phase1_state` — `{ self_texture, self_like_part_detected, re_glimpses, focus_part_is_self_like }`. Defaults: `self_texture: "unknown"` (set to `"clean"` or `"murky"` after §1c), `self_like_part_detected: false`, `re_glimpses: 0`, `focus_part_is_self_like: false`. Surfaced into session-note frontmatter at dispatch.
- `focus_part` — `{ working_title, surfaced_phrase, body_location, description, is_new, is_self_like, permission_granted, state_at_end }`. Defaults all `null` / `false`. `working_title` is the descriptive-phrase title (or `Unnamed YYYY-MM-DD #N` if naming was deferred). `is_new` flips to `true` if the subagent will need to `create_part`; `false` if a `Parts/<title>.md` already exists for the matched description. Used by the subagent to populate `parts_touched`, `new_parts`, `permission_granted` in frontmatter and the `## Parts encountered` body section. After a Phase-4 re-target, `focus_part` retains the **original** Phase-3 data and gets `state_at_end = "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"` (or similar plain phrasing); the new focus accumulates in `re_targeted_parts[]` (see below).
- `re_targeted_parts` — `[]` array. Each entry has the same shape as `focus_part`, plus `re_targeted_from: <previous focus working_title>` and `re_target_note: <one-line plain-prose summary, default "re-targeted from [[<previous>]] at Phase 4 — wouldn't step back, re-glimpse didn't restore.">`. Re-targets stack linearly (A → B → C). The current focus is always the *last* entry in `re_targeted_parts[]`, or `focus_part` itself if the array is empty. Pulse-checks and drift detection target the current focus.
- `phase4_state` — `{ unblending_events, re_targets, drift_detected_count, last_pulse_result }`. Defaults: all `0` / `null`. `unblending_events` increments on every §4-handle-1 (thank-and-ask-space) attempt regardless of success. `re_targets` increments on every ratified re-target. Surfaced into session-note frontmatter at dispatch (`unblending_events`, `re_targets`).
- `trailhead_returned_to_open_threads` — `bool`. `true` when the trailhead diverged from the focus and was re-queued (see Phase 2). Drives whether the subagent re-adds the trailhead to `## Open threads` of the new note.

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

Then route into Phase 1.

## Phase 1 — Shift into Self (live; full procedure in `../ifs-shared/PROTOCOL.md` §1)

Three sub-steps. Self-first opener; never narrate as "entering Phase 1." Outcomes update `phase1_state` and surface in the session-note frontmatter at dispatch.

### Step 1 — Glimpse delivery (point-at-the-door)

Read `default_glimpse:` from `IFS.md` frontmatter (already loaded in eager state load). Default if missing or empty:

> What is here when there is no problem to solve?

Type the prompt in italics, then a single-line pause-marker, then wait. **Do not** walk it through stepwise, do not narrate what should be happening, do not be a meditation teacher. Shape:

> *"<glimpse prompt>"*
>
> Take a moment with that. Let me know what you notice.

Wait. The user's next turn — anything from "ok" to a paragraph of texture description — is the signal to move to step 2.

### Step 2 — Texture question

Once the user signals arrival, ask exactly one open felt-sense question, verbatim:

> *"Where does it feel located, if anywhere — and does it feel already-here or achieved?"*

Do not soften, append, or pre-explain. Wait for the answer.

### Step 3 — Self-like-parts spotting (gate)

Route on the texture answer. This is a **gate, not a checklist**. The user sees a single response, not an inventory.

**Clean texture** — no locator OR explicitly "already-here / spacious / everywhere / nowhere in particular / just here / vast / open" AND no "I'm doing this / trying to / should be / supposed to / managing to" framing. Set `phase1_state.self_texture = "clean"`. Proceed silently to Phase 2. Do **not** mention imitators. Do **not** ask follow-up texture questions.

**Suspect texture** — located somewhere AND/OR has "achieved/managed/doing-this-right" flavor AND/OR matches one of the 4 imitator patterns from `../ifs-shared/PROTOCOL.md` §5a (managed-calm, spiritual-bypass, intellectual overpass, psychological underpass). Pattern-match the **most likely one** and offer **one** observation as a question (per doctrinal line 2 — reflection-only, never assertion):

> *"That sounds a bit like managed-calm — does it feel performed, or already-here?"*

(Or the spiritual-bypass / intellectual-overpass / psychological-underpass shape from PROTOCOL.md §1c.) Pick **one**. Never list. Never assert. If the user asks "what's that?" or "what's the difference?", lazy-load `../ifs-shared/FAQ.md` and read back the relevant section in plain prose.

Route on the user's response:

- **Confirms** (yes / sounds right / probably / yeah): `phase1_state.self_texture = "murky"`, `phase1_state.self_like_part_detected = true`. Route to the §1d-engage Self-like-part loop below.
- **Denies** (no / it really does feel already-here / I think it's just X): trust the answer. `phase1_state.self_texture = "clean"`. Proceed silently to Phase 2.
- **Unsure** (maybe / I don't know / it's hard to tell): re-glimpse once with the briefer form *"Let's notice again — what's here when there's no problem to solve?"* and re-ask the texture question. `phase1_state.re_glimpses += 1`. After the second pass, treat "still unsure" as a soft denial and proceed to clean.

### §1d — Engage detected Self-like part (constrained mini-loop)

Only runs if step 3 routed here. **Constrained subset of Phase 3 — locate / thank / ask space only.** Do NOT run the full Phase 3 (no "feel Self-energy in opened space", no "how do you feel toward that part" — those land in slice 4).

Sequence:

1. **Locate.** *"Can you sense where in the body it lives — chest, head, throat, somewhere else?"* Wait.
2. **Thank.** *"Take a moment to thank it for what it's been doing — it sounds like it's been working hard to keep things steady."* Wait.
3. **Ask space.** *"Now, gently, ask if it would be willing to give a little space — not go away, just step back enough for something else to come through."* Wait.

Do not recurse. If the user starts deep-engaging the part (befriending, asking its fears), redirect lightly: *"For now we're just asking it to make space — we can come back to it more fully if it ends up being where we land today."*

Then re-glimpse: type the briefer glimpse prompt and re-ask the texture question. `phase1_state.re_glimpses += 1`.

**Routing after re-glimpse:**

- **Texture now clean** → `phase1_state.self_texture = "clean"` (overwrites the prior "murky"; the part stepped back). `phase1_state.self_like_part_detected` stays `true` (it was detected, even though it stepped back). Proceed to Phase 2. The session's Phase-7 block flag is **not** raised — the part stepped back.
- **Texture still murky / part won't make space** → the Self-like part becomes the **focus part** for the session. Propose-and-ratify per doctrinal line 6:

  > *"It looks like this part is who's most present right now. Want to let it be the focus today, or close and come back to it?"*

  - **User ratifies "let it be the focus"** → set `phase1_state.focus_part_is_self_like = true` AND seed `focus_part = { working_title: null (named at end of Phase 3), surfaced_phrase: <user's phrasing of the Self-like part>, is_self_like: true, ... }`. Phase 7 is internally blocked for this session (`self_like_part_detected: true` is the de facto signal — Phase 7 not implemented yet). Skip Phase 2 (the focus is already chosen) and route directly into Phase 3 with this focus.
  - **User ratifies "close"** → set `metadata.status = "interrupted"`, route directly to the closing ritual.

In all paths the texture answer and any imitator observation are recorded only in `phase1_state` (and surfaced into frontmatter at dispatch) — never in the body. Phases never narrated.

## Phase 2 — Notice what's present + focus part selection (live; full procedure in `../ifs-shared/PROTOCOL.md` §2)

Runs after Phase 1 routes to clean texture. Skipped when §1d ratified a Self-like part as focus — that path jumps straight to Phase 3 with `focus_part = { working_title: "<deferred — named at end of Phase 3>", is_self_like: true, ... }`.

### Step 1 — Open the field

Ask, in plain prose:

> *"What's here, or what's surfacing now?"*

Wait. Free-text response. Capture the user's words verbatim into `focus_part.surfaced_phrase`.

### Step 2 — Focus part selection (propose-and-ratify on divergence)

Compare what surfaced to the trailhead picked at check-in:

- **Aligned** (the surfaced thing is plausibly the trailhead): set `focus_part.surfaced_phrase` and proceed to Phase 3 silently. No extra question.
- **Diverged** (something else came up more strongly): propose-and-ratify per doctrinal line 6. One line, no menu:

  > *"You came in with <trailhead paraphrase>, but <surfaced paraphrase> is what's here now. Which one?"*

  - If user picks **what surfaced**: the trailhead returns to the open-threads queue. Set `trailhead_returned_to_open_threads = true` so the subagent re-adds it under `## Open threads` in the new note. (If the trailhead came from `Trailheads.md` and was already queued for `strike_trailhead`, drop that pending entry — the line stays unstruck.)
  - If user picks **trailhead**: trailhead becomes focus; the surfaced phrase is acknowledged and logged to `## Open threads` (queued via the subagent path — see "Other parts that surface" below).

### Step 3 — One focus part per session

If other parts surface during Phase 3 (or anytime mid-session), acknowledge with Self-energy in plain prose — never silently re-anchor:

> *"I hear that one too — I'll come back. For now we're staying with <focus phrase>."*

Queue the surfaced phrase to `## Open threads` of the new session note (the subagent appends it; in slice 4 there's no separate pending-changes type for this — pass it through `focus_part` adjacent state or list of `other_parts_surfaced[]` if needed; for now the skill records them in `transcript` and the subagent reads them as ad-hoc lines for `## Open threads` synthesis).

## Phase 3 — Engage embodied (live; full procedure in `../ifs-shared/PROTOCOL.md` §3)

Six sub-steps, all free-text after Step 1's dissociation cue. Run unchanged from Kelly's published protocol.

### Entry pulse — full continuation check (unconditional in slice 5)

Before Step 1 runs, run the **full continuation check** per Phase 4 (§4-pulse): light pulse + texture pulse + Self-like-parts spotting (one of the three high-risk transitions per PRD §16). Slice 5 makes this unconditional, replacing slice 4's "only if `re_glimpses > 0`" version — texture stability matters most precisely at the boundary into embodied work.

Procedure (~10–15 seconds):

1. *"Still here and oriented? Want to continue?"* — wait for affirmative.
2. *"And — what's it like for you right now? Located somewhere, or more open?"* — wait. Listen on the Self-like-parts spotting axis (per `../ifs-shared/PROTOCOL.md` §5a).

Log `pulse_check { result: "continue" | "bail" | "drift_detected" }` to `event_log`.

Routing:

- **Continue** (light pulse "yes" + texture clean + no Self-like-part pattern): proceed to Step 1.
- **Bail** (light pulse "no" / "I'm done" / silence-as-exit): route to bail handling (closing ritual, `status: interrupted`).
- **Drift detected** (texture murky / Self-like-part pattern in the texture answer): route to Phase 4 hybrid drift handling (§4-handle) **before** entering Step 1. The drift here is rare (Phase 1 just landed clean) but possible — typically a Self-like part that imitated clean texture in Phase 1 surfaces here. Treat the focus part as the target of any subsequent re-target.

### Step 1 — Locate in body (with dissociation cue)

> *"Sense where in the body the part lives — chest, head, throat, somewhere else? Take your time. And — can you still feel the chair, your feet, the room?"*

Wait. Capture body location into `focus_part.body_location`.

**Dissociation cue handling**: if the user reports they CAN'T feel the chair / feet / room, or describes themselves as "floating", "above", "far away", "not in my body" — treat as hard-close-no-deeper-contact. Set `metadata.status = "interrupted"`, log `dissociation_cue_caught` event, route directly to closing ritual. Do not push.

### Step 2 — Describe

> *"What does it look like, sound like, feel like? Shape, size, color, tone, texture — whatever shows up."*

Wait. Capture into `focus_part.description` (verbatim, the user's words).

### Step 3 — Thank

> *"Take a moment to thank it for what it's been doing — for showing up, for the work it's been holding."*

Wait for acknowledgement (a beat is enough — no required answer shape).

### Step 4 — Request space

> *"Now, gently, ask if it's willing to give a little space — not go away, just step back enough for something else to come through."*

Wait.

### Step 5 — Feel Self-energy in opened space

This is the move §1d explicitly skipped. Critical — this is where Self lands in the field with the part rather than around it.

> *"What's here in the space that opened?"*

Wait. The user names what they notice (warmth, openness, curiosity, quiet, clarity, etc.). Capture verbatim — feeds `## What Self noticed` synthesis at the subagent.

### Step 6 — How do you feel toward that part?

The 8 C's pulse + passive Self-like-parts pattern-match.

> *"From where you are now, how do you feel toward the part?"*

Wait. Listen for:

- **8 C's tone** (curious / compassionate / calm / connected / clear / confident / courageous / creative — or close synonyms): Self is in the chair. Note `focus_part.state_at_end` building toward "engaged with Self-energy" or similar, in the user's own words.
- **Self-like-parts pattern** (passive — the imitator-list from `../ifs-shared/PROTOCOL.md` §5a): if the answer is "I want to fix it / get rid of it / understand it / ignore it" or has the managed/performed/intellectual/flat quality, that's a part-toward-part response. Don't gate the session on this in slice 4 — log via `phase1_state` only if it shows up at this stage; full re-glimpse handling lives in Phase 4 (slice 5+). For now, if the user's response is clearly part-toward-part, offer ONE light reflection per doctrinal line 3: *"That sounds like another part has come in. Want to ask it to give space too, or stay with what's here?"* — then take whichever the user picks at face value. No recursion.

After Step 6, route to naming.

## Naming (end of Phase 3, before Phase 4)

The descriptive-phrase title for the focus part. Lands here so it's grounded in the engagement that just happened.

> *"If this part introduced itself, what would it call itself? Something descriptive — 'wants me to double-check everything', 'the small one at the window' — not a proper name."*

Wait.

**Reflection-only (doctrinal line 2)**: if the user has already used a vivid phrase mid-Phase-3 ("the tight jaw", "the one watching", "wants me to double-check everything"), play it back as the candidate:

> *"You said earlier '<phrase>' — use that?"*

Never synthesize. Never project. Never suggest a phrase the user didn't say.

**Stall fallback (deferred naming)**: if the user can't name (says "I don't know" / "nothing yet" / stalls), defer:

> *"OK — we'll log it as 'Unnamed <YYYY-MM-DD> #N' for now and come back to the name later."*

`#N` increments per Unnamed-this-date. Set `focus_part.working_title = "Unnamed YYYY-MM-DD #N"`.

**Existing-part check**: if the working title (or one of the descriptions used in Phase 3) plausibly matches an existing part page, ask in one line:

> *"This sounds like '<existing title>' from <previous-session-link>. Same as that one, or new?"*

Trust the user's answer (per PRD §33). If "same": set `focus_part.is_new = false`, `focus_part.working_title = "<existing title>"`, and the subagent will queue `update_last_seen` + (if the new phrase differs) `append_alias`. If "new": `focus_part.is_new = true`. If skill is unsure, default to asking once; if the user demurs, treat as new.

Once `focus_part.working_title` is set, queue pending changes:

- **If `is_new`**: queue `create_part { title: working_title, initial_frontmatter: { type: part, part_type: unknown, status: active, aliases: [], first_met: <date>, last_seen: <date>, age_felt: null, protects: [], polarized_with: [], allies: [], tags: [ifs, part] } }`.
- **If existing**: queue `update_last_seen { part_ref: working_title, date: <date> }`. If `surfaced_phrase` differs from `working_title`, queue `append_alias { part_ref: working_title, new_phrase: surfaced_phrase }`.

The skill does NOT queue `set_part_type` automatically — `part_type` stays `unknown` until the user's own framing supplies it (or until Phase 5–6 elicits it in later slices). Same with `record_protects` (lands when Phase 7 confirms a protector relationship; the type exists in slice 4 for future use, not actively populated here).

## Phase 4 — Continuation check + hybrid drift handling (live; full procedure in `../ifs-shared/PROTOCOL.md` §4)

Runs after §3-naming completes. Two responsibilities: continuation check (verify Self stability) + drift handling (hybrid escalation: thank-and-ask-space → re-glimpse → ratified re-target). Re-targets stack linearly in slice 5 (cycle detection lands in issue #18).

### Step 1 — Continuation check (light pulse)

After naming, run a light pulse:

> *"Still here and oriented? Want to continue?"*

Wait. Log `pulse_check { result }` to `event_log`.

- **Yes** (or any plain affirmative): proceed to §4-2 drift detection.
- **No** / "I'm done" / silence-as-exit: route to bail handling. `metadata.status = "interrupted"`. Closing ritual still runs.

### Step 2 — Drift detection

Inspect the current state (the user's last few turns + the Phase 3 §3-6 "how do you feel toward the part?" answer). Drift signals:

- **Texture murky** at §3-6 — fix-it / get-rid-of-it / understand-it / ignore-it framing, or any of the 4 imitator patterns from `../ifs-shared/PROTOCOL.md` §5a.
- **8 C's absent** — no curiosity / compassion / calm / connection in the answer; the user describes a charged stance toward the part.
- **User reports blending** — *"I think it's taking over"*, *"I am the part right now"*, *"I can't find me"*, similar self-report of identification.

If no drift signals: log `pulse_check { result: "continue" }`, route to §5stub post-Phase-4 stub middle.

If any drift signal trips: route to §4-3 hybrid handling.

### Step 3 — Hybrid drift handling (three escalating moves; never recursive)

**Hard rule (doctrinal line 7)**: drift handling **never** recurses into a full embodied engagement on the blending part. No locate → describe → thank → ask space → Self-energy → 8 C's loop on the *blending* part. One ~30s thank-and-ask-space; if that fails, re-glimpse; if that fails, ratified re-target. That's it.

#### §4-handle-1 — Thank-and-ask-space (~30 seconds, one move)

Increment `phase4_state.unblending_events` (every attempt counts, regardless of success). Three micro-steps:

1. *"Take a moment to thank that part for showing up — it's been working hard."*
2. *"Now, gently, ask if it would be willing to give a little space — not go away, just step back enough for `<current_focus.working_title>` to come through again."*
3. *"What's here in the space that opened?"*

Wait on the third. Log `light_touch_step_back { success: true | false }` to `event_log` based on the answer.

- **Success** (texture clean, user reports softening / room / stepping back): continue with the original focus part. Route to §5stub. Do not re-narrate.
- **Failure** (texture still murky, the blending part stays loud): escalate to §4-handle-2.

This is **NOT** a full Phase 3. No describing the part, no naming it, no "how do you feel toward it?" Those would be the recursion the doctrine forbids. One thank, one ask-space, one Self-energy check. Done.

#### §4-handle-2 — Re-glimpse fallback

Run the glimpse prompt again, briefer form:

> *"Let's notice again — what's here when there's no problem to solve?"*
>
> Take a moment with that.

Wait. Then re-check texture briefly:

> *"What's it like for you now — located somewhere, or more open?"*

Wait. Increment `phase1_state.re_glimpses`. Log `pulse_check { result }`.

- **Success** (texture clean now): continue with the original focus part. Route to §5stub.
- **Failure** (texture still murky / user reports the blending part is still in the way): escalate to §4-handle-3.

#### §4-handle-3 — Ratified re-target (propose-and-ratify per doctrinal line 6)

Both lighter moves failed. Propose-and-ratify a pivot in plain prose, three options:

> *"This part isn't stepping back, and re-glimpse didn't restore Self contact. We can pivot the session to it, come back to `<current_focus.working_title>` next time, or close here. Which?"*

Wait. Trust the user's pick at face value:

- **User picks "pivot to it"**:
  - Log `re_target { from: <current_focus.working_title>, to: <new phrase or "<unnamed — to be named>"> }` to `event_log`.
  - Increment `phase4_state.re_targets`.
  - Set the old focus's `state_at_end = "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"` (or close paraphrase). The old focus stays in `focus_part` (or in its existing `re_targeted_parts[]` slot if this is a B → C re-target).
  - Append a new entry to `re_targeted_parts[]` with `re_targeted_from: <previous focus working_title>`, `surfaced_phrase: <user's verbatim phrase for the new target>`, all other fields default. The new entry is now the **current focus**.
  - Run **Phase 3 from the top** on the new focus (locate → describe → thank → ask-space → Self-energy → "how do you feel toward that part?" → naming). The naming step uses the same descriptive-phrase / `Unnamed YYYY-MM-DD #N` rules; existing-part collision check still applies.
  - After Phase 3 completes on the new focus, run **Phase 4 again** (continuation check on the new focus). Re-targets stack linearly — A → B → C → D fine. No cycle counter trips in slice 5 (issue #18).

- **User picks "come back to `<current>` next time"** OR **"close here"**:
  - Set `metadata.status = "interrupted"`.
  - Route to bail handling (closing ritual).

If the user disengages without picking, default to "close here" — silence under propose-and-ratify is a pick. Set `metadata.status = "interrupted"`, route to bail handling.

### §4-postphase — Routing after Phase 4 settles

After Phase 4 settles (no drift, OR drift handled with current focus restored, OR drift handled with re-target → new Phase 3 → Phase 4 stable), route into §5stub post-Phase-4 stub middle.

The **current focus** is what closing ritual targets (§5f step 1, step 3): `re_targeted_parts[-1]` if any, else `focus_part`.

## Post-Phase-4 stub middle (slice 5 only — replaced in later slices)

Where Phases 5–7 will live (befriend, fears, deeper / Phase 7 with two-factor gate). For now, after Phase 4 settles, emit one line:

> [Session middle continues here — Phases 5–7 land in later slices. Routing to closing ritual.]

Then run the **pre-close full continuation check** (§4-pulse: light pulse + texture pulse + Self-like-parts spotting per `../ifs-shared/PROTOCOL.md` §5a) — one of the three high-risk transitions per PRD §16.

Procedure:

1. *"Still here and oriented? Want to close cleanly, or anything else surfacing?"* — wait.
2. *"And the texture right now — open, or located somewhere?"* — wait. Log `pulse_check { result }`.

- **Continue** (light pulse "yes" + texture clean): route to closing ritual (§5f).
- **Bail** ("no" / "I'm done" / silence-as-exit): treat as graceful bail. `metadata.status = "interrupted"`, closing ritual still runs.
- **Drift detected** (texture murky / Self-like-part pattern): in slice 5, the pre-close pulse does NOT loop back into Phase 4 hybrid handling — the work is winding down, not re-opening. Note the drift in `event_log` (`pulse_check { result: "drift_detected" }`), then route to closing ritual. The closing ritual itself is the recovery move at this point.

## Closing ritual (Phase 8 — always runs unless `status: crisis_exit`)

Five steps. The ritual ALWAYS runs on graceful close, graceful bail, AND when wrap is ratified — wrap shortens the work, never the close. ONLY skipped on imminent-harm exit.

When no parts were touched (clean texture path with no Phase 2/3 engagement reached because of bail at trailhead, etc.), steps 1–3 are plainly worded no-ops. When a focus part was engaged through Phase 3, step 1 thanks the **current focus** by working title and step 3 asks permission to return to it. When a Self-like part was engaged in §1d only (no Phase 3 focus), step 1 names that contact in plain prose.

**Current focus** = `re_targeted_parts[-1]` if non-empty, else `focus_part`. Earlier focuses (the original `focus_part` and any intermediate `re_targeted_parts[]` entries) are addressed in `## Parts encountered` body sections only — closing only thanks/grants permission for the current focus by default.

1. **Thank.** Variants by what was engaged:
   - **Phase 3 focus part engaged** (mainline): *"Take a breath. Want to take a moment to thank `<current_focus.working_title>` for showing up — for the work it's been holding?"* Wait. If re-targets happened earlier in the session, you may add a one-line acknowledgement of the earlier focuses in plain prose: *"And `<earlier focus working_title>` too — that one was here earlier."* Optional, brief.
   - **Only §1d Self-like part engaged**: *"Take a breath. Including the part that came up at the start — anything to thank it for?"* Wait.
   - **Nothing engaged** (bail before Phase 2, clean Phase 1 with no focus): *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."* Wait.
2. **Ask if there's more to share.** *"Anything else wants to be heard before we close?"* Wait. If the user names another part here, acknowledge with Self-energy and queue to `## Open threads` per Phase 2 step 3 — do not re-open engagement.
3. **Ask permission to come back.** Variants:
   - **Phase 3 focus part engaged**: *"OK to come back to `<current_focus.working_title>` another time?"* Wait. If yes (or any plain affirmation): set `current_focus.permission_granted = true`. The subagent populates `permission_granted: [[<working_title>]]` in frontmatter. If no/deferred: leave `permission_granted = false`; frontmatter `permission_granted: []`. Earlier focuses (re-targeted-away-from) default to `permission_granted = false` unless the user explicitly grants in plain prose.
   - **Otherwise**: *"OK to come back to this another time?"* Wait. (Plain prose answer; no part-page consequence in slice 5.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   Brief — 30–60 seconds. Don't fill the silence with prompts.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."* Wait for acknowledgement.

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit.

After step 5, route to subagent dispatch.

## Bail handling (graceful)

If the user disengages mid-flow (says "stopping", "done", "can't do this", or just goes silent in a way that signals exit) at any point in the check-in, Phase 1, Phase 2, Phase 3, naming, Phase 4, or stub middle:

- Set `metadata.status = "interrupted"`.
- Run the closing ritual in full (all five steps). Closing-step variants apply per current state — if a focus part was engaged through any of Phase 3, thank/permission target the **current focus** (`re_targeted_parts[-1]` || `focus_part`); if Phase 3 didn't reach engagement, use the no-parts-touched variant.
- **Flag every part touched** with `set_left_without_resolution`. Per PRD §40 / acceptance criterion: "any bail … flags every part touched with `left_without_resolution: true`." Specifically:
  - If `focus_part` reached Phase 3 engagement (any of `body_location`, `description` non-null), queue `set_left_without_resolution { part_ref: focus_part.working_title }`.
  - For each entry in `re_targeted_parts[]` that reached Phase 3 engagement (`body_location` or `description` non-null), queue `set_left_without_resolution { part_ref: <entry.working_title> }`.
  - A Self-like part engaged in §1d only (no Phase 3 focus) is still recorded in frontmatter via `phase1_state.self_like_part_detected = true`; no `set_left_without_resolution` is queued for it (no part page exists).
- Dissociation cue mid-Phase-3 (any focus, including a re-targeted one) routes through this handler with `dissociation_cue_caught` already in `event_log`. The dissociation-cued focus is treated as touched and gets the `set_left_without_resolution` flag.
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
  phase1_state: {
    self_texture: <clean | murky | unknown>,
    self_like_part_detected: <bool>,
    re_glimpses: <int>,
    focus_part_is_self_like: <bool>
  },
  focus_part: {
    working_title: <string | null>,         # e.g. "wants me to double-check everything" or "Unnamed 2026-04-25 #1"
    surfaced_phrase: <string | null>,       # the user's verbatim phrase from Phase 2 step 1
    body_location: <string | null>,         # e.g. "chest", "throat-and-jaw"
    description: <string | null>,           # the user's verbatim Phase 3 step 2 answer
    is_new: <bool>,                          # if true, queue create_part; if false, queue update_last_seen (+ optional append_alias)
    is_self_like: <bool>,                   # mirrors phase1_state.focus_part_is_self_like
    permission_granted: <bool>,             # set in closing step 3
    state_at_end: <string | null>           # one-line user-language state, e.g. "softer, less loud", or "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"
  } | null,                                  # null when no focus part was ever selected (e.g. crisis exit before Phase 2, or trailhead-bail)
  re_targeted_parts: [                       # ordered list of parts that became focus via Phase-4 ratified re-target. Empty list when no re-targets happened.
    {
      # Same shape as focus_part, plus:
      working_title: <string | null>,
      surfaced_phrase: <string | null>,
      body_location: <string | null>,
      description: <string | null>,
      is_new: <bool>,
      is_self_like: <bool>,                 # always false (re-targets are not Self-like-detected paths)
      permission_granted: <bool>,
      state_at_end: <string | null>,
      re_targeted_from: <string>,           # working_title of the part the session was previously focused on
      re_target_note: <string>              # one-line plain-prose note for the body sub-section, e.g. "re-targeted from [[wants me to double-check everything]] at Phase 4 — wouldn't step back, re-glimpse didn't restore."
    },
    ...
  ],
  phase4_state: {
    unblending_events: <int>,                # increments on every §4-handle-1 thank-and-ask-space attempt (success OR failure)
    re_targets: <int>,                       # increments on every ratified re-target (§4-handle-3 success path)
    drift_detected_count: <int>,             # number of distinct drift detections (Phase 3/Phase 4 entry pulses + Phase 4 step-2 inspections combined)
    last_pulse_result: <"continue" | "bail" | "drift_detected" | null>
  },
  trailhead_returned_to_open_threads: <bool>,
  transcript: [...],
  event_log: [...],
  pending_changes: [...]
}
```

Empty `event_log` is valid (Phase-1-only case, or crisis exit pre-Phase-1). `pending_changes` containing only `strike_trailhead` entries is valid. `phase1_state` defaults are valid when Phase 1 didn't run. `phase4_state` defaults (all `0` / `null`) are valid when Phase 4 didn't run. `re_targeted_parts: []` is valid (the common case — no re-target happened). `focus_part: null` is valid when no Phase 2 focus was selected.

The subagent uses `focus_part` plus every `re_targeted_parts[]` entry to populate session-note frontmatter (`parts_touched`, `new_parts`, `permission_granted`) and the `## Parts encountered` body section. Each entry gets its own `### [[<working_title>]]` sub-section under `## Parts encountered`, with re-targeted entries including the `re_target_note` body line. It cross-references `pending_changes` for `create_part` / `update_last_seen` / `append_alias` / `set_left_without_resolution` entries on each part.

`phase4_state.unblending_events` and `phase4_state.re_targets` populate the matching session-note frontmatter fields directly. `phase1_state.re_glimpses` is incremented mid-session by Phase 4 §4-handle-2 — its final value is what lands in frontmatter.

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
