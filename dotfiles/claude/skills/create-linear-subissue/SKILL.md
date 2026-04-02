---
name: create-linear-subissue
description: Create a Linear sub-issue under the current branch's PRD from conversation context. The branch name IS the PRD — fetches it directly, creates a sub-issue with the AI label, and links it. Does not perform the changes. Use when user wants to file a sub-issue, log a task, or track needed work discovered during review or manual feedback after an afk-ralph run.
allowed-tools:
  - Bash(git:*)
---

# Create Linear Sub-Issue

Create a Linear sub-issue under the current branch's PRD. Use after identifying needed work during conversation (e.g., post-afk-ralph manual feedback).

---

## Process

### 1. Fetch the PRD

Get the current branch name:
```bash
git rev-parse --abbrev-ref HEAD
```

The branch name **is** the Linear PRD branch. Use `get_issue` MCP tool with `branchName` set to the branch name to fetch the parent PRD directly.

If no issue is found, ask the user for the parent issue identifier.

### 2. Identify the work

From the current conversation context, identify what issue or feature the user wants to file. Ask the user to describe it if not already clear. Grill briefly to clarify:

- What exactly needs to change?
- Is this a bug fix or a feature?
- Any acceptance criteria?

Keep it short — one or two questions max if the intent is already clear.

### 3. Create the sub-issue

Create a Linear sub-issue using the `save_issue` MCP tool on the **MECA Therapies** team:

- **Parent issue:** the PRD from step 1
- **Type:** Bug if it's a defect, otherwise Feature
- **Assign to:** me
- **Labels:** AI
- **Status:** Todo
- **Title:** concise description of the work
- **Body:**

```markdown
## What to build

{Concise description of the change. Reference the parent PRD for broader context rather than duplicating it.}

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Context

Filed during manual review of {PRD identifier}: {PRD title}.
```

### 4. Report

Print a confirmation:

```
Sub-issue created: {IDENTIFIER}: {title}
{linear_url}

Parent PRD: {PRD identifier}: {PRD title}
```

**Do NOT perform any code changes.** The sub-issue will be picked up in a future afk-ralph run or worked manually.

---

## Common Mistakes

- Don't start implementing the change — this skill only files the issue.
- Don't skip the PRD lookup — always anchor sub-issues to the parent.
- Don't forget the AI label.
- Don't create overly vague acceptance criteria — be specific enough for afk-ralph to act on.
