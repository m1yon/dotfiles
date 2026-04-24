# IFS Skill — Design Decisions

Design notes for a Claude Code skill that supports strict-IFS
(Schwartz-orthodox) practice with Obsidian as the persistent store.

## Goal

A single slash command, `/ifs-session`, that walks the user through strict IFS
sessions. Parts and sessions persist as Obsidian pages navigated by
`[[wikilinks]]`. Doctrinal lines around Self, unblending, and never voicing
parts are non-negotiable.

Scope: personal tool for one user, not distributable.

---

## 1. Skill architecture

Single skill + a shared (non-skill) reference directory:

```
~/.claude/skills/
├── ifs-session/SKILL.md      → guided 6 F's walkthrough (the only command)
└── ifs-shared/               (not a skill; reference dir)
    ├── PROTOCOL.md           → 6 F's, anchor + unblending + re-targeting,
                                cycle detection, polarization work, closing
    ├── TAXONOMY.md           → manager / firefighter / exile definitions
    ├── OBSIDIAN.md           → file paths, schemas, templates
    └── SAFETY.md             → crisis handling, scope limits, tier gating
```

Rationale: structured session work is the only mode where Self-contact is
reliable. Quick-journal and browse commands were considered and cut — they
risk substituting cataloging for actual Self↔part contact, which is the
therapeutic mechanism.

---

## 2. Obsidian location & folder structure

Inside `6 - Full Notes/IFS/`, fairly flat, wiki-navigated (not
file-tree-navigated).

