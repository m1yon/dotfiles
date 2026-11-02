---
name: "scheduled-job-suggest-up-next"
description: "Daily job that re-picks the top 2-3 tasks per Todoist project by deadline, priority and recent work, and tags them @up-next for the Up next filter. Used by the daily 8:14 AM scheduled task or run on demand."
---

# Suggest Up next (daily)

Each morning, choose the few tasks in each of Michael Lyon's Todoist projects that are most worth doing next, and make the `up-next` label point at exactly those tasks. His favorite filter "Up next" (query `@up-next`) shows the result. Assume no memory of earlier runs. Don't ask questions. End with a short summary.

## Context
- Michael Lyon, timezone America/Denver, Todoist user id 18992205. He has ADHD: a short, fresh, believable list beats a long one.
- Load tools with ToolSearch first: mcp__Todoist__find-tasks, mcp__Todoist__find-activity, mcp__Todoist__fetch-object, mcp__Todoist__update-tasks.
- Projects in scope (pick from these only):
  - Home & Family 6fpR3gJHfCJ8phg4
  - Money 6hhGx42xf79HXRV4
  - Core Project (his LLC) 6gf8RwrWXR94rM5c
  - MECA 6hhGx42gGrMJP7M9 (non-Linear tasks only)
  - Side Projects 6g747Frvj326c9VJ
- Out of scope: Inbox 6Crfv33JcgwhPGr2 (not yet accepted), Someday 6hpqFjWVMwxfRm39 (out of sight on purpose), and any project not listed above.

## 1. Gather candidates
Call find-tasks with filter `!#Inbox & !#Someday & !@waiting & !@linear & !recurring & !today & !overdue`, limit 100, and page with the cursor. Note: a grouped negation like `!(today | overdue)` silently returns nothing, so keep the two negations separate.

Drop a task when any of these is true:
- Its project is not one of the five in-scope projects.
- It has the label `routine` or `daily-ish`.
- It has a due date more than 2 days from today. Michael scheduled it on purpose, and some due dates are start dates (for example, enrollment that opens Nov 1).
- It is a parent task that has open subtasks. Consider the subtasks instead, so the pick is a concrete next step rather than an umbrella. The parent's priority and deadline carry down to its subtasks for scoring.

`@linear` tasks (Linear mirrors) and anything due today or overdue already show in the Today filter. That is why they are excluded here.

## 2. Read recent work
Call find-activity with objectType "task", initiatorId "18992205", dateFrom = 7 days ago (start of day, -06:00 or -07:00 offset), limit 100, and page with the cursor.
- completed events count from any client (he sometimes completes through Claude or ChatGPT).
- updated events count only when extraData.client starts with "Todoist" (his own apps). Updates from "Claude" or "ChatGPT" are automated description rewrites, not his work.
- From these events, build:
  - touchedTasks: task ids he updated in the last 7 days.
  - hotParents: parent task ids whose subtasks he completed or updated in the last 7 days (fetch-object on the completed task if its parentId is not in the event).

If find-activity fails, skip the recency factors and say so in the summary.

## 3. Score each candidate
Add up the points below. "Deadline" means the deadlineDate if there is one, otherwise a due date within 2 days.
- Deadline in 0-3 days: +6. In 4-7 days: +4. In 8-14 days: +2. In 15-30 days: +1.
- Priority p1: +4. p2: +3. p3: +1. p4: 0.
- Michael updated it in the last 7 days (in touchedTasks): +2.
- It is a subtask of a hotParent, or the next open subtask (lowest order) of a parent with a deadline or p1/p2: +2.
- It has the label `quick`: +1.
- It currently has the label `up-next` (continuity, so the list doesn't churn for no reason): +1.
- A tie breaks toward the newer task (later addedAt): fresher captures are more likely still relevant, and old untouched tasks belong in the weekly review, not here.

## 4. Pick
- In each project, take the top 2 by score.
- Take a 3rd only when it scores 5 or more (a real deadline or a high priority, not just recency).
- Only one task per parent: never pick two siblings from the same parent in the same project, unless both have their own deadline within 7 days.
- A project with no candidates gets no picks. Do not pad it.
- At most 12 picks in total. If there are more, drop the lowest-scoring 3rd picks first.

## 5. Apply the label
1. find-tasks with labels ["up-next"], responsibleUserFiltering "all", limit 100 (page with the cursor). These are the currently suggested tasks.
2. Work out the difference between the current set and the new picks, and change only that:
   - Picked and not yet labeled: add `up-next`.
   - Labeled and not picked: remove `up-next`.
   - Labeled and picked: leave it alone.
3. Use update-tasks with only `id` and `labels`. `labels` replaces the task's whole label list, so always pass every existing label plus or minus `up-next`. Never send content, description, due, deadline, priority, projectId, sectionId, or parentId: sending a project, section, or parent counts as a move, and changing the due date breaks recurrence.
4. Batch the updates. If some items fail, re-send only the failed ones once, then report anything still failing.

Running the job twice in one day must leave the same result. Never add a second label, and never create, complete, move, reschedule, or comment on tasks.

## Hard rules
- The only write allowed is adding or removing the `up-next` label. Nothing else in Todoist changes.
- Never touch `@linear` tasks, the Inbox, Someday, or the Inbox assistant log task 6hprQ27W6mMHPXrh.
- Do not create the label or edit the "Up next" filter. Both already exist. If the `up-next` label is missing, stop and report it.

## Summary
List the picks grouped by project, each with a one-line reason (for example, "deadline Oct 26, p4", "p2, worked on Tue", "next step of Catholic convalidation"). Then give counts of labels added and removed, any projects with no candidates, and any errors.