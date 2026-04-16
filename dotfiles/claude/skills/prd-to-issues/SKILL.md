---
name: prd-to-issues
description: Break a PRD into independently-grabbable beads child issues under an epic using tracer-bullet vertical slices. Use when user wants to convert a PRD to issues, create implementation tickets, or break down a PRD into work items.
---

# PRD to Issues

Break a PRD into independently-grabbable beads child issues using vertical slices (tracer bullets). The PRD lives in an **epic** bead; each slice is a **child** of that epic (created with `--parent`).

## Process

### 1. Locate the PRD epic

Ask the user for the epic bead ID (e.g., `bd-a3f8e9`) that holds the PRD.

If the PRD is not already in your context window, fetch it with `bd show <id>`.

If the user has a PRD but no epic yet, offer to create one with:

```bash
bd create "<PRD title>" -t epic -p <0-4> --body-file <path-to-prd.md>
```

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code.

### 3. Draft vertical slices

Break the PRD into **tracer bullet** child issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be assigned to 'AI' or 'Human'. Human slices require human interaction, such as an architectural decision or a design review. AI slices can be implemented and merged without human interaction. Prefer AI over Human where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: `feature` | `task` | `bug` | `chore`
- **Assigned to**: AI / Human
- **Priority**: 0 (critical) / 1 (high) / 2 (medium) / 3 (low)
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices assigned to AI and Human?

Iterate until the user approves the breakdown.

### 5. Create the child issues under the epic

For each approved slice, create a child issue with `bd create --parent <epic-id>`. Children auto-number (e.g. `bd-a3f8e9.1`, `bd-a3f8e9.2`). Use `feature` as the default type for vertical slices; use `task`, `bug`, or `chore` where appropriate. Apply the `ai` label for slices assigned to AI, or the `human` label for slices assigned to Human.

Set the **priority** (`-p`) on each child using these rules (highest to lowest):

1. **0 (Critical)** — Critical bugfixes
2. **1 (High)** — Tracer bullets (thin end-to-end slices that validate architecture)
3. **2 (Medium)** — Polish and quick wins
4. **3 (Low)** — Refactors

Use `--body-file` or `--stdin` for the description to avoid shell-escaping issues. Example:

```bash
bd create "Slice title" \
  --parent bd-a3f8e9 \
  -t feature \
  -p 1 \
  -l ai \
  --body-file /tmp/slice-1.md \
  --json
```

Create children in dependency order (blockers first). After all children exist, add blocking relations:

```bash
bd dep add <blocked-child-id> <blocker-child-id>
# or equivalently:
bd link <blocked-child-id> <blocker-child-id>
```

The `--parent` flag already creates the structural `parent-child` link to the epic — do NOT add that manually.

<issue-template>
## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation. Reference specific sections of the parent PRD rather than duplicating content.

## Development approach

If the slice touches testable logic (APIs, business rules, data transformations, integrations), include this section recommending TDD:

> Use the `tdd` skill (red-green-refactor) to implement this slice.

Omit this section for slices that are purely configuration, UI layout, or infrastructure with no testable behavior.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</issue-template>

Do NOT close or modify the parent epic.
