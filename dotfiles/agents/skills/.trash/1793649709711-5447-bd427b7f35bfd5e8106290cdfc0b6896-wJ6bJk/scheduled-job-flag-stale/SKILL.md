---
name: "scheduled-job-flag-stale"
description: "Weekly job that finds Todoist tasks Michael has likely abandoned (old and untouched, or long overdue) and tags them @stale for the \"Still need these?\" filter. Used by the Sunday 7:43 AM scheduled task or run on demand."
---

# Flag stale tasks (weekly)

Once a week, find the to-dos in Michael Lyon's Todoist that he has probably stopped caring about, and make the `stale` label point at exactly those tasks. His favorite filter "Still need these?" (query `@stale`) shows the result, and he goes through it to complete or delete what he doesn't need. Assume no memory of earlier runs. Don't ask questions. End with a short summary.

You only flag. Michael decides. Never complete, delete, move, reschedule, or edit anything else.

## Context
- Michael Lyon, timezone America/Denver, Todoist user id 18992205. He has ADHD: a short review list he can clear in one sitting beats a giant one.
- Load tools with ToolSearch first: mcp__Todoist__find-tasks, mcp__Todoist__find-activity, mcp__Todoist__fetch-object, mcp__Todoist__update-tasks.
- Projects in scope:
  - Home & Family 6fpR3gJHfCJ8phg4
  - Money 6hhGx42xf79HXRV4
  - Core Project (his LLC) 6gf8RwrWXR94rM5c
  - MECA 6hhGx42gGrMJP7M9 (non-Linear tasks only)
  - Side Projects 6g747Frvj326c9VJ
  - Someday 6hpqFjWVMwxfRm39 (longer threshold, see step 3)
- Out of scope: Inbox 6Crfv33JcgwhPGr2 (the Triage filter handles it) and any project not listed above.
- Keeping a task: Michael removes `stale` from it (or edits it) in the Todoist app. That counts as touching it, so the rules below won't re-flag it for at least a month.

## 1. Gather candidates
Call find-tasks with filter `!#Inbox & !@linear & !recurring`, responsibleUserFiltering "unassignedOrMe", limit 100, and page with the cursor until done.

Drop a task when any of these is true:
- Its project is not one of the six in-scope projects.
- It is the Inbox assistant log task 6hprQ27W6mMHPXrh.
- It has the label `routine`, `daily-ish`, or `up-next` (up-next means the daily job just judged it worth doing).
- It has a due date today or later, or a deadlineDate today or later. He scheduled it on purpose.

Group what's left into trees: each top-level task plus all its open subtasks (use parentId). A subtask whose parent was dropped is its own tree root. You judge and flag whole trees, never individual subtasks of a tree.

## 2. Read recent activity
Call find-activity with initiatorId "18992205", dateFrom = 120 days ago (start of day, -06:00 or -07:00 offset), limit 100, and page with the cursor. Stop after 30 pages and note it in the summary. Read both objectType "task" and objectType "comment".
- completed events count from any client (he sometimes completes through Claude or ChatGPT). For a completed subtask, the event touches its parent tree (fetch-object on it if the parentId is not in the event).
- updated events count only when extraData.client starts with "Todoist" (his own apps). Updates from "Claude" or "ChatGPT" are automated (including this job's label changes), not his work.
- added comment events count from any client when the initiator is him; they touch the comment's task.
- For each task id, keep the latest event date: lastEvent.

If find-activity fails, stop without changing any labels and say so in the summary. Without activity data every old task looks stale.

## 3. Decide what's stale
For each tree, lastTouched = the latest of: every task's addedAt in the tree and every lastEvent in the tree.

A tree is stale when either holds:
- A. lastTouched is 60 or more days ago (120 or more days for a tree in Someday).
- B. Its root is overdue by 14 or more days (due date 14+ days in the past) and lastTouched is 30 or more days ago.

Record the reason for each stale tree, for example "untouched since Jun 6", "overdue since Sep 30, untouched 5 weeks", "Someday, untouched since Jul 2025".

## 4. Pick
- Keep every tree root that already has `stale` and is still stale (continuity).
- Add new stale trees, oldest lastTouched first, until there are 15 new ones this run or none left.
- Hard cap: at most 25 tasks labeled `stale` in total. If adding would exceed it, add fewer.
- Report how many stale trees were left unflagged because of the caps, so Michael knows more are waiting.

## 5. Apply the label
1. find-tasks with labels ["stale"], responsibleUserFiltering "all", limit 100 (page with the cursor). These are the currently flagged tasks.
2. Work out the difference and change only that:
   - Picked and not labeled: add `stale`.
   - Labeled and no longer stale (he touched it, gave it a future date, it went up-next, it's now out of scope) or labeled on a subtask rather than a tree root: remove `stale`.
   - Labeled and still picked: leave it alone.
3. Use update-tasks with only `id` and `labels`. `labels` replaces the task's whole label list, so always pass every existing label plus or minus `stale`. Never send content, description, due, deadline, priority, projectId, sectionId, or parentId: sending a project, section, or parent counts as a move, and changing the due date breaks recurrence.
4. Batch the updates. If some items fail, re-send only the failed ones once, then report anything still failing.

Running the job twice in one day must leave the same result.

## Hard rules
- The only write allowed is adding or removing the `stale` label. Never create, complete, delete, move, reschedule, comment on, or rename tasks.
- Never touch `@linear` tasks, recurring tasks, the Inbox, or the log task 6hprQ27W6mMHPXrh.
- Do not create the label or edit the "Still need these?" filter. Both already exist. If the `stale` label is missing, stop and report it.

## Summary
List the newly flagged tasks grouped by project, each with its one-line reason. Then give counts: labels added, labels removed (and why: touched, rescheduled, up-next), total now flagged, stale trees left unflagged by the caps, and any errors.