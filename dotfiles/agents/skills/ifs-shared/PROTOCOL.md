# PROTOCOL.md — eager-loaded EM+IFS playbook

Slice 5 of the build: full check-in (§0), Phase 1 (§1 — glimpse + texture + Self-like-parts gate), Phase 2 (§2 — notice what's present + focus part selection), Phase 3 (§3 — full embodied engagement: locate → describe → thank → ask space → feel Self-energy → "how do you feel toward that part?"), naming (§3-naming), Phase 4 (§4 — continuation check + hybrid drift handling: thank-and-ask-space → re-glimpse → ratified re-target; pulse cadence; dissociation cue), Phase 8 closing ritual (§5f), and post-Phase-4 stub middle (§5stub) are live. Phases 5–7 procedural content (befriend, fears, deeper work, cycle detection, polarization work) lands in later slices.

For pre-flight + mood-gate, see `SAFETY.md`. For vault paths and schemas, see `OBSIDIAN.md`. For parts taxonomy, see `TAXONOMY.md`. For longer-form imitator explanations, see `FAQ.md`.

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
5. **Never recurse drift handling into full embodied engagement.** Thank-ask-space is one ~30s move; if it fails, re-glimpse; if that fails, ratified re-target. Recursion (running locate → describe → thank → ask-space → Self-energy → 8 C's on the *blending* part) is the single most common failure mode that produces directionless sessions. Hard rule.
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
- `FAQ.md` loaded only when user asks a conceptual question pattern-matching a topic, or when Claude needs to explain a concept it's about to invoke. The 4 imitators are the most common load trigger — when the texture-gate offers an imitator observation and the user asks "what's that?" or "what's the difference?", load `FAQ.md` and read back the relevant section in plain prose, not by reading the whole file aloud.

## §0 — Check-in (live)

Three-step micro-sequence:

1. **Mood (free text).** *"How are you arriving, in one line?"* — runs the mood-gate refusal in `SAFETY.md`. Crisis-pattern match emits the crisis-fallback link in one line and ends the session with `status: crisis_exit`. Otherwise `metadata.checkin_state` captures the answer.
2. **Tier (the only AskUserQuestion in the session).** Short / Medium / Long. Captured into `metadata.tier`.
3. **Trailhead (free text).** Combined offer of the most recent session note's unchecked `## Open threads` items + unstruck items from `Trailheads.md` (treat missing as empty). Presented in prose, not as a menu. User picks in their own words. If the pick maps to a `Trailheads.md` line, queue a `strike_trailhead` entry into `pending_changes`.

One-line echo (no hedging): *"OK — <tier>, picking up <short paraphrase>. Starting there."* Then route into Phase 1.

## §1 — Phase 1 — Shift into Self (live)

Self-first opener. The session's architectural foundation. Runs immediately after the check-in's one-line echo. Never narrated as "entering Phase 1."

### §1a — Glimpse delivery (point-at-the-door)

Read `default_glimpse:` from `IFS.md` frontmatter. Default if missing or empty: `"What is here when there is no problem to solve?"`.

Type the prompt in italics and wait. Mark a brief pause (one line, e.g. *"Take a moment with that."*) — do **not** walk it through stepwise, do not break it into sub-steps, do not narrate what should be happening. Claude is not a meditation teacher. The user signals arrival in their own words.

Shape:

> *"What is here when there is no problem to solve?"*
>
> Take a moment with that. Let me know what you notice.

Wait. Let the silence work. The user's next turn — anything from "ok" to a paragraph of texture — is the signal to proceed to §1b.

### §1b — Texture question (post-glimpse)

Once the user signals arrival, ask exactly one open felt-sense question:

> *"Where does it feel located, if anywhere — and does it feel already-here or achieved?"*

Verbatim. Do not soften, do not append, do not pre-explain what "located" means. Wait for the answer.

Real Self texture: boundless, no locator, already-here, effortless, clear knowing without effort. Self-like-part texture: located somewhere (head, chest, "around"), achieved/managed/held, "doing this right" flavor, performed.

### §1c — Self-like-parts spotting (gate, not checklist)

Listen to the texture answer and route on it. This is a **gate**, not a checklist — the user sees a single response, not an inventory of imitators.

**Clean texture** (no locator OR explicitly "already-here", "spacious", "everywhere", "nowhere in particular", "just here", "vast", "open", or similar — and no "I'm doing this", "trying to", "should be", "supposed to", "managing to" framing): proceed silently to §1d. Frontmatter: `self_texture: clean`, `self_like_part_detected: false`. Do not mention imitators. Do not ask follow-up texture questions. Do not pulse-check here — Phase 1 just landed.

**Suspect texture** (located somewhere AND/OR has "achieved/managed/doing-this-right" flavor AND/OR matches one of the 4 imitator patterns from §5a): offer ONE observation as a question (per doctrinal line 3 — reflection-only). Pattern-match the most likely imitator from §5a and name only that one:

> *"That sounds a bit like managed-calm — does it feel performed, or already-here?"*

or for spiritual-bypass:

> *"That sounds a bit like a part that goes to spaciousness — does it have a body location, or is it 'above' the body somehow?"*

or for intellectual-overpass:

> *"That sounds a bit like the part that explains it really well — is there a felt sense in the body, or is it more in the head?"*

or for psychological-underpass:

> *"That sounds a bit flat — is there energy here, or more of a 'nothing's really here' quality?"*

Pick **one**. Never list. Never assert ("this IS managed-calm"). Always offer as a question. If the user asks what you mean, lazy-load `FAQ.md` and read back the relevant section in plain prose.

The user's response routes:

- **User confirms** (yes / sounds right / probably / yeah I think so): treat as detected. Frontmatter: `self_texture: murky`, `self_like_part_detected: true`. Route to §1d-engage-self-like-part.
- **User denies** (no / it really does feel already-here / I think it's just X): trust the answer. Frontmatter: `self_texture: clean`, `self_like_part_detected: false`. Proceed to §1d-clean.
- **User isn't sure** (maybe / I don't know / it's hard to tell): re-glimpse once. Frontmatter: increment `re_glimpses`. Use the briefer form *"Let's notice again — what's here when there's no problem to solve?"* and re-ask the texture question. After the second pass, route as above (treating "still not sure" as a soft denial — proceed to §1d-clean, but flag in event_log via implicit narrative — `re_glimpses` count tells the story).

### §1d — Routing out of Phase 1

**§1d-clean** (clean texture, or denied imitator, or post-re-glimpse settled): Phase 1 is complete. Proceed to Phase 2.

In slice 3, Phase 2 is still stubbed — route into `§5stub` (post-Phase-1 stub middle).

**§1d-engage-self-like-part** (Self-like part detected, user confirmed): engage the Self-like part as a part using a **constrained mini-loop** of the Phase 3 protocol — locate / thank / ask space only. Do **not** run the full Phase 3 (no "feel Self-energy in opened space", no "how do you feel toward that part" — those land in slice 4 as full Phase 3).

Sequence:

1. **Locate.** *"Can you sense where in the body it lives — chest, head, throat, somewhere else?"* Wait.
2. **Thank.** *"Take a moment to thank it for what it's been doing — it sounds like it's been working hard to keep things steady."* Wait.
3. **Ask space.** *"Now, gently, ask if it would be willing to give a little space — not go away, just step back enough for something else to come through."* Wait.

Do not recurse. If the user starts deep-engaging it (befriending, asking its fears), redirect lightly: *"For now we're just asking it to make space — we can come back to it more fully if it ends up being where we land today."*

Then re-glimpse: type the (briefer) glimpse prompt and re-ask the texture question. Frontmatter: increment `re_glimpses`.

**Routing after re-glimpse:**

- **Texture now clean** → Phase 1 complete. `self_like_part_detected:` stays `true` (it was detected, even though it stepped back), but proceed to Phase 2 (slice 3: `§5stub`). The session's Phase 7 block flag is **not** raised — the part stepped back, exile contact remains permissible if other gates pass.
- **Texture still murky / part won't make space**: the Self-like part becomes the **focus part** for the session. Propose-and-ratify per doctrinal line 4:

  > *"It looks like this part is who's most present right now. Want to let it be the focus today, or close and come back to it?"*

  - **User ratifies "let it be the focus"** → set `focus_part_is_self_like` flag internally. Set the session's **Phase-7-blocked** internal flag (regardless of tier, per §5a). In slice 3, full Phase 3+ engagement is still stubbed — route into `§5stub` with the Self-like part recorded as the focus, and surface in the session note frontmatter as `self_like_part_detected: true`. Slice 4+ will run real Phase 3 on this focus.
  - **User ratifies "close"** → set `metadata.status = "interrupted"`, route to closing ritual.

In all paths, the texture answer and any imitator observation are recorded only in the frontmatter fields (`self_texture`, `self_like_part_detected`, `re_glimpses`) — never in the body. Phases never narrated.

## §2 — Phase 2 — Notice what's present + focus part selection (live)

Runs after Phase 1's `§1d-clean` route. Skipped when §1d ratified a Self-like part as focus (that path goes straight to Phase 3 with `is_self_like: true` already set). Single conversational beat, no narration.

### §2a — Open the field

Verbatim:

> *"What's here, or what's surfacing now?"*

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

## §3 — Phase 3 — Engage embodied (live)

Six steps, free-text after Step 1. Run unchanged from Loch Kelly's published protocol. Pulse-check at entry only if `re_glimpses > 0` from Phase 1, or any §1d engagement happened — otherwise the glimpse just landed and a pulse adds friction.

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

The move §1d explicitly skipped. Critical: this is where Self lands in the field with the part rather than around it.

> *"What's here in the space that opened?"*

Wait. Capture the user's verbatim answer (warmth, openness, curiosity, quiet, clarity — or the opposite, e.g. "still tight" — whatever shows up). Feeds `## What Self noticed` synthesis.

### §3-6 — How do you feel toward that part?

The 8 C's pulse + passive Self-like-parts pattern-match.

> *"From where you are now, how do you feel toward the part?"*

Wait. Listen for:

- **8 C's tone** (curious / compassionate / calm / connected / clear / confident / courageous / creative — or close synonyms): Self is in the chair. Note state in user's own words.
- **Self-like-parts pattern** (passive): if the answer is "I want to fix it / get rid of it / understand it / ignore it" or has the managed/performed/intellectual/flat quality, that's a part-toward-part response. In slice 4, log via `phase1_state` only if it shows up here (frontmatter signal); full re-glimpse handling is Phase 4 (slice 5+). For now offer ONE light reflection: *"That sounds like another part has come in. Want to ask it to give space too, or stay with what's here?"* Take user's pick at face value; no recursion.

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

Trust the user's answer (per PRD §33). If "same": `is_new = false`, working_title = existing title, queue `update_last_seen` (+ `append_alias` if surfaced phrase differs). If "new": `is_new = true`, queue `create_part`. If unsure, ask once; if user demurs, treat as new.

Pending-changes queued at end of naming step:

- `is_new = true` → `create_part { title, initial_frontmatter: { type: part, part_type: unknown, status: active, aliases: [], first_met: <date>, last_seen: <date>, age_felt: null, protects: [], polarized_with: [], allies: [], tags: [ifs, part] } }`
- `is_new = false` → `update_last_seen { part_ref: working_title, date: <date> }` (+ `append_alias { part_ref: working_title, new_phrase: surfaced_phrase }` if different)

`part_type` defaults to `unknown` — never set automatically by the skill in slice 4. User-supplied or Phase 5–6-elicited (later slices) sets it via `set_part_type`. Same with `record_protects` — type exists for future use; not actively populated in slice 4.

## §4 — Phase 4 — Continuation check + hybrid drift handling (live)

Runs after §3-naming completes. Two responsibilities:

1. **Continuation check** — verify Self is still in the chair before continuing.
2. **Drift handling** — if Self isn't, route through the hybrid escalation: thank-and-ask-space → re-glimpse → ratified re-target. Never recurse.

### §4-pulse — Pulse cadence

Two flavors of pulse, both used in slice 5:

- **Light pulse** (every phase transition): one line — *"Still here and oriented? Want to continue?"* Yes → continue. Anything else (no / "I'm done" / "actually I'm checking out a bit" / silence indicating exit) → branch to bail handling (closing ritual, `status: interrupted`).
- **Full continuation check** (three high-risk transitions: entering Phase 3, entering Phase 7, pre-close): light pulse + texture pulse + Self-like-parts spotting (per §5a). The texture pulse re-asks the §1b question briefly: *"And — what's it like for you right now? Located somewhere, or more open?"* Self-like-parts spotting is passive listening on the answer; only offers an imitator observation if the texture answer pattern-matches. Phase 7 is not built yet — flag for slice 7+.

Pulse-check entry into Phase 3 is **unconditional** in slice 5 (full continuation check), replacing slice 4's conditional version. The PRD §16 says full continuation check at three high-risk transitions; cycle detection isn't here yet but the entry pulse is now standard.

Log every pulse to `event_log` as `pulse_check { result: "continue" | "bail" | "drift_detected" }`.

### §4-detect — Drift detection signals

After Phase 3 (or any time mid-engagement past Phase 3), watch for:

- **Texture murky** at the §3-6 "how do you feel toward the part?" answer — fix-it / get-rid-of-it / understand-it / ignore-it framing, or any of the 4 imitator patterns (§5a).
- **8 C's absent** — no curiosity / compassion / calm / connection in the answer; the user describes a charged stance toward the part.
- **User reports blending** — *"I think it's taking over"*, *"I am the part right now"*, *"I can't find me"*, or similar self-report of identification with the part.
- **Pulse-check returns `drift_detected`** at a phase boundary — texture or Self-like-parts spotting flags murkiness.

If any signal trips, route into §4-handle. Otherwise continue (no narration; just keep going).

### §4-handle — Hybrid drift handling (three escalating moves, never recursive)

**Hard rule (doctrinal line 5)**: drift handling **never** runs a full embodied engagement on the blending part. No locate → describe → thank → ask space → Self-energy → 8 C's loop on the *blending* part. That recursion is the failure mode that produces directionless sessions where the part-doing-the-handling becomes the new focus and the original work disappears.

Three moves, in order. Each is one ~30-second beat. If a move succeeds (Self texture restored), continue with the original focus part. If it fails, escalate to the next move. After move 3, the session has either re-targeted or closed.

#### §4-handle-1 — Thank-and-ask-space (~30 seconds)

The blending part gets a brief acknowledgement and a request, in plain prose. Two micro-steps:

1. *"Take a moment to thank that part for showing up — it's been working hard."*
2. *"Now, gently, ask if it would be willing to give a little space — not go away, just step back enough for `<focus_part.working_title>` to come through again."*

Then attend to Self-energy in the opened space:

3. *"What's here in the space that opened?"*

Wait. Log `light_touch_step_back { success: true | false }` to `event_log` based on the answer. Increment `unblending_events` regardless of success (a drift was detected and a step-back was attempted — that's the count).

- **Success** (texture clean, space opened, user reports softening / room / stepping back): continue with the original focus part. Do not re-narrate where you are. Increment `unblending_events`.
- **Failure** (texture still murky, user can't sense space opening, the blending part stays loud): escalate to §4-handle-2.

This is **NOT** a full Phase 3. No "describe the part", no naming, no "how do you feel toward it" — those would be recursion. One thank, one ask-space, one Self-energy check. Done.

#### §4-handle-2 — Re-glimpse fallback

If thank-and-ask-space fails, run the glimpse prompt again. Briefer form is acceptable:

> *"Let's notice again — what's here when there's no problem to solve?"*

> Take a moment with that.

Wait. Then re-check texture briefly:

> *"What's it like for you now — located somewhere, or more open?"*

Log `pulse_check { result: "drift_detected" | "continue" }` based on the answer. Increment `re_glimpses` in `phase1_state` regardless.

- **Success** (texture clean now): continue with the original focus part.
- **Failure** (texture still murky / user reports the blending part is still in the way): escalate to §4-handle-3.

#### §4-handle-3 — Ratified re-target (propose-and-ratify, doctrinal line 4)

Both lighter moves failed. The blending part is the real focus right now. Propose-and-ratify a pivot. Plain prose, three options:

> *"This part isn't stepping back, and re-glimpse didn't restore Self contact. We can pivot the session to it, come back to `<focus_part.working_title>` next time, or close here. Which?"*

Wait. Trust the user's pick at face value:

- **User picks "pivot to it"**:
  - Log `re_target { from: <original focus working_title>, to: <new phrase / placeholder if unnamed> }` to `event_log`.
  - Increment `re_targets` in session-state.
  - Move the original focus to `## Open threads` of the new note (subagent appends — the skill flags it via the `re_targets` event log entries; the original `focus_part` stays in the input as the *first* part touched, but with `state_at_end = "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"` or similar plain phrasing).
  - The new target becomes the focus part. Run Phase 3 on it (locate → describe → thank → ask-space → Self-energy → "how do you feel toward that part?" → naming). The new focus accumulates as a *separate* `focus_part` entry — slice 5 tracks this as a `re_targeted_parts[]` list passed to the subagent (each entry has the same shape as `focus_part`, plus `re_targeted_from: <previous focus working_title>`).
  - **Re-targets stack linearly.** A → B → C → D is fine in slice 5 (cycle detection lands in slice 8 / issue #18). Each new re-target appends to `re_targeted_parts[]` with `re_targeted_from` pointing at the immediately-previous focus.
  - After Phase 3 completes on the new focus, run Phase 4 again (continuation check). If drift detected again, hybrid handling runs again on the *new* focus. Re-targets keep stacking.

- **User picks "come back to `<original>` next time"**:
  - Set `metadata.status = "interrupted"` (the user is choosing to close mid-work; this is a graceful bail, not a failure).
  - Route to closing ritual. The original focus already has `set_left_without_resolution` queued via bail handling.

- **User picks "close here"**:
  - Same as "come back next time" — `status: interrupted`, route to closing ritual.

If the user disengages without picking, default to "close here" — propose-and-ratify means the user gets to choose, but silence under the wrap clock is a pick.

### §4-stack — Re-target stacking semantics

When a re-target happens, both parts are recorded:

- The original `focus_part` stays in input with its original Phase-3 data and `state_at_end = "re-targeted away from at Phase 4 — wouldn't step back, re-glimpse didn't restore"` (or similar one-line phrasing in user/Claude prose).
- The new focus is appended to `re_targeted_parts[]` with full Phase-3 data of its own and `re_targeted_from: <original working_title>`.
- If a *second* re-target happens (B → C), the original B becomes the previous focus for C: C gets `re_targeted_from: <B working_title>`. B's `state_at_end` updates to mention the second re-target. Original A stays as-is.
- The *current* focus is always the last entry in `re_targeted_parts[]` (or `focus_part` itself if no re-target happened). Pulse-checks and drift detection target the current focus.

Subagent renders each part (original `focus_part` + every `re_targeted_parts[]` entry) as its own `### [[<working_title>]]` sub-section under `## Parts encountered`. Re-targeted parts get a body-line note: *"re-targeted from [[<previous working title>]] at Phase 4 — wouldn't step back, re-glimpse didn't restore."* Verbatim or close-paraphrase per the skill's `re_targeted_parts[<N>].re_target_note` field.

### §4-postphase — Post-Phase-4 routing

After Phase 4 completes (no drift detected, OR drift handled with current focus restored, OR drift handled with re-target → new Phase 3 → Phase 4 stable), Phases 5–7 are not implemented yet — route into §5stub (post-Phase-4 stub middle), then closing ritual.

Closing ritual targets the **current focus** (last entry in `re_targeted_parts[]` if any, else `focus_part`). The original focus and any intermediate re-targets are addressed in `## Parts encountered` body sections only — closing's permission-to-return question targets the most-engaged-most-recently part. If user wants to grant permission for multiple, they say so in plain prose; the skill defaults to current-focus-only for `permission_granted` frontmatter.

## §5a — Self-like-parts spotting (terse pattern-match list)

Used by §1c to pick the most likely imitator. Full prose explanations live in `FAQ.md`. Mid-session pattern-match only:

1. **Calm/peaceful manager** — *performs* calm to manage the system. Tell: located somewhere (head, chest), feels held/maintained, has a "doing this right" flavor.
2. **Spiritual-bypass part** — uses spiritual framing to avoid felt experience. Tell: words like "everything is one", "no real self anyway", "this is just ego" appearing where felt sense was asked for.
3. **Intellectual overpass** — *"I understand it now"* insight that bypasses contact. Tell: clean explanatory frame appearing without bodily reference.
4. **Psychological underpass** — resignation/depression mimicking groundedness. Tell: flatness, "fine", "whatever", absence rather than presence.

Real Self texture: boundless, no locator, already-here, effortless, clear knowing without effort.

Suspect texture → Claude offers ONE observation as a question. Never asserts an imitator-verdict. See §1c for the exact routing.

On detected Self-like part: engage it as a part (locate → thank → ask space) and re-glimpse. If it won't make space, it becomes the focus part. **Phase 7 is blocked for this session regardless of tier.**

## §5stub — Post-Phase-4 stub middle (slice 5 only)

Phases 5–7 are not implemented yet. After Phase 3 + naming + Phase 4 (continuation check + any drift handling) completes, emit one line:

> [Session middle continues here — Phases 5–7 land in later slices. Routing to closing ritual.]

Then route into the **pre-close full continuation check** (light pulse + texture pulse + Self-like-parts spotting per §4-pulse) — one of the three high-risk transitions. If that pulse passes, route to the closing ritual. If it returns `bail` or `drift_detected`, treat as a graceful bail (`status: interrupted`, ritual still runs).

The closing ritual targets the **current focus** — the last entry in `re_targeted_parts[]` if any, else `focus_part`. Permission-to-return question targets the current focus by working title.

If the Self-like-part-as-focus path ratified through §1d, the part is the focus; engaging it embodied is real work. Frontmatter: `self_like_part_detected: true`, `parts_touched: [[<working title>]]`. Phase 7 block is the de facto signal of `self_like_part_detected: true` (no separate `phase_7_blocked` field — that's the design until Phase 7 lands).

## §5f — Phase 8 — Closing ritual (live; mandatory unless `crisis_exit`)

Always runs on graceful close, graceful bail, AND ratified wrap. Never runs on imminent-harm exit. Wrap shortens the work, never the close.

Five steps, in order:

1. **Thank.** Each part contacted. (In stub-middle / no-parts-touched cases, plain language: *"Take a breath. Anything you want to thank — yourself, anyone you reached, anything that surfaced — go ahead."*) When a Self-like part was engaged in §1d, that counts as a part contacted — name it in plain prose: *"Including the part that came up at the start — it gave space (or didn't) — anything to thank it for?"*
2. **Ask more.** *"Anything else wants to be heard before we close?"*
3. **Permission to come back.** *"OK to come back to this another time?"* (Directed at parts contacted in real sessions; plain framing in stub-middle.)
4. **Rest in Self.** Type and wait:
   > Rest here for a moment. This is what's always available. Nothing to do.
   30–60 seconds. Don't fill the silence.
5. **Step out.** *"Re-orient: feet, chair, room. Notice what's here in your space."*

Order matters: rest-in-Self before step-out so re-orientation happens *from* Self, not as an exit. Sessions don't get logged as `complete` until the ritual runs.

## Slice 6+ content (placeholder)

Full procedural content for the following lands in later slices:

- Phase 5–6 — befriend / fears (Schwartz light-touch, retained). Likely surface for `set_part_type` queueing.
- Phase 7 — optional deeper work (two-factor gate; see `SAFETY.md` tier matrix). Blocked for the session if `self_like_part_detected: true` from Phase 1. Requires the entry-to-Phase-7 full continuation check (third high-risk transition). `record_protects` queueing lands here.
- §5e — cycle detection (signals: same part blends at Phase 4 twice; three distinct re-targets in one session). Response: pause, name pattern, offer three paths in prose (polarization work / pick-one / close-and-log; default close-and-log). Slice 5 lands linear stacking of re-targets without cycle detection — re-targets log freely, no cycle counter trips. Cycle detection is issue #18.
- §5e — polarization work (Schwartz 7-step protocol, Kelly-retained; replaces remainder of session; requires clean re-glimpse first).
- Renames and the `[[New|old phrase]]` backlink rewrites (inline at rename-discovery time, mid-session). Slice 4 wires `append_alias` for new phrasings of the same part; full rename lands later.
