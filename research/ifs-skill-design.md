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
    ├── PROTOCOL.md           → 6 F's, unblending sub-loop, closing ritual
    ├── TAXONOMY.md           → manager / firefighter / exile definitions
    ├── OBSIDIAN.md           → file paths, schemas, templates
    └── SAFETY.md             → crisis handling, scope limits
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

### 4b. Check-in refusal criteria

`/ifs-session` opens with a 60–90 second check-in. Skill **refuses to start
a session** on:

- Active suicidal ideation (plan/means/timeline)
- Acute crisis within the last 24h (assault, loss, medical)
- Intoxication or substances on board

Does **not** refuse on high distress alone (high distress is exactly when IFS
helps). On refusal the skill names the crisis fallback in one line and
closes. No therapist-voice boilerplate.

If the user reports "no Self-energy at all," the skill pivots to
observational parts-mapping (no F4 contact) rather than refusing.

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

---

## 5. Session protocol — the 6 F's

Phase-aware adaptive, with a toggle to escalate to checklist-strict. Names
phases explicitly in early sessions; quieter about structure later.

Canonical 6 F's: **Find, Focus, Flesh out, Feel toward, beFriend, Fears.**

### 5a. Recursive unblending sub-loop (non-negotiable)

At "Feel toward" (F4), if the user's feeling is anything other than the 8 C's
(Curious, Calm, Clear, Compassionate, Confident, Courageous, Creative,
Connected), another part is blended in. Protocol pauses:

1. Turn toward the blended part.
2. Lightly 6 F it until it agrees to step back.
3. Return to the original part.
4. Session note logs the nesting.

This is the single most consequential design call in the whole skill, and the
move most "IFS-flavored" apps skip.

### 5b. Closing ritual (mandatory unless explicitly bailed)

1. Thank each part contacted.
2. Ask if they have anything more to share.
3. Ask permission to come back later.
4. "Step out" — re-orient to body, room, present.

Sessions don't get logged as `complete` until the ritual runs.

### 5c. Full session flow

```
1. Check-in            → state assessment, safety gate
2. Trailhead           → surface unworked trailheads + prior session's Open threads
3. Find & Focus        → locate the part
4. Flesh out           → describe it (includes dissociation cue)
5. Feel toward         → SELF CHECK (recursive unblending if needed)
6. Befriend            → relationship-building
7. Fears               → surface what it protects
8. (optional) Deeper   → exile contact, unburdening — only with protector permission
9. Closing ritual      → thank, ask, permission, step out
10. Log to Obsidian    → session note + part page updates
```

Pulse check runs at every transition between phases (see §4c).

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
duration_min: 35
status: complete           # complete | interrupted
checkin_state: tight chest, mild dread
parts_touched: [[wants me to double-check everything]], [[the tight jaw]]
new_parts: [[the tight jaw]]
unblending_events: 1
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

- **Recursive unblending logged inline** under the originating part —
  preserves the narrative that the second part blended *while we were with
  the first*.
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
