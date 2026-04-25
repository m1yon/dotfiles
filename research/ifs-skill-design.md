# EM+IFS Skill — Design Decisions

Design notes for a Claude Code skill that supports Loch Kelly's
**Effortless Mindfulness + IFS** (EM+IFS) practice, with Obsidian as the
persistent store.

## Goal

A single slash command, `/em-ifs-session`, that walks the user through
EM+IFS sessions following Loch Kelly's synthesis: **shift into Self
first** via a glimpse practice, then engage parts from stable Self.
Parts and sessions persist as Obsidian pages navigated by `[[wikilinks]]`.

The architectural foundation is Kelly's inversion of the Schwartz
mechanism: Self is ever-present and inherent, not constructed by
unblending. Sessions open by shifting *into* Self (not by finding a
part), and parts work happens *from* that ground. Schwartz's parts-work
machinery (locate / thank / ask-space / 8 C's / exile contact /
unburdening / polarization) is retained — Kelly explicitly keeps it —
but it's framed throughout by the Self-first stance.

Doctrinal lines around Self, never voicing parts, and Self-like-parts
spotting (Kelly's distinctive guardrail) are non-negotiable.

Scope: personal tool for one user, not distributable.

---

## 1. Skill architecture

Single skill + a shared (non-skill) reference directory:

```
~/.claude/skills/
├── em-ifs-session/SKILL.md      → guided EM+IFS walkthrough (the only command)
└── ifs-shared/                  (not a skill; reference dir)
    ├── PROTOCOL.md              → procedural playbook: new spine, glimpse mechanics,
                                    embodied engagement, drift handling (hybrid),
                                    Self-like-parts spotting as procedure,
                                    cycle detection, polarization work, closing
    ├── FAQ.md                   → explanatory user-facing concepts: "no problem to
                                    solve," Self-like parts (4 imitators),
                                    11 i's of Self Essence, EM vs. Schwartz,
                                    glimpse practice rationale
    ├── TAXONOMY.md              → manager / firefighter / exile definitions
    ├── OBSIDIAN.md              → file paths, schemas, templates
    └── SAFETY.md                → crisis handling, scope limits, tier gating
```

`PROTOCOL.md` is eager-loaded every session — it's the AI's playbook.
`FAQ.md` is lazy-loaded only when the user asks a conceptual question
that pattern-matches a topic, or when Claude needs to explain a concept
it's about to invoke. The 4 imitators appear in *both* docs with
different framings: PROTOCOL.md gets a terse pattern-match list (Claude
needs this to spot them mid-session); FAQ.md gets longer prose for
user-facing questions like *"wait, what's the 'intellectual overpass'?"*

Rationale for skill consolidation: structured session work is the only
mode where Self-contact is reliable. Quick-journal and browse commands
were considered and cut — they risk substituting cataloging for actual
Self-led part engagement.

---

## 2. Obsidian location & folder structure

Inside `6 - Full Notes/IFS/`, fairly flat, wiki-navigated (not
file-tree-navigated).

```
6 - Full Notes/IFS/
├── IFS.md                    ← homepage (Dataview dashboard + crisis_fallback +
                                default_glimpse pointers)
├── Crisis Plan.md            ← user-authored fallback protocol; required to exist
├── Trailheads.md             ← flat dated scratch list
├── Parts/                    ← flat, all parts here
└── Sessions/                 ← flat, dated session notes
```

Two folders deep is the only nesting. Part type lives in frontmatter, not
folder structure (reclassification is common).

---

## 3. Claude's role during sessions

Pure coach. Hard refusal to role-play parts, even on user override mid-session.

- Claude only ever speaks to the user.
- Claude never voices a part, never says "Hi X, what do you need?", never
  simulates dialogue.
- The therapeutic mechanism is *Self contacting part from stable Self*.
  Claude voicing parts short-circuits that contact.
- Mid-session "just this once" requests to role-play are themselves often a
  part trying to avoid Self-contact. Skill explains and offers EM+IFS
  alternative ("I won't voice the part, but I can ask you what you hear
  when you ask it directly from Self").
- Hard refusal also keeps Claude safe when heavy material surfaces — no
  character to break.

**Self-inquiry questions are not voicing parts.** Claude *does* prompt the
glimpse practice (e.g., *"What is here when there is no problem to solve?"*)
and ask Self-directed inquiry questions (*"Where does it feel located, if
anywhere?"*). These are inquiries asked *of* the user's Self / awareness,
not parts being role-played. The line is: Claude can prompt Self-inquiry,
but never speaks *as* a part.

**Glimpse delivery is point-at-the-door, not stepwise walkthrough.** Claude
types the glimpse prompt, marks a brief pause, and waits for the user to
signal arrival. Claude is not a meditation teacher walking the user through
turn-by-turn — that would be Claude voicing the practice, the same family
of error as voicing parts.

Claude also never names or classifies parts on the user's behalf. It reflects
the user's own words back as candidate framings, never synthesizes
("sounds like a perfectionist part"). Surfacing a known part by name is only
valid after the user describes something concrete, and even then as a
question, not an assertion. The same rule applies to Self-like-parts
spotting: Claude offers a single observation when texture sounds suspect
(*"that sounds a bit like managed-calm — does it feel performed or
already-here?"*) but never asserts an imitator-verdict.

This guardrail must be explicit in the skill prompt; without it, the
behavior will erode.

### 3a. Propose-and-ratify

Claude proposes protocol branches; the user ratifies them. The AI never
silently changes scope. Focus-part pivots, re-targets, cycle responses,
wrap proposals, and session close all require explicit user confirmation.
The AI's role is to observe and offer, not to decide.

This is the same family as "never names parts on the user's behalf" — both
exist to prevent the AI from acting as the locus of agency in the system.
The user's Self is the locus; the AI surfaces options.

The single exception is the imminent-harm pattern match (§4d), which
breaks protocol unilaterally.

---

## 4. Safety

### 4a. Crisis fallback pointer (mandatory)

`IFS.md` frontmatter must contain `crisis_fallback: [[Crisis Plan]]`. If the
pointer or the target page is missing, `/em-ifs-session` **refuses to run at
all** and makes the user write `Crisis Plan.md` first.

The Crisis Plan is a user-authored concrete self-regulation protocol —
ideally 2–3 pre-committed items (*"text [person], 20-min walk, no screens
until morning"*). Not a hotline, not a therapist. Written in a non-crisis
moment.

### 4b. Check-in shape and refusal criteria

`/em-ifs-session` opens with a 60–90 second check-in structured as a 3-step
micro-sequence:

1. **Mood** (free text). *"How are you arriving, in one line?"* Safety
   gate runs on this answer.
2. **Tier** (AskUserQuestion — the only AskUserQuestion in the entire
   session). *Short / Medium / Long.* See §4f for ranges and wrap
   behavior.
3. **Trailhead** (free text). Combined offer of last session's `## Open
   threads` plus unstruck items from `Trailheads.md`, presented in prose.
   User picks in their own words.

Then a one-line echo: *"OK — medium, picking up the tight-jaw thread.
Starting there."* No "does that work?" hedging.

The trailhead names the user's *intent* for the session, not the focus
part — the focus is selected post-glimpse from what surfaces in stable
Self (§5b). The check-in flows directly into Phase 1 (Shift into Self).

Order rationale: mood first because safety refusal has to gate the rest.
Tier before trailhead because tier gates depth (§4f) — if it's short, the
AI knows deeper exile work is off-limits and can flag heavy-looking
trailheads as better-saved-for-a-longer-session.

**Refusal criteria** (run on step 1 only):

- Active suicidal ideation (plan/means/timeline)
- Acute crisis within the last 24h (assault, loss, medical)
- Intoxication or substances on board

Does **not** refuse on high distress alone (high distress is exactly when
EM+IFS helps). On refusal the skill names the crisis fallback in one line
and closes — before tier is ever asked. No therapist-voice boilerplate.

If the user reports "no Self-energy at all," the skill still attempts the
Phase 1 glimpse — Kelly's claim is Self is always available even when it
feels inaccessible. If the glimpse doesn't land (texture stays murky after
two attempts; Self-like-part detected and won't make space), the skill
pivots to observational parts-mapping (no Phase 3 contact) rather than
forcing engagement.

**Why AskUserQuestion only at tier:** the modality lives in the user's
own language — naming, descriptions, the texture pulse, Self-like-parts
spotting. A menu at any in-session decision point would shape the answer
before the user has felt into it. Tier is the one exception because it's
a contractual commitment made in planner-mode *before* session work begins.

### 4c. Mid-session pulse cadence

Hybrid cadence:

- **Light pulse at every phase-transition** — *"Still here and oriented?
  Want to continue?"* Yes → continue. Anything else → branch to closing
  ritual. Catches dissociation; cheap; preserves the "don't over-scan"
  doctrine.
- **Full continuation check** at three high-risk transitions: entering
  Phase 3 (engagement), entering Phase 7 (deeper work), pre-close. Full
  check = light pulse + texture pulse + Self-like-parts spotting (per
  §5a). Catches drift into a Self-like part, not just dissociation.
- **Dissociation cue at Phase 3** (locate-in-body): *"Check: can you
  still feel the chair / your feet / the room?"* A bail at that cue is
  treated as a hard "close now, no deeper contact."

Pattern-matching on crisis language mid-session is otherwise passive —
EM+IFS assumes stable Self gives the user enough access to notice.
Over-scanning is fragile and infantilizing.

### 4d. Imminent-harm pattern match

The one exception to passive safety: if user text looks like an acute
emergency signal (explicit imminent-harm statement), the skill breaks
protocol immediately with: *"Going to the crisis plan. [[Crisis Plan]]."*
No pulse-check, no ritual, session ends.

### 4e. Bailed sessions

Any bail runs the closing ritual (thank + permission + rest-in-Self +
step-out), logs session as `status: interrupted` with `self_texture`
reflecting state at bail, and flags every part touched with
`left_without_resolution: true` in its frontmatter.

### 4f. Session tier and time budget

User picks a tier at check-in (§4b step 2). The tier is a soft wall-clock
budget *and* one of two depth gates (the other is Self-stability — see
below).

| Tier   | Range       | Depth                                           |
| ------ | ----------- | ----------------------------------------------- |
| Short  | ~15–25 min  | Phase 7 (exile contact / unburdening) blocked entirely |
| Medium | ~30–45 min  | Phase 7 only with explicit user request + protector permission + clean Self texture |
| Long   | ~60–90 min  | Phase 7 per existing protocol (protector permission + clean Self texture required) |

**Two-factor gate for Phase 7 (Kelly modification):** deeper work requires
*all* of:

1. Tier permits (medium with explicit request, or long).
2. Protector permission (existing requirement).
3. Phase 1 produced clean Self texture (no Self-like-part detected at the
   gate).
4. No Self-like-part detected in current continuation check.

Reason: Kelly's "stabilized Self bears the unbearable" claim cuts both
ways. Stable Self genuinely can hold more, *but* a Self-like-part doing
exile work is exactly the failure mode his Self-like-parts spotting
exists to prevent. Either factor failing blocks Phase 7 — even on a long
session with protector permission, murky texture is a stop.

Tier-gates-depth rationale: unburdening work cut off at the upper bound
is worse than not starting — exiles left partially unburdened is a real
IFS concern. Tier is a commitment to how deep you're willing to go today,
not just how long. Don't loosen tier ceilings on Kelly's framing alone;
the wall-clock concern is independent of Self-stability.

**Wrap behavior:**

1. AI silently tracks wall-clock against the tier upper bound.
2. **Soft wrap** — ~5 min before upper bound, AI proposes once: *"We're
   near your time — want to close, or keep going?"* User ratifies close →
   skip any unworked phases, route to closing ritual. User says keep
   going → AI does not re-propose for ~10 min.
3. **Firm wrap** — at the upper bound, AI proposes again, firmer: *"We're
   at your limit — heading to close."*
4. Wrap never cuts mid-phase. If wrap is ratified mid-engagement, finish
   that phase's contact, then closing ritual.
5. The closing ritual *always* runs (per §5f).

**Extension is ad-hoc, not pre-declared.** No "how much extra do you want
budgeted?" up front. If short ends up wanting to be longer, that
conversation happens at the wrap proposal.

**Crisis-pattern override:** imminent-harm pattern match (§4d) ignores
wrap state and closes immediately.

---

## 5. Session protocol — the EM+IFS spine

Schwartz's 6 F's framing is dropped entirely. Kelly's mechanism (Self
first, then engage parts from Self) doesn't fit Schwartz's spine — F4 is
structurally the moment Self arrives in Schwartz, but in Kelly Self
arrives at the new Phase 1, hollowing the 6 F's out. Forcing the
old framing creates documentation confusion (every F means something
different from any IFS book the user might also read).

The new spine:

```
0. Check-in              (mood / tier / trailhead — §4b)
1. Shift into Self       (glimpse + texture check + Self-like-parts spot — §5a)
2. Notice what's present (parts arise from Self; pick the focus part — §5b)
3. Engage embodied       (locate → describe → thank → request space →
                          feel Self-energy in opened space → texture pulse)
4. Continuation check    (drift detection; hybrid drift handling — §5d)
5. Befriend              (relationship-building — Schwartz F5 carries over)
6. Fears                 (what it protects — Schwartz F6 carries over)
7. Optional deeper       (exile contact / unburdening — two-factor gated, §4f)
8. Close                 (thank → ask-more → permission → rest-in-Self →
                          step-out — §5f)
9. Log to Obsidian       (session note + part page updates — §9)
```

Phases are tracked internally but never narrated to the user out loud
(no "moving to Phase 4 now"). Flow is implicit. The user's complaint
that drove this design was sessions feeling endless and stopping
arbitrarily — addressed not by surfacing the phase scaffold to the user,
but by tier budgeting (§4f), cycle detection (§5e), focus-part
discipline (§5b), and propose-and-ratify (§3a).

### 5a. Phase 1 — Shift into Self

After check-in, the session opens with a glimpse practice that shifts the
user into Self *before* any parts are engaged. This is the architectural
foundation of EM+IFS.

**Glimpse prompt.** Single canonical opener:

> *"What is here when there is no problem to solve?"*

Kelly's signature Self-inquiry. Configurable in `IFS.md` frontmatter as
`default_glimpse:` if the user wants a different prompt later, but a fixed
prompt is the default — menu-shaping at session-start would be the same
anti-pattern §4b warns against.

**Claude types the prompt and waits.** Brief pause-marker, then Claude
waits for the user to signal arrival. Claude is not a meditation teacher
walking through it stepwise (per §3).

**Texture question (post-glimpse).** Once the user signals arrival, Claude
asks one open felt-sense texture question:

> *"Where does it feel located, if anywhere — and does it feel
> already-here or achieved?"*

Real Self texture: boundless, no locator, already-here, effortless, clear
knowing without effort. Self-like-part texture: located somewhere (head,
chest), achieved/managed, held, "doing this right" flavor.

**Self-like-parts spotting (gate, not checklist).** Clean texture answer
→ proceed to Phase 2, no mention of imitators. Suspect texture answer →
Claude names *one* most-likely imitator as a single offered observation
(per §3 reflection-only stance):

> *"That sounds a bit like managed-calm — does it feel performed, or
> already-here?"*

The 4 imitators (terse pattern-match list lives in `PROTOCOL.md`; longer
explanations in `FAQ.md`):

1. **Calm/peaceful manager** — performs calm to manage the system.
2. **Spiritual-bypass part** — uses spiritual framing to avoid felt
   experience.
3. **Intellectual overpass** — "I understand it now" insight that
   bypasses contact.
4. **Psychological underpass** — resignation/depression mimicking
   groundedness.

These correspond 1:1 to Kelly's "spiritual bypass / psychological
underpass / intellectual overpass" warnings — fully absorbed into
Self-like-parts spotting; no separate guard.

**On detected Self-like part: engage it as a part.** Doctrinally Kelly
— the Self-like part *is* a part. Run the standard embodied protocol on
it (locate → thank → ask space) and re-glimpse. If it won't make space,
it becomes the focus part for the session (re-target, ratified per §3a).
Phase 7 is blocked for this session regardless of tier.

### 5b. Phase 2 — Focus part selection

Kelly's framework engages whatever surfaces from stable Self, but session
economy still benefits from one part being worked in depth vs. several
touched superficially. The "anchor" concept (renamed **focus part**)
survives as a discipline against directionless sessions.

**Selection rule.** Trailhead names the *intent* (set at check-in,
planner-mode); what surfaces from stable Self post-glimpse names the
*focus*. Usually they align. When they diverge, Claude proposes the
divergence (*"You came in with X, but Y surfaced more strongly — which?"*)
and ratifies per §3a. The Self-led choice is usually whatever surfaced;
the trailhead returns to `## Open threads` or `Trailheads.md`.

**One focus part per session.** Other parts that surface *outside* the
drift handling check at Phase 4 get acknowledged with Self-energy ("I
hear you, I'll come back") and logged to the session's `## Open threads`
or to `Trailheads.md` — not pivoted to. The AI never silently re-anchors
(per §3a).

### 5c. Phase 3 — Embodied engagement

Kelly's signature parts-engagement protocol. Unchanged from his published
materials:

1. **Locate in body.** Shape, size, color, emotional tone.
2. **Describe.** What the part feels like, looks like, sounds like.
3. **Thank.** Honor what it's been doing.
4. **Request space.** Ask the part if it would give some space.
5. **Feel Self-energy in the opened space.** Not "is Self present?" —
   *what fills the space the part just opened?* The texture pulse here
   is light: *"What's here in the space that opened?"*
6. **"How do you feel toward that part?"** Schwartz's classic — Kelly
   keeps it. 8 C's pulse plus passive Self-like-parts pattern-match.

The Phase 3 dissociation cue from §4c runs at step 1 (locate-in-body).

### 5d. Phase 4 — Continuation check and hybrid drift handling

Continuation check is the new role for what was the Schwartz F4 self-check.
Self arrived at Phase 1 — Phase 4 verifies Self is *still here*, hasn't
been blended over.

**On drift detected (texture murky, 8 C's not present, or user reports
something blended in):**

1. **First move: thank the blending part and ask for space.** Schwartz
   light-touch, retained by Kelly. After space opens, attend to
   Self-energy filling the opened space (Kelly's emphasis): *"What's
   here in the space that opened?"* This is the same mechanic as
   Phase 3 step 4–5, applied to the blending part.
2. **Fallback: re-glimpse.** If the part won't make space, run the
   glimpse prompt again (briefer form acceptable: *"Notice what's here
   when there's no problem to solve."*) and re-check texture. This is
   Kelly's distinct contribution — when negotiation isn't landing, the
   direct Self-shift is the supplemental tool.
3. **Re-target (escalation).** If neither restores Self texture, the
   blended part becomes the new focus, ratified per §3a:

   > *"This part isn't stepping back, and re-glimpse didn't restore
   > Self contact. We can pivot the session to it, come back to
   > [original focus] next time, or close here. Which?"*

   If the user pivots, the new target *is* the focus for the rest of
   the session; the original is logged as an open thread. Never a
   silent drift.

The single most consequential warning in the whole skill: do **not** run
the full embodied engagement (locate → describe → thank → ask-space →
feel-Self-energy as a multi-turn sequence) on the blending part as part
of drift handling. The drift handling thank-ask-space is one move,
~30 seconds; if it doesn't work, re-glimpse, then re-target. Never
recurse — recursion is the failure mode that produces endless,
directionless sessions.

**Re-targeting can stack.** Depth isn't the failure mode — *cycles* are
(see §5e). A → B → C → D linear descent through new parts is fine.
A → B → A is a cycle and gets caught.

### 5e. Cycle detection and polarization work

Cycles aren't a bug in the protocol — they're diagnostic. A session that
keeps returning to the same parts is telling you something specific:
polarization (two parts in active conflict), protector pile-up (multiple
managers guarding the same exile), or system-wide activation that won't
let any one part land. The AI's job is to *surface that observation*,
never to silently ride the loop.

**Cycle signals.** Either trips cycle handling:

1. **Repeat blend** — the same part blends at Phase 4 twice in one
   session (whether the first blend was thank-and-ask resolved,
   re-glimpsed, or re-targeted). Signal: this part isn't ready to step
   back today.
2. **Re-target pile-up** — three distinct re-targets in one session,
   even without return. Signal: system is too activated to land
   anywhere today.

**Cycle response.** When a signal trips, the AI pauses the protocol,
names the pattern in one line, and offers three paths in prose (no
AskUserQuestion):

- **(i) Polarization work** — see protocol below. Replaces the rest of
  the session. Requires a clean re-glimpse to verify Self stability
  before entering.
- **(ii) Pick one and commit** — *"If you had to work with just one
  today, which?"* User commits to one part as the focus for the
  remaining session; others are logged as open threads.
- **(iii) Close and log** — name the cycle in the session note, mirror a
  `polarized_with:` link on each involved part page (per §8 sub-decisions),
  close.

**Default is (iii)** if the user disengages or can't decide. A
dysregulated system trying to do polarization work is just more cycling;
(i) only works *from* Self, which is exactly what cycling threatens.
(iii) is the safest default; the cycle observation persists across sessions
via the mirrored `polarized_with:` field, which surfaces in the next
session's Phase 0/1 load.

**Polarization work protocol** (option i — Schwartz-orthodox move Kelly
retains):

1. **Re-glimpse to verify Self.** Cycle response only enters polarization
   work from clean Self texture. Murky texture → close (option iii).
2. **Name the polarization.** *"These two seem tied up with each other —
   does that feel right?"*
3. **Invite both to make space simultaneously.** Not step back fully —
   just enough that Self can see both at once. Externalize: *"can you
   see them both in front of you?"*
4. **Self curious toward both, equally.** *"What does each of them
   need?"* Asked of the user, never role-played by Claude.
5. **Surface what each protects.** Polarized pairs are usually two
   protectors guarding different facets of the same vulnerability.
   Naming the shared exile below makes the fight make sense.
6. **Ask for cooperation, not merger.** *"Would you both be willing to
   let me lead for a bit, without either of you taking over?"* Not
   "settle your differences."
7. **Log.** Polarization pair recorded; what each protects; whether
   cooperation was agreed.

It is explicitly *not*: running the full embodied engagement on each
part individually, trying to resolve the polarization in one session, or
making either part relinquish its role. Resolution is multi-session work.

**Scope:** polarization work *replaces* the remainder of the session.
After step 7, route directly to the closing ritual (§5f). Continuing
befriend/fears on either polarized part after naming would re-trigger
the cycle.

### 5f. Phase 8 — Closing ritual (mandatory unless explicitly bailed)

Kelly modification: rest-in-Self is added before step-out. Self isn't a
session-state to leave behind — it's the home you live from. But
step-out remains as the dissociation guard.

1. **Thank** each part contacted.
2. **Ask if they have anything more to share.**
3. **Ask permission to come back later.**
4. **Rest in Self.** *"Rest here for a moment. This is what's always
   available. Nothing to do."* Brief — 30–60 seconds.
5. **Step out.** Re-orient to body, room, present.

Order matters: rest-in-Self first so the re-orientation happens *from*
Self, not as an exit. Dropping step 4 loses Kelly's doctrinal point that
Self isn't visited; dropping step 5 loses the dissociation guard.

Sessions don't get logged as `complete` until the ritual runs.

When wrap (§4f) skips remaining unworked phases, the closing ritual still
runs in full — wrap shortens the work, never the close.

---

## 6. State persistence

Lazy, three-tier load at the start of `/em-ifs-session`.

**Tier 1 (eager, always):**

- `IFS.md` frontmatter (for `crisis_fallback` + `default_glimpse` +
  homepage pointers).
- Most recent session note's frontmatter and `## Open threads` section
  only (not the full body).
- `Trailheads.md` full contents.
- `PROTOCOL.md` (the AI's playbook).
- No part pages, no FAQ.

**Tier 2 (on-demand, after trailhead phase):**

- Part pages read only when named in conversation, or when the user
  confirms a new description matches an existing part.
- Never preload the full active roster.

**Tier 3 (on-demand, mid-session):**

- `FAQ.md` loaded only when the user asks a conceptual question that
  pattern-matches a topic, or when Claude needs to explain a concept it's
  about to invoke.

Rationale: EM+IFS meets what's present, not what a dossier predicts. The
"last session you flagged X" prompt is the one concession to continuity, and
it's opt-in. The FAQ is reference material the user reads between sessions
(internalizing the 11 i's, the imitators, the EM/Schwartz distinction);
mid-session it loads only on demand.

---

## 7. Naming

Page titles are **descriptive phrases** tied to thought/feeling/behavior —
not proper names. Examples:

- `wants me to double-check everything.md`
- `the tight jaw when someone criticizes me.md`
- `Unnamed 2026-04-23 #1.md` (deferred naming)

### 7a. Candidate generation

Collaborative, reflection-only. Claude plays back the user's own language as
a candidate title ("You just said 'wants me to double-check everything' —
use that?"). Claude never synthesizes or projects.

At the end of Phase 3 (after embodied engagement, before continuation
check) the skill asks: *"If this part introduced itself, what would it
call itself?"* If the user stalls, the skill offers the deferred-naming
fallback: file as `Unnamed YYYY-MM-DD #N` and name later.

### 7b. Aliases

One part, multiple expressions. The same underlying part surfaces in
different contexts with different phrases. Rather than one page per phrase:

- Page title = the **first** phrase the part surfaced as.
- Frontmatter `aliases:` accumulates alternate phrasings over time.
- When a new phrase surfaces the skill asks once: *"Same as X, or new?"* —
  and trusts the answer.

### 7c. Renames

The canonical name is expected to evolve as understanding deepens. Rename
check happens **inline at alias-discovery time**, not batched:

1. New phrase surfaces, user confirms "same part."
2. Skill adds phrase to `aliases`.
3. Skill asks: *"Does `[current name]` still fit, or want to rework it?"*
4. If rework: collaborative reflection-based rename.

On rename:

1. File renamed.
2. Old canonical name appended to `aliases`.
3. Session-note backlinks rewritten as `[[New|old phrase as it appeared then]]`
   — preserves historical phrasing while keeping links live.
4. Other part-page backlinks rewritten to plain `[[New]]` — those reference
   the part in the abstract, not tied to a moment.

The alias list becomes a therapeutic artifact over time — a record of how
the relationship to the part evolved.

---

## 8. Part page schema

Frontmatter for queryable facets, body sections for prose.

```markdown
---
type: part
part_type: manager        # manager | firefighter | exile | unknown
status: active            # active | unburdened | dormant
aliases:                  # alternate phrasings as the part surfaces over time
  - won't let me stop once I start
  - catches every mistake before it happens
first_met: 2026-04-23
last_seen: 2026-04-23
age_felt: ~7
protects: [[the small one at the window]]
polarized_with: [[the one that wants everything perfect]]
allies: [[the one that plans ahead]]
tags: [ifs, part]
---

# wants me to double-check everything

## Role
What this part does for the system.

## How it appears
Body location, visual image, voice quality, posture.

## Fears
What it fears would happen if it stopped doing its job.

## Burdens
Extreme beliefs / feelings carried that aren't intrinsic to the part.

## Origin story
When/why this part took on its role.

## What it needs from Self
What this part has asked for, or what would help it relax.
```

Sub-decisions:

- **No `8Cs_present` field on parts.** Self-energy is a session-level
  observation, not a part property.
- **No Self-texture field on parts either.** Texture is session-level
  (parallels 8 C's reasoning). Texture lives on session notes only.
- **Polarizations mirrored on both parts** — the skill writes both sides.
- **Recent encounters surfaced via Obsidian backlinks**, not a maintained
  section. Every session note that wikilinks a part shows up on that part's
  page automatically.
- **`status: unburdened`** is a real, recorded event.
- **`age_felt`** = how old the part feels, not user's age when it formed.
- **`left_without_resolution: true`** is added by bailed sessions (§4e) and
  cleared when the part is next revisited.

---

## 9. Session note schema

Append-only historical record. Frontmatter for queryable events, prose body
for narrative.

```markdown
---
type: session
date: 2026-04-23
tier: medium                     # short | medium | long (§4f)
duration_min: 35
status: complete                 # complete | interrupted
checkin_state: tight chest, mild dread
self_texture: clean              # clean | murky (Phase 1 verdict)
self_like_part_detected: false   # true if any imitator detected at any check
re_glimpses: 0                   # count of mid-session re-glimpses
parts_touched: [[wants me to double-check everything]], [[the tight jaw]]
new_parts: [[the tight jaw]]
unblending_events: 1             # count of thank-and-ask-space drift fixes
re_targets: 0                    # count of ratified re-targets (§5d)
cycle_detected: false            # true if §5e signal tripped
polarization_work: false         # true if cycle response (i) was chosen
polarization_pair:               # populated if polarization_work or close-with-cycle
  []
permission_granted: [[wants me to double-check everything]]
exile_contact: false
unburdening: false
previous_session: [[2026-04-19 — ...]]
tags: [ifs, session]
---

# 2026-04-23 — first contact with the double-checking part

## Trailhead
What brought you to this session.

## Arc
Brief prose narrative — the inner movement, not a transcript.

## Parts encountered
### [[wants me to double-check everything]]
- How it appeared this session
- What it shared
- State at end

### [[the tight jaw]]  (blended in at Phase 4)
- Surfaced as drift event
- What it needed
- Stepped back: yes

## What Self noticed
System-level observations. Polarizations sensed, allies noticed.
Self-stability commentary if notable.

## Closing
- Parts thanked: yes
- Permission to return: granted by double-checking part; tight-jaw deferred
- Rest-in-Self: yes
- Re-orientation: yes

## Open threads
- [ ] Double-checking part mentioned an "earlier one" — possible exile, return next session
- [ ] Double-checking and tight-jaw may be polarized — explore
```

Sub-decisions:

- **Self-texture and re-glimpse counts in frontmatter, not narrated**
  in the body. The body's *## What Self noticed* can prose-comment on
  Self-stability if it was notable.
- **Drift events (thank-and-ask-space) counted, not narrated.**
  `unblending_events` is a count in frontmatter. The body section under
  each part records *how it appeared this session* — including drift
  events as part of that — but doesn't separately enumerate them.
- **Re-targets logged as their own parts encountered.** When a re-target
  happens, the new target gets its own `### [[part name]]` section in
  `## Parts encountered`, with a note like *"re-targeted from
  [[original focus]] at Phase 4 — wouldn't step back, re-glimpse didn't
  restore."* Preserves the narrative.
- **Cycle detection events go in `## What Self noticed`.** Prose:
  *"[A] and [B] cycled twice — likely polarized."* Plus
  `cycle_detected: true` and `polarization_pair: [[A]], [[B]]` in
  frontmatter, plus mirrored `polarized_with:` on each part page.
- **`previous_session` link** in frontmatter — chronology navigable as a
  wiki chain.
- **No retroactive editing of session notes.** New understanding goes on the
  *part* page or in the *next* session's `## What Self noticed`. Editing
  past sessions corrupts the record of how understanding actually developed.
- **`## Open threads` as Obsidian task checkboxes** — `/em-ifs-session`
  reads the most recent session's Open threads at start: "Last session
  you flagged X — pick that up?"

---

## 10. Trailheads.md

Flat, dated, append-only scratch list of unworked entry points. Written by
the user manually in Obsidian between sessions; read by `/em-ifs-session` at
the trailhead step of check-in.

```markdown
# Trailheads

Unworked entry points — things noticed that haven't been brought to a session yet.

- 2026-04-24: tightens when partner mentions money
- 2026-04-25: rehearsed an argument with no one in the shower
- ~~2026-04-20: keep noticing the "should have" voice~~ → [[2026-04-26 session]]
```

Rules:

- Flat, not categorized. No protector/exile grouping — you don't know yet,
  that's the point of a trailhead.
- Date-prefixed, bullet-per-line. Phone-editable.
- No frontmatter, no schema.
- When worked in a session, the skill strikes through the line and appends
  `→ [[session note]]`. Never deleted.
- Items sit indefinitely. No expiration, no stale pruning. User can manually
  strike without a session link if no longer live.

At the trailhead step, `/em-ifs-session` surfaces both sources together:

1. Unchecked items from the most recent session's `## Open threads`.
2. Unstruck items from `Trailheads.md`.

Offered as one combined list. Worked items get their mark on their
respective surface.

---

## 11. IFS.md homepage

Minimal Dataview dashboard for human reading only (no slash command consumes
it).

````markdown
---
type: ifs_home
crisis_fallback: [[Crisis Plan]]
default_glimpse: "What is here when there is no problem to solve?"
---

# IFS

## Active parts
```dataview
table part_type as "type", last_seen
from "6 - Full Notes/IFS/Parts"
where status = "active"
sort last_seen desc
```

## Relationships
```dataview
table protects, polarized_with, allies
from "6 - Full Notes/IFS/Parts"
where status = "active" and (protects or polarized_with or allies)
```

## Unburdened
```dataview
list from "6 - Full Notes/IFS/Parts" where status = "unburdened"
```
````

Deliberately excluded:

- **No recent-sessions list** — Obsidian's file explorer sorted by date
  handles it; putting it on the homepage adds re-reading pressure that primes
  the next session.
- **No "parts not seen in N days" query** — chasing dormant parts via
  dashboard is manager behavior. If a part wants contact, it will surface.
- **No aggregated open-threads view** — threads carry forward through the
  most recent session's `## Open threads`. Aggregating creates
  completion-anxiety.
- **No Self-texture/glimpse-history dashboard.** Texture is a session-level
  observation, not a metric to optimize. Surfacing it as a dashboard would
  invite gaming the texture answer.

The kept sections serve the stated goal: sort which parts are which and see
how they relate. Nothing more.
