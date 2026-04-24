# IFS Skill — Design Decisions

Brainstorming output for a Claude Code skill (or set of skills) to support
strict-IFS practice with Obsidian as the persistent store. Captured from a
grilling session on 2026-04-23.

## Goal

A small family of slash commands that:

- Walk the user through IFS sessions following strict (Schwartz-orthodox) protocol.
- Identify and file new parts.
- Browse/query the user's existing parts system.
- Persist everything as Obsidian wiki pages, navigated by `[[wikilinks]]`.

Constraint: **strict IFS**. Not "IFS-flavored." Doctrinal lines around Self,
unblending, and never voicing parts are non-negotiable.

---

## 1. Skill architecture

**Decision:** Small family of slash commands + a shared (non-skill) reference
directory.

```
~/.claude/skills/
├── ifs-session/SKILL.md      → guided 6 F's walkthrough
├── ifs-part/SKILL.md         → quick file a new part outside a session
├── ifs-browse/SKILL.md       → query existing parts
└── ifs-shared/               (not a skill; reference dir)
    ├── PROTOCOL.md           → 6 F's, unblending sub-loop, closing ritual
    ├── TAXONOMY.md           → manager / firefighter / exile definitions
    ├── OBSIDIAN.md           → file paths, schemas, templates
    └── SAFETY.md             → crisis handling, scope limits
```

Rationale: distinct intents (active session vs. quick journal vs. browsing) get
distinct triggers; protocol knowledge lives once.

---

## 2. Obsidian location & folder structure

**Decision:** Inside `6 - Full Notes/IFS/`, fairly flat, wiki-navigated (not
file-tree-navigated).

```
6 - Full Notes/IFS/
├── IFS.md                     ← homepage / Dataview dashboard
├── Parts/                     ← flat, all parts here
├── Sessions/                  ← flat, dated session notes
└── Trailheads.md              ← running scratch list of unexplored entry points
```

- Two folders deep is the only nesting.
- Part type lives in frontmatter, not folder structure (reclassification is common).
- Dataview is installed and assumed available for the homepage.

---

## 3. Part page schema

**Decision:** Frontmatter for queryable facets, body sections for prose.

```markdown
---
type: part
part_type: manager        # manager | firefighter | exile | unknown
status: active            # active | unburdened | dormant
first_met: 2026-04-23
last_seen: 2026-04-23
age_felt: ~7
protects: [[Small One]]   # protectors only — points at the exile
polarized_with: [[The Critic]]
allies: [[The Planner]]
tags: [ifs, part]
---

# The Strategist

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

- **No `8Cs_present` field on parts.** Self-energy is a session-level observation,
  not a part property.
- **Polarizations mirrored on both parts** — the skill writes both sides.
- **Recent encounters surfaced via Obsidian backlinks**, not a maintained section.
- **`status: unburdened`** is a real, recorded event in strict IFS.
- **`age_felt`** = how old the part feels, not user's age when it formed.

---

## 4. Claude's role during sessions

**Decision:** Pure coach. Hard refusal to role-play parts, even on user override
mid-session.

- Claude only ever speaks to the user.
- Claude never voices a part, never says "Hi Strategist, what do you need?",
  never simulates dialogue.
- The therapeutic mechanism is *Self contacting part*. Claude voicing parts
  short-circuits that contact.
- Mid-session "just this once" requests to role-play are themselves often a
  part trying to avoid Self-contact. Skill explains and offers strict-IFS
  alternative ("I won't voice the part, but I can ask you what you hear when
  you ask it directly").
- Hard refusal also keeps Claude safe when heavy material surfaces — no
  character to break.

This guardrail must be explicit in the skill prompt; without it, the behavior
will erode.

---

## 5. Session protocol — the 6 F's

**Decision:** Phase-aware adaptive (B), with a toggle to escalate to
checklist-strict (A). Names phases explicitly in early sessions; quieter about
structure later.

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

Sessions don't get logged as `complete` until the ritual runs. Bailed sessions
are logged as `interrupted` with a flag on parts touched: "left without closing
— return to."

### 5c. Pre-session check-in

Every `/ifs-session` opens with a 60–90 second check-in. Doubles as safety gate
— if user reports crisis-level distress, skill **does not start a session**
(see `SAFETY.md`).

### Full session flow

```
1. Check-in            → state assessment, safety gate
2. Trailhead           → what brought you here
3. Find & Focus        → locate the part
4. Flesh out           → describe it
5. Feel toward         → SELF CHECK (recursive unblending if needed)
6. Befriend            → relationship-building
7. Fears               → surface what it protects
8. (optional) Deeper   → exile contact, unburdening — only with protector permission
9. Closing ritual      → thank, ask, permission, step out
10. Log to Obsidian    → session note + part page updates
```

---

## 6. Session note schema

**Decision:** Append-only historical record. Frontmatter for queryable events,
prose body for narrative.

```markdown
---
type: session
date: 2026-04-23
duration_min: 35
status: complete           # complete | interrupted
checkin_state: tight chest, mild dread
parts_touched: [[The Strategist]], [[The Critic]]
new_parts: [[The Critic]]
unblending_events: 1
permission_granted: [[The Strategist]]
exile_contact: false
unburdening: false
previous_session: [[2026-04-19 — ...]]
tags: [ifs, session]
---

# 2026-04-23 — first contact with Strategist

## Trailhead
What brought you to this session.

## Arc
Brief prose narrative — the inner movement, not a transcript.

## Parts encountered
### [[The Strategist]]
- How it appeared this session
- What it shared
- State at end

### [[The Critic]]  (blended in at F4)
- Surfaced as unblending event
- What it needed
- Stepped back: yes

## What Self noticed
System-level observations. Polarizations sensed, allies noticed.

## Closing
- Parts thanked: yes
- Permission to return: granted by Strategist; Critic deferred
- Re-orientation: yes

## Open threads
- [ ] Strategist mentioned an "earlier one" — possible exile, return next session
- [ ] Critic and Strategist may be polarized — explore
```

Sub-decisions:

- **Recursive unblending logged inline** under the originating part — preserves
  the narrative that Critic blended *while we were with Strategist*.
- **`previous_session` link** in frontmatter — chronology navigable as a wiki
  chain; enables clean Dataview "last 5 sessions" queries.
- **No retroactive editing of session notes.** New understanding goes on the
  *part* page or in the *next* session's `## What Self noticed`. Editing past
  sessions corrupts the record of how understanding actually developed.
- **`## Open threads` as Obsidian task checkboxes** — skill scans across all
  session files at start of next session: "Last session you flagged X — want
  to pick that up?"

---

## Open / unresolved branches

The grilling session ended before reaching these. Worth resolving before
implementation:

- **Naming approach** — how creative names for new parts get generated. User
  input vs. AI-suggested vs. collaborative. Style register (whimsical?
  archetypal? descriptive?).
- **Safety / scope** — crisis detection, suicidal ideation handling, when to
  refuse a session, how the skill talks about not being a therapist.
- **State persistence across sessions** — what does Claude read at the start
  of `/ifs-session`? All part pages? Recent sessions only? Open threads only?
- **`/ifs-part` flow** — the lightweight "I noticed a part, file it" command
  outside an active session. Schema same as session-discovered parts? Less?
- **`/ifs-browse` flow** — the queries that matter. "Show my managers." "Who's
  polarized?" "Parts I haven't seen in 30 days." Concrete query set vs. open NL.
- **`IFS.md` homepage** — exact Dataview queries. Active parts, recent
  sessions, open threads, polarization map.
- **`Trailheads.md` format** — flat list? Categorized? Auto-promoted to part
  pages once worked?
```