```
6 - Full Notes/IFS/
├── IFS.md                    ← homepage (Dataview dashboard + crisis_fallback pointer)
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
- The therapeutic mechanism is *Self contacting part*. Claude voicing parts
  short-circuits that contact.
- Mid-session "just this once" requests to role-play are themselves often a
  part trying to avoid Self-contact. Skill explains and offers strict-IFS
  alternative ("I won't voice the part, but I can ask you what you hear when
  you ask it directly").
- Hard refusal also keeps Claude safe when heavy material surfaces — no
  character to break.

Claude also never names or classifies parts on the user's behalf. It reflects
the user's own words back as candidate framings, never synthesizes
("sounds like a perfectionist part"). Surfacing a known part by name is only
valid after the user describes something concrete, and even then as a
question, not an assertion.

This guardrail must be explicit in the skill prompt; without it, the behavior
will erode.

### 3a. Propose-and-ratify

Claude proposes protocol branches; the user ratifies them. The AI never
silently changes scope. Anchor pivots, re-targets, cycle responses, wrap
proposals, and session close all require explicit user confirmation. The
AI's role is to observe and offer, not to decide.

This is the same family as "never names parts on the user's behalf" — both
exist to prevent the AI from acting as the locus of agency in the system.
The user's Self is the locus; the AI surfaces options.

The single exception is the imminent-harm pattern match (§4d), which
breaks protocol unilaterally.

---

## 4. Safety

### 4a. Crisis fallback pointer (mandatory)

`IFS.md` frontmatter must contain `crisis_fallback: [[Crisis Plan]]`. If the
pointer or the target page is missing, `/ifs-session` **refuses to run at
all** and makes the user write `Crisis Plan.md` first.

The Crisis Plan is a user-authored concrete self-regulation protocol —
ideally 2–3 pre-committed items (*"text [person], 20-min walk, no screens
until morning"*). Not a hotline, not a therapist. Written in a non-crisis
moment.

### 4b. Check-in shape and refusal criteria

`/ifs-session` opens with a 60–90 second check-in structured as a 3-step
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

Order rationale: mood first because safety refusal has to gate the rest.
Tier before trailhead because tier gates depth (§4f) — if it's short, the
AI knows F8 is off-limits and can flag heavy-looking trailheads as
better-saved-for-a-longer-session.

**Refusal criteria** (run on step 1 only):

- Active suicidal ideation (plan/means/timeline)
- Acute crisis within the last 24h (assault, loss, medical)
- Intoxication or substances on board

Does **not** refuse on high distress alone (high distress is exactly when IFS
helps). On refusal the skill names the crisis fallback in one line and
closes — before tier is ever asked. No therapist-voice boilerplate.

If the user reports "no Self-energy at all," the skill pivots to
observational parts-mapping (no F4 contact) rather than refusing.

**Why AskUserQuestion only at tier:** the IFS modality lives in the user's
own language — naming, descriptions, the 8 C's check, pulse-check texture
that reveals dissociation. A menu at any in-session decision point would
shape the answer before the user has felt into it. Tier is the one
exception because it's a contractual commitment made in planner-mode
*before* session work begins.

### 4c. Mid-session pulse check

At every F-transition the skill asks a one-line orientation check: *"Still
here and oriented? Want to continue?"* Yes → continue. Anything else →
branch to closing ritual.

At F3 ("Flesh out") the skill adds a dissociation cue: *"Check: can you still
feel the chair / your feet / the room?"* A bail at that cue is treated as a
hard "close now, no deeper contact."

Pattern-matching on crisis language mid-session is otherwise passive — strict
IFS assumes the user has access to Self enough to notice. Over-scanning is
fragile and infantilizing.

### 4d. Imminent-harm pattern match

The one exception to passive safety: if user text looks like an acute
emergency signal (explicit imminent-harm statement), the skill breaks
protocol immediately with: *"Going to the crisis plan. [[Crisis Plan]]."*
No pulse-check, no ritual, session ends.

### 4e. Bailed sessions

Any bail runs the closing ritual (thank + permission + step-out), logs
session as `status: interrupted`, and flags every part touched with
`left_without_resolution: true` in its frontmatter.

### 4f. Session tier and time budget

User picks a tier at check-in (§4b step 2). The tier is a soft wall-clock
budget *and* a depth gate.

| Tier   | Range       | Depth                                           |
| ------ | ----------- | ----------------------------------------------- |
| Short  | ~15–25 min  | F8 (exile contact / unburdening) blocked entirely |
| Medium | ~30–45 min  | F8 only with explicit user request + protector permission |
| Long   | ~60–90 min  | F8 per existing protocol (protector permission required) |

Tier-gates-depth rationale: unburdening work cut off at the upper bound is
worse than not starting — exiles left partially unburdened is a real IFS
concern. Tier is a commitment to how deep you're willing to go today, not
just how long.

**Wrap behavior:**

1. AI silently tracks wall-clock against the tier upper bound.
2. **Soft wrap** — ~5 min before upper bound, AI proposes once: *"We're
   near your time — want to close, or keep going?"* User ratifies close →
   skip any unworked phases, route to closing ritual. User says keep
   going → AI does not re-propose for ~10 min.
3. **Firm wrap** — at the upper bound, AI proposes again, firmer: *"We're
   at your limit — heading to close."*
4. Wrap never cuts mid-phase. If wrap is ratified mid-F5, finish that
   phase's contact, then closing ritual.
5. The closing ritual *always* runs (per §5c).

**Extension is ad-hoc, not pre-declared.** No "how much extra do you want
budgeted?" up front. If short ends up wanting to be longer, that
conversation happens at the wrap proposal.

**Crisis-pattern override:** imminent-harm pattern match (§4d) ignores
wrap state and closes immediately.

---

## 5. Session protocol — the 6 F's

Canonical 6 F's: **Find, Focus, Flesh out, Feel toward, beFriend, Fears.**

Phases are tracked internally but never narrated to the user out loud (no
"moving to F4 now"). Flow is implicit. The user's complaint that drove
this design was sessions feeling endless and stopping arbitrarily — both
addressed not by surfacing the phase scaffold to the user, but by tier
budgeting (§4f), cycle detection (§5b), and propose-and-ratify (§3a).

### 5a. Anchor, light-touch unblending, re-targeting

Three distinct moves, often conflated by "IFS-flavored" apps. Conflating
them is what produces the "going in circles" failure mode where a session
chases every part that mentions itself.

**Anchor (one per session).** A single anchor part is identified at F1
and held as the focus through the whole session. Other parts that surface
*outside* the F4 unblending check get acknowledged with Self-energy ("I
hear you, I'll come back") and logged to the session's `## Open threads`
or to `Trailheads.md` — they are not pivoted to. The AI never silently
re-anchors (per §3a).

**Light-touch unblending (F4 first move).** When the user's answer to "how
do you feel toward the [anchor] part?" is anything other than the 8 C's
(Curious, Calm, Clear, Compassionate, Confident, Courageous, Creative,
Connected), a second part is blended in. The first move is *not* to run
the 6 F's on it. The first move is the orthodox light-touch ask:

> *"Would it be willing to step back, pull its energy back a little, or
> make some space so you can be with [anchor] more easily?"*

30 seconds, a handful of turns. Most blends step back from a Self-curious
ask. Then return to the anchor and continue F4. Session note records the
unblending event (count only — no nested sub-record).

**Re-targeting (escalation).** If the blended part won't step back from
the light-touch ask, orthodox IFS doctrine has a specific move: *the
blended part becomes the new target.* The skill ratifies this with the
user explicitly:

