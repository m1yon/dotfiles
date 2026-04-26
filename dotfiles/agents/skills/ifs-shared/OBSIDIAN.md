# OBSIDIAN.md — vault paths, schemas, templates, pending-changes log

Reference for Obsidian-side state for `/em-ifs-session`. The conversation orchestrator never writes mid-session; the `ifs-session-writer` subagent applies a typed pending-changes log atomically at session end.

## Vault root

```
/home/michael/My Vault/
```

Pinned here and in the `ifs-session-writer` subagent's system prompt. Not pinned in `SKILL.md`.

## Folder structure

```
/home/michael/My Vault/6 - Full Notes/IFS/
├── IFS.md                ← homepage (user-authored from §"IFS.md homepage template" below)
├── Crisis Plan.md        ← user-authored fallback protocol; required to exist
├── Trailheads.md         ← flat dated scratch list (user-edited between sessions)
├── Parts/                ← flat, all part pages
└── Sessions/             ← flat, dated session notes
```

Two folders deep is the only nesting. Part type lives in frontmatter, not folder structure.

## First-run bootstrap (skill side)

On every session start:

- Create `<vault>/6 - Full Notes/IFS/Sessions/` if missing.
- Create `<vault>/6 - Full Notes/IFS/Parts/` if missing.
- Do NOT create `IFS.md` or `Crisis Plan.md`. If either is missing, the skill hard-refuses (see `SAFETY.md`).
- Do NOT create `Trailheads.md`. Treat missing `Trailheads.md` as an empty list at the trailhead step.

## IFS.md homepage template

User authors this. Skill reads `crisis_fallback:` from frontmatter.

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

Deliberately excluded: recent-sessions list, "parts not seen in N days" query, aggregated open-threads view, glimpse-history dashboard. Those would invite manager behavior or completion anxiety.

## Crisis Plan.md (purpose)

User-authored concrete self-regulation protocol. Ideally 2–3 pre-committed items written in a non-crisis moment (e.g. *"text [person], 20-min walk, no screens until morning"*). Not a hotline, not a therapist. Required to exist for the skill to run; the skill never writes to it.

## Part page schema

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
- No `8Cs_present` field on parts (Self-energy is a session-level observation).
- `polarized_with:` mirrored on both parts (subagent writes both sides).
- Recent encounters surfaced via Obsidian backlinks, not a maintained section.
- `status: unburdened` is a real recorded event.
- `age_felt` = how old the part feels, not user's age when it formed.
- `left_without_resolution: true` added by bailed sessions; cleared on next visit.
- **Titles are descriptive phrases only — never proper names.** Examples: `wants me to double-check everything`, `the small one at the window`, `the tight jaw`. The canonical title is expected to evolve; `aliases:` is append-only and never compressed, reading as the chronological record of how the part has been seen over time. See `PROTOCOL.md` §3-naming and §3-naming-rename for the alias-accumulation and collaborative-rename mechanics.

## Session note schema

Append-only historical record. Filename: `Sessions/YYYY-MM-DD — <short-desc>.md`.

```markdown
---
type: session
date: 2026-04-23
tier: medium                     # short | medium | long
duration_min: 35
status: complete                 # complete | interrupted | crisis_exit
checkin_state: tight chest, mild dread
re_glimpses: 0
parts_touched: [[wants me to double-check everything]], [[the tight jaw]]
new_parts: [[the tight jaw]]
unblending_events: 1
re_targets: 0
cycle_detected: false
polarization_work: false
polarization_pair: []
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

## What Self noticed
System-level observations.

## Closing
- Parts thanked: yes
- Permission to return: granted
- Rest-in-Self: yes
- Re-orientation: yes

## Open threads
- [ ] Double-checking part mentioned an "earlier one" — possible exile, return next session
```

Sub-decisions:
- Session notes are never retroactively edited. New understanding goes on the *part* page or in the *next* session's `## What Self noticed`.
- `## Open threads` written as Obsidian task checkboxes (`- [ ]`); next session reads as a checklist.
- Drift events counted in frontmatter (`unblending_events`), not separately enumerated in the body.
- Re-glimpses counted in frontmatter (`re_glimpses`) — Phase 1 has no auto-triggered re-glimpse, so non-zero values come from user-initiated re-glimpse or polarization-work step 1.
- Re-targets logged as their own `### [[part]]` section under `## Parts encountered`.
- Cycle detection events go in `## What Self noticed` plus `cycle_detected: true` and `polarization_pair:` in frontmatter.

## Trailheads.md format

```markdown
# Trailheads

Unworked entry points — things noticed that haven't been brought to a session yet.

- 2026-04-24: tightens when partner mentions money
- 2026-04-25: rehearsed an argument with no one in the shower
- ~~2026-04-20: keep noticing the "should have" voice~~ → [[2026-04-26 session]]
```

Rules:
- Flat, not categorized.
- Date-prefixed, bullet-per-line. Phone-editable.
- No frontmatter, no schema.
- When worked: skill strikes through and appends `→ [[session note]]`. Never deleted.

## Pending-changes log schema (typed)

In-memory mid-session, applied atomically by `ifs-session-writer` at session end. Subagent rejects malformed entries.

- `create_part { title, initial_frontmatter }`
- `append_alias { part_ref, new_phrase }`
- `rename_part { old_title, new_title, reason? }`
- `set_part_type { part_ref, type }` — `manager | firefighter | exile | unknown`
- `set_status { part_ref, status }` — `active | unburdened | dormant`
- `update_last_seen { part_ref, date }`
- `set_left_without_resolution { part_ref }` — added by bailed sessions to every part touched
- `clear_left_without_resolution { part_ref }` — cleared on next visit
- `record_polarization { pair: [a, b] }` — mirrored on both pages
- `record_protects { part_ref, exile_ref }`
- `strike_trailhead { line, session_link }`

`part_ref` resolves through the local pending-state view: a queued `rename_part { old: X, new: Y }` at minute 10 means a minute-25 reference to `X` already resolves to `Y`.

## Event log types (subagent input)

`anchor_selected`, `blend_at_f4`, `light_touch_step_back`, `re_target`, `cycle_detected`, `polarization_work`, `pulse_check`, `dissociation_cue_caught`, `exile_contact`, `unburdening`.

## Write order (subagent)

1. Session note first.
2. On success, part-page touches and `Trailheads.md` updates.
3. Later failures populate `failed[]` without rolling back the session note.
4. On any partial failure, write `Sessions/<date>-recovery.md` stub with the unwritten changes.
