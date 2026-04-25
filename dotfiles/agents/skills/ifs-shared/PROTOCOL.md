# PROTOCOL.md — eager-loaded EM+IFS playbook

Slice 3 of the build: full check-in (§0), Phase 1 (§1 — glimpse + texture + Self-like-parts gate, including the embodied-mini-loop on detected Self-like parts), Phase 8 closing ritual (§5f), and post-Phase-1 stub middle (§5stub) are live. Phases 2–7 procedural content (focus part, embodied engagement, drift handling, cycle detection, polarization work) lands in later slices.

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

## §5a — Self-like-parts spotting (terse pattern-match list)

Used by §1c to pick the most likely imitator. Full prose explanations live in `FAQ.md`. Mid-session pattern-match only:

1. **Calm/peaceful manager** — *performs* calm to manage the system. Tell: located somewhere (head, chest), feels held/maintained, has a "doing this right" flavor.
2. **Spiritual-bypass part** — uses spiritual framing to avoid felt experience. Tell: words like "everything is one", "no real self anyway", "this is just ego" appearing where felt sense was asked for.
3. **Intellectual overpass** — *"I understand it now"* insight that bypasses contact. Tell: clean explanatory frame appearing without bodily reference.
4. **Psychological underpass** — resignation/depression mimicking groundedness. Tell: flatness, "fine", "whatever", absence rather than presence.

Real Self texture: boundless, no locator, already-here, effortless, clear knowing without effort.

Suspect texture → Claude offers ONE observation as a question. Never asserts an imitator-verdict. See §1c for the exact routing.

On detected Self-like part: engage it as a part (locate → thank → ask space) and re-glimpse. If it won't make space, it becomes the focus part. **Phase 7 is blocked for this session regardless of tier.**

## §5stub — Post-Phase-1 stub middle (slice 3 only)

Phases 2–7 are not implemented yet. After Phase 1 routes here (clean OR Self-like-part-as-focus), emit one line:

> [Session middle skipped — Phases 2–7 land in later slices. Routing to closing ritual.]

Then route directly into the closing ritual.

If the Self-like-part-as-focus path ratified through §1d, the closing ritual still runs in full and the session note records `self_like_part_detected: true` plus, where slice 4+ would have a Phase-7-blocked flag visible, the slice-3 surfacing is the frontmatter field alone — no separate `phase_7_blocked` field is added in slice 3 (the `self_like_part_detected: true` flag is the de facto block signal until Phase 7 lands).

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

## Slice 4+ content (placeholder)

Full procedural content for the following lands in later slices:

- Phase 2 — focus part selection (post-glimpse, propose-and-ratify on divergence from trailhead).
- Phase 3 — full embodied engagement (locate → describe → thank → request space → feel Self-energy → "how do you feel toward that part?"). Includes dissociation cue at step 1 and the full "feel Self-energy in opened space" that the §1d mini-loop deliberately omits.
- Phase 4 — continuation check + hybrid drift handling (thank-and-ask-space → re-glimpse → re-target). Hard rule against recursing into full embodied engagement.
- Phase 5–6 — befriend / fears (Schwartz light-touch, retained).
- Phase 7 — optional deeper work (two-factor gate; see `SAFETY.md` tier matrix). Blocked for the session if `self_like_part_detected: true` from Phase 1.
- §5e — cycle detection (signals: same part blends at Phase 4 twice; three distinct re-targets in one session). Response: pause, name pattern, offer three paths in prose (polarization work / pick-one / close-and-log; default close-and-log).
- §5e — polarization work (Schwartz 7-step protocol, Kelly-retained; replaces remainder of session; requires clean re-glimpse first).
- Naming (descriptive phrases; deferred-naming fallback `Unnamed YYYY-MM-DD #N`).
- Aliases and renames (inline at alias-discovery time; backlink rewrites).