> *"This part isn't stepping back. We can pivot the session to it, come
> back to [original anchor] next time, or close here. Which?"*

If the user pivots, the new target *is* the anchor for the rest of the
session; the original is logged as an open thread. Never a silent drift.

**Re-targeting can stack.** Depth isn't the failure mode — *cycles* are
(see §5b). A → B → C → D linear descent through new parts is fine. A → B
→ A is a cycle and gets caught.

**The single most consequential design call in the whole skill** is
keeping these three moves separate. The earlier draft of this section
collapsed light-touch unblending into "lightly 6 F it until it agrees to
step back," which is exactly the recursion that produces endless,
directionless sessions.

### 5b. Cycle detection and polarization work

Cycles aren't a bug in the protocol — they're diagnostic. A session that
keeps returning to the same parts is telling you something specific:
polarization (two parts in active conflict), protector pile-up (multiple
managers guarding the same exile), or system-wide activation that won't
let any one part land. The AI's job is to *surface that observation*,
never to silently ride the loop.

**Cycle signals.** Either trips cycle handling:

1. **Repeat blend** — the same part blends at F4 twice in one session
   (whether the first blend was light-touch resolved or re-targeted).
   Signal: this part isn't ready to step back today.
2. **Re-target pile-up** — three distinct re-targets in one session, even
   without return. Signal: system is too activated to land anywhere
   today.

(Earlier drafts considered a third signal — "re-target back to a prior
target" — and dropped it: signal #1 catches the same A↔B ping-pong one
beat later, with cleaner semantics. Returning to a prior target after
successful light-touch unblending is the *happy path* and was easy to
confuse with cycling.)

**Cycle response.** When a signal trips, the AI pauses the protocol,
names the pattern in one line, and offers three paths in prose (no
AskUserQuestion):

- **(i) Polarization work** — see protocol below. Replaces the rest of
  the session.
- **(ii) Pick one and commit** — *"If you had to work with just one
  today, which?"* User commits to one part as the anchor for the
  remaining session; others are logged as open threads.
- **(iii) Close and log** — name the cycle in the session note, mirror a
  `polarized_with:` link on each involved part page (per §8 sub-decisions),
  close.

**Default is (iii)** if the user disengages or can't decide. A
dysregulated system trying to do polarization work is just more cycling;
(i) only works *from* Self, and a user who's just ping-ponged between
parts probably isn't cleanly there. (iii) is the safest default; the
cycle observation persists across sessions via the mirrored
`polarized_with:` field, which surfaces in the next session's Phase 2
load.

**Polarization work protocol** (option i — orthodox Schwartz move):

1. **Name the polarization.** *"These two seem tied up with each other —
   does that feel right?"*
2. **Invite both to make space simultaneously.** Not step back fully —
   just enough that Self can see both at once. Externalize: *"can you see
   them both in front of you?"*
3. **Self curious toward both, equally.** *"What does each of them need?"*
   Asked of the user, never role-played by Claude.
4. **Surface what each protects.** Polarized pairs are usually two
   protectors guarding different facets of the same vulnerability.
   Naming the shared exile below makes the fight make sense.
5. **Ask for cooperation, not merger.** *"Would you both be willing to
   let me lead for a bit, without either of you taking over?"* Not
   "settle your differences."
6. **Log.** Polarization pair recorded; what each protects; whether
   cooperation was agreed.

It is explicitly *not*: running 6 F's on each part individually, trying
to resolve the polarization in one session, or making either part
relinquish its role. Resolution is multi-session work.

**Scope:** polarization work *replaces* the remainder of the 6 F's.
After step 6, route directly to the closing ritual (§5c). Continuing
F5/F6 on either polarized part after naming would re-trigger the cycle.

### 5c. Closing ritual (mandatory unless explicitly bailed)

1. Thank each part contacted.
2. Ask if they have anything more to share.
3. Ask permission to come back later.
4. "Step out" — re-orient to body, room, present.

Sessions don't get logged as `complete` until the ritual runs.

When wrap (§4f) skips remaining unworked phases, the closing ritual still
runs in full — wrap shortens the work, never the close.

### 5d. Full session flow

