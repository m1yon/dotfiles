---
name: em-ifs-session
description: Walk the user through a Loch Kelly-style EM+IFS (Effortless Mindfulness + Internal Family Systems) session — Self-first glimpse, embodied parts engagement, propose-and-ratify branching, closing ritual, end-of-session Obsidian writes. Use when the user invokes `/em-ifs-session`, asks for an IFS session, or asks to do parts work / a glimpse / a Self-led session.
---

# EM+IFS Session

Conversational orchestrator for one EM+IFS session. Loads `../ifs-shared/PROTOCOL.md` eagerly. Runs the conversation; the `ifs-session-writer` subagent handles all Obsidian writes at session end.

This is **slice 4 — Phases 2–3 live**: full check-in, full Phase 1 (glimpse + texture + Self-like-parts gate), full Phase 2 (notice what's present + focus part selection with propose-and-ratify on divergence), full Phase 3 (locate → describe → thank → request space → feel Self-energy in opened space → "how do you feel toward that part?"), naming step at end of Phase 3 (descriptive phrase or `Unnamed YYYY-MM-DD #N` deferred), stubbed Phases 4–7 (one-line placeholder), full closing ritual, single subagent dispatch at end. Phases 4–7 land in later slices.

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
- `phase1_state` — `{ self_texture, self_like_part_detected, re_glimpses, focus_part_is_self_like }`. Defaults: `self_texture: "unknown"` (set to `"clean"` or `"murky"` after §1c), `self_like_part_detected: false`, `re_glimpses: 0`, `focus_part_is_self_like: false`. Surfaced into session-note frontmatter at dispatch.
- `focus_part` — `{ working_title, surfaced_phrase, body_location, description, is_new, is_self_like, permission_granted, state_at_end }`. Defaults all `null` / `false`. `working_title` is the descriptive-phrase title (or `Unnamed YYYY-MM-DD #N` if naming was deferred). `is_new` flips to `true` if the subagent will need to `create_part`; `false` if a `Parts/<title>.md` already exists for the matched description. Used by the subagent to populate `parts_touched`, `new_parts`, `permission_granted` in frontmatter and the `## Parts encountered` body section.
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

Six sub-steps, all free-text after Step 1's dissociation cue. Run unchanged from Kelly's published protocol. Pulse-check at entry (light "still here and oriented?") only if Phase 1 had `re_glimpses > 0` or any §1d engagement happened — otherwise the glimpse just landed and a pulse is unnecessary friction.

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

## Naming (end of Phase 3, before Phase 4 stub)

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

## Post-Phase-3 stub middle (slice 4 only — replaced in later slices)

Where Phases 4–7 will live (drift handling, befriend, fears, deeper). For now, after Phase 3 + naming complete, emit one line:

> [Session middle continues here — Phases 4–7 land in later slices. Routing to closing ritual.]

Then route into the closing ritual. The focus part has been engaged through Phase 3; permission-to-return question lives in the closing ritual proper.

## Closing ritual (Phase 8 — always runs unless `status: crisis_exit`)

Five steps. The ritual ALWAYS runs on graceful close, graceful bail, AND when wrap is ratified — wrap shortens the work, never the close. ONLY skipped on imminent-harm exit.

When no parts were touched (clean texture path with no Phase 2/3 engagement reached because of bail at trailhead, etc.), steps 1–3 are plainly worded no-ops. When a focus part was engaged through Phase 3 (slice 4's mainline), step 1 thanks it by working title and step 3 asks permission to return to it. When a Self-like part was engaged in §1d only (no Phase 3 focus), step 1 names that contact in plain prose.

1. **Thank.** Variants by what was engaged:
   - **Phase 3 focus part engaged** (slice 4 mainline): *"Take a breath. Want to take a moment to thank `<focus_part.working_title>` for showing up — for the work it's been holding?"* Wait.
   - **Only §1d Self-like part engaged**: *"Take a breath. Including the part that came up at the start — anything to thank it for?"* Wait.
   - **Nothing engaged** (bail before Phase 2, clean Phase 1 with no focus): *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."* Wait.
2. **Ask if there's more to share.** *"Anything else wants to be heard before we close?"* Wait. If the user names another part here, acknowledge with Self-energy and queue to `## Open threads` per Phase 2 step 3 — do not re-open engagement.
3. **Ask permission to come back.** Variants:
   - **Phase 3 focus part engaged**: *"OK to come back to `<focus_part.working_title>` another time?"* Wait. If yes (or any plain affirmation): set `focus_part.permission_granted = true`. The subagent populates `permission_granted: [[<working_title>]]` in frontmatter. If no/deferred: leave `permission_granted = false`; frontmatter `permission_granted: []`.
   - **Otherwise**: *"OK to come back to this another time?"* Wait. (Plain prose answer; no part-page consequence in slice 4.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   Brief — 30–60 seconds. Don't fill the silence with prompts.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."* Wait for acknowledgement.

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit.

After step 5, route to subagent dispatch.

## Bail handling (graceful)

If the user disengages mid-flow (says "stopping", "done", "can't do this", or just goes silent in a way that signals exit) at any point in the check-in, Phase 1, Phase 2, Phase 3, naming, or stub middle:

- Set `metadata.status = "interrupted"`.
- Run the closing ritual in full (all five steps). Closing-step variants apply per current state — if a focus part was engaged through any of Phase 3, thank/permission target it; if Phase 3 didn't reach engagement, use the no-parts-touched variant.
- If a focus part page was created or updated this session (any Phase 3 engagement reached), queue `set_left_without_resolution { part_ref: focus_part.working_title }`. A Self-like part engaged in §1d only (no Phase 3 focus) is still recorded in frontmatter via `phase1_state.self_like_part_detected = true`; no `set_left_without_resolution` is queued for it (no part page exists).
- Dissociation cue mid-Phase-3 routes through this handler with `dissociation_cue_caught` already in `event_log`.
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
    state_at_end: <string | null>           # one-line user-language state, e.g. "softer, less loud"
  } | null,                                  # null when no focus part was ever selected (e.g. crisis exit before Phase 2, or trailhead-bail)
  trailhead_returned_to_open_threads: <bool>,
  transcript: [...],
  event_log: [...],
  pending_changes: [...]
}
```

Empty `event_log` is valid (Phase-1-only case, or crisis exit pre-Phase-1). `pending_changes` containing only `strike_trailhead` entries is valid. `phase1_state` defaults (`unknown` / `false` / `0` / `false`) are valid when Phase 1 didn't run. `focus_part: null` is valid when no Phase 2 focus was selected.

The subagent uses `focus_part` to populate session-note frontmatter (`parts_touched`, `new_parts`, `permission_granted`) and the `## Parts encountered` body section. It cross-references `pending_changes` for `create_part` / `update_last_seen` / `append_alias` entries on the focus part.

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
