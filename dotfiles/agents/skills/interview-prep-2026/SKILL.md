---
name: interview-prep-2026
description: Interview Prep 2026 plan cadence. Use when the user asks to update the Obsidian interview plan, change daily tasks, add low-level design inserts, or rebalance Hello Interview prep.
---

# Interview Prep 2026

Maintain Michael's Obsidian interview plan at `/home/michael/My Vault/6 - Full Notes/Interview Prep 2026`.

Load the `obsidian-vault` skill before reading or editing vault notes.

## Source Map

- Dashboard: `/home/michael/My Vault/4 - Indexes/Interview Prep 2026.md`
- Daily pages: `/home/michael/My Vault/6 - Full Notes/Interview Prep 2026/Daily/`
- Trackers: `/home/michael/My Vault/6 - Full Notes/Interview Prep 2026/Trackers/`
- References: `/home/michael/My Vault/6 - Full Notes/Interview Prep 2026/Reference/`

Treat the dashboard and daily pages as the plan's source of truth. Treat trackers as read-only Dataview maps unless the request changes the tracker taxonomy itself.

## Cadence Rules

- Goal: senior fullstack interviews at medium-sized companies in 2026.
- Bias: design-led prep, practical engineering judgment, AI/practical coding, behavioral readiness, and interview communication over FAANG-style algorithm breadth.
- Default objective: complete all planned courses by the end of the plan.
- Each day is 90 minutes.
- Reviews are normally 10 minutes.
- Non-review work should not be split into blocks under 25 minutes.
- Behavioral work appears in larger weekly chunks instead of tiny daily fragments.
- DS&A stays in core-pattern maintenance unless the user changes the goal.
- Days are incremental whole numbers. When adding or reshaping course work, create or reshape whole-number daily pages and keep navigation sequential.
- Completed days are historical record. Never update completed daily pages.
- Course adjustments should distribute load across the remaining incomplete course unless the user asks for a concentrated block.
- Adding a significant amount of material should trigger Course Rebalance instead of local patching.

## Workflow

### 1. Orient

Read the dashboard's `Goal`, `Daily Time Split`, `Time Rules`, and `Weekly Operating Rule` sections. Read the relevant daily pages, including neighboring days when adding, moving, renumbering, or deleting sessions. Read the relevant reference notes for the requested track.

Completion criterion: the affected days, plan rules, adjacent `Previous`/`Next` links, whole-number day sequence, and relevant course/reference material are known before proposing or editing changes.

### 2. Ask Correction Questions

Ask questions only when missing information would materially change the schedule, such as deadline, target companies, daily time budget, replacing versus inserting days, or which track should lose time. If there is one reasonable interpretation, proceed and state the assumption in the final summary.

Completion criterion: every material ambiguity is either answered by the user or carried forward as an explicit assumption.

### 3. Shape The Plan

Preserve the current cadence unless the user asks to change it. When the request is broad, update incomplete daily pages only and spread added, removed, or rebalanced work across the remaining course unless told otherwise. Keep the dashboard aligned only when the global goal, phase structure, or operating rules change.

Completion criterion: every requested change maps to specific daily pages, dashboard rules, or tracker taxonomy changes before editing.

### 4. Edit Daily Pages

Match the existing daily-note format:

- YAML frontmatter with `day`, `completed`, `completed_date`, `focus`, and `topics`.
- `Dashboard`, `Flashcards`, `Previous`, and `Next` links.
- `## 90 Minute Plan` with checklist tasks.
- The existing `## Complete This Day` DataviewJS block.
- `## Links` with the relevant course and tracker links.

Preserve completed checkboxes, completion dates, and completed daily pages. Use the relevant course reference, tracker link, topic names, and track-specific task expectations already established in nearby daily pages.

Completion criterion: every modified or created daily page follows the format, totals 90 minutes, and has correct navigation links.

### 5. Validate

Check all touched daily notes for valid frontmatter, 90-minute totals, dashboard links, tracker links, and `Previous`/`Next` consistency. Check that tracker topic names are existing names unless the request intentionally adds taxonomy.

Completion criterion: every touched file has been re-read after editing and the final response lists changed files plus any assumptions or follow-up decisions.

## Branches

### Broad Plan Refresh

If the user says to update the plan without a range, treat every incomplete daily page as in scope. Read enough completed pages to preserve the established cadence, but do not rewrite completed pages.

### Course Rebalance

When shifting time between system design, AI coding, behavioral, DS&A, low-level design, or another track, or when adding a significant amount of material, read that track's reference note, tracker, nearby daily pages, and neighboring days around the affected range. Use the reference note's time estimates as the source of truth over existing daily-note estimates, so each day's allotted work is realistic, neither overloaded nor padded. Calculate remaining reference-estimated work against remaining incomplete-day capacity before editing. If the work does not fit, give the user three choices with math: extend the plan by the needed number of days, cut or defer specific lower-priority work with minutes saved, or use a hybrid of fewer added days plus selected cuts. Treat course completion as the default objective, and make any course cuts explicit before asking the user to choose. Distribute the chosen change across the remaining incomplete course unless the user asks for a concentrated block. Update affected day metadata plus `Previous`/`Next` links. Update the dashboard rules if the change becomes a new standing policy. Otherwise keep the change local to daily pages.