```
1. Check-in            → mood (free text, safety gate) → tier (AskUserQuestion)
                         → trailhead (free text) → echo. See §4b.
2. Find & Focus        → locate the anchor part (§5a). One per session.
3. Flesh out           → describe it (includes dissociation cue)
4. Feel toward         → SELF CHECK
                         → if not 8 C's: light-touch unblending (§5a)
                         → if won't step back: ratified re-target (§5a)
                         → cycle signals tracked throughout (§5b)
5. Befriend            → relationship-building
6. Fears               → surface what it protects
7. (optional) Deeper   → exile contact, unburdening — protector permission
                         required AND tier-gated (§4f). Short blocks; medium
                         opt-in; long allowed.
8. Closing ritual      → thank, ask, permission, step out (§5c)
9. Log to Obsidian     → session note + part page updates (§9)
```

Pulse check runs at every transition between phases (see §4c).

Phases are *not* named to the user out loud (no "moving to F4 now"
narration). Flow is implicit. Wrap (§4f) can collapse remaining unworked
phases at any point; cycle response (§5b) can replace the remainder with
polarization work; either way, step 8 (closing ritual) always runs.

---

## 6. State persistence

Lazy, two-phase load at the start of `/ifs-session`.

**Phase 1 (eager, always):**

- `IFS.md` frontmatter (for `crisis_fallback` + homepage pointers).
- Most recent session note's frontmatter and `## Open threads` section only
  (not the full body).
- `Trailheads.md` full contents.
- No part pages.

**Phase 2 (on-demand, after trailhead phase):**

- Part pages read only when named in conversation, or when the user confirms
  a new description matches an existing part.
- Never preload the full active roster.

Rationale: strict IFS meets what's present, not what a dossier predicts. The
"last session you flagged X" prompt is the one concession to continuity, and
it's opt-in.

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

At the end of F3 the skill asks: *"If this part introduced itself, what
would it call itself?"* If the user stalls, the skill offers the
deferred-naming fallback: file as `Unnamed YYYY-MM-DD #N` and name later.

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
- **Polarizations mirrored on both parts** — the skill writes both sides.
- **Recent encounters surfaced via Obsidian backlinks**, not a maintained
  section. Every session note that wikilinks a part shows up on that part's
  page automatically.
- **`status: unburdened`** is a real, recorded event in strict IFS.
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
tier: medium               # short | medium | long (§4f)
duration_min: 35
status: complete           # complete | interrupted
checkin_state: tight chest, mild dread
parts_touched: [[wants me to double-check everything]], [[the tight jaw]]
new_parts: [[the tight jaw]]
unblending_events: 1
re_targets: 0              # count of ratified re-targets (§5a)
cycle_detected: false      # true if §5b signal tripped
polarization_work: false   # true if cycle response (i) was chosen
polarization_pair:         # populated if polarization_work or close-with-cycle
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

### [[the tight jaw]]  (blended in at F4)
- Surfaced as unblending event
- What it needed
- Stepped back: yes

## What Self noticed
System-level observations. Polarizations sensed, allies noticed.

## Closing
- Parts thanked: yes
- Permission to return: granted by double-checking part; tight-jaw deferred
- Re-orientation: yes

## Open threads
- [ ] Double-checking part mentioned an "earlier one" — possible exile, return next session
- [ ] Double-checking and tight-jaw may be polarized — explore
```

Sub-decisions:

- **Light-touch unblending events counted, not narrated.** `unblending_events`
  is a count in frontmatter. The body section under each part records *how
  it appeared this session* — including light-touch unblendings as part of
  that — but doesn't separately enumerate them.
- **Re-targets logged as their own parts encountered.** When a re-target
  happens, the new target gets its own `### [[part name]]` section in
  `## Parts encountered`, with a note like *"re-targeted from
  [[original anchor]] at F4 — wouldn't step back."* Preserves the
  narrative.
- **Cycle detection events go in `## What Self noticed`.** Prose:
  *"[A] and [B] cycled twice — likely polarized."* Plus
  `cycle_detected: true` and `polarization_pair: [[A]], [[B]]` in
  frontmatter, plus mirrored `polarized_with:` on each part page.
- **`previous_session` link** in frontmatter — chronology navigable as a
  wiki chain.
- **No retroactive editing of session notes.** New understanding goes on the
  *part* page or in the *next* session's `## What Self noticed`. Editing
  past sessions corrupts the record of how understanding actually developed.
- **`## Open threads` as Obsidian task checkboxes** — `/ifs-session` reads
  the most recent session's Open threads at start: "Last session you flagged
  X — pick that up?"

---

## 10. Trailheads.md

Flat, dated, append-only scratch list of unworked entry points. Written by
the user manually in Obsidian between sessions; read by `/ifs-session` at the
trailhead phase.

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

At the trailhead phase, `/ifs-session` surfaces both sources together:

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

The three kept sections serve the stated goal: sort which parts are which
and see how they relate. Nothing more.
