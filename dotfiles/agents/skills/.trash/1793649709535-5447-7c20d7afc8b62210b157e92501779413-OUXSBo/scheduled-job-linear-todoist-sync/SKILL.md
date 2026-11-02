---
name: "scheduled-job-linear-todoist-sync"
description: "Two-way sync between Michael's Linear issues and their Todoist mirrors on the MECA board: creates Linear issues from new linear-labeled MECA tasks and Linear projects from new MECA child projects, plus status, completion, due date, description, comments. Used by the hourly weekday scheduled task or on demand."
---

# Linear ⇄ Todoist sync

Run an unattended, idempotent two-way sync between Michael Lyon's Linear work and a Todoist mirror of it. The Todoist MECA project is a board whose columns are Linear statuses: moving a card between columns changes the issue's status in Linear, and a status change in Linear moves the card. An issue in a Linear project mirrors into a child project of MECA named after that Linear project, with the same columns; an issue with no Linear project mirrors into MECA itself. Each mirror also carries the issue's due date (as the Todoist due date), full description, and comment thread, and edits on either side flow to the other. New work can start on either side: an issue Michael creates in Linear gets a mirror, and a task Michael creates in the MECA family with the `linear` label (and no MEC-### prefix yet) becomes a new Linear issue and is renamed into its mirror (step 2b). A child project Michael creates under MECA becomes a Linear project and gets the board columns ("Project boards" item 3). MECA also holds Michael's own non-Linear tasks (no `linear` label); they use the same columns but never touch Linear, and the sync only sweeps column-less ones into Todo (step 10). Assume no memory of earlier runs; everything you need is here. Do not ask questions. Do not touch email, Teams, or any Todoist task outside the MECA family (MECA and its child projects).

## Hard rules
- The ONLY writes you may make to Linear (issue writes only on issues assigned to Michael):
  (a) status: to the column Michael moved the mirror into (step 4), or to the team's completed state when he checked the mirror off (step 3);
  (b) description: Michael's Todoist description edits (step 6), applied with `patch`;
  (c) comments: create a comment copying one Michael wrote in Todoist, or edit a comment the sync itself created (its body ends with a `td:` footer) (step 8);
  (d) due date: the due date Michael set, changed, or removed on the mirror in Todoist (step 5);
  (e) create: one new MEC issue, assigned to Michael, for each new `linear`-labeled Todoist task, exactly as step 2b says;
  (f) create project: one new MEC project, led by Michael, for each unlinked MECA child project, exactly as "Project boards" item 3 says.
  Never change any other Linear field. Never edit or delete anyone else's Linear comment. Never cancel or reassign Linear issues, and never create one except in step 2b. Never update, archive, or delete a Linear project.
- Never delete Todoist tasks or comments. Never reopen (uncomplete) Todoist tasks.
- Never change a mirror's title, deadline, order, or any label other than `linear` and `waiting`, except the one-time conversion of a new task into a mirror in step 2b. Preserve every other label the user added. Change a mirror's section and project only as steps 2b, 4 and 7 say, and its due date only as steps 5 and 7 say. The Todoist deadline field is not synced; leave it alone.
- Never write the Linear project of an existing issue. Project placement flows from Linear to Todoist only. The single exception is step 2b, which sets the project of the issue it creates from the board the task was created on.
- Create, rename, or describe Todoist projects, change their view, and create sections only as "Project boards" says. Never delete, archive, unarchive, or move a Todoist project, and never delete, rename, or reorder a section.
- Never nest mirrors as subtasks. A subtask cannot sit in a different column from its parent, so every mirror is top level.
- Never push a Todoist comment to Linear unless its "added" activity event exists and its client is not "Claude" (step 8). Comments from the assistant jobs (triage, this sync) stay in Todoist.
- Tasks without the `linear` label never touch Linear. The ONLY change you may make to one is step 10: moving a top-level MECA family task with no section into its own project's Todo column.
- If anything looks ambiguous or unsafe, skip that item and report it in the summary instead of guessing. When in doubt, do NOT change Linear.

## Tools
Load with ToolSearch first: mcp__Linear__list_issues, mcp__Linear__get_issue, mcp__Linear__list_issue_statuses, mcp__Linear__save_issue, mcp__Linear__list_comments, mcp__Linear__save_comment, mcp__Linear__get_project, mcp__Linear__list_projects, mcp__Linear__save_project, mcp__Todoist__find-projects, mcp__Todoist__add-projects, mcp__Todoist__update-projects, mcp__Todoist__add-sections, mcp__Todoist__find-tasks, mcp__Todoist__find-completed-tasks, mcp__Todoist__find-comments, mcp__Todoist__find-sections, mcp__Todoist__find-activity, mcp__Todoist__add-tasks, mcp__Todoist__update-tasks, mcp__Todoist__reschedule-tasks, mcp__Todoist__complete-tasks, mcp__Todoist__add-comments, mcp__Todoist__update-comments.

## Context
- User: Michael Lyon, timezone America/Denver. Linear workspace "meca-therapies", issues are MEC-###.
- Todoist project MECA, id 6hhGx42gGrMJP7M9, board view. The MECA family is MECA plus its active (non-archived) child projects. All mirrors live in the MECA family.
- A mirror's home H is the project board for its issue's Linear project, or MECA itself when the issue has no Linear project.
- Labels: `linear` marks a mirror, or a new task Michael wants created in Linear (a `linear` task whose title has no MEC-### prefix yet; step 2b); `waiting` marks a mirror in the Blocked column (the "Waiting on" filter uses it, and the Today filter hides it).
- The boards have no "no section" column by design: every MECA family task belongs in a column, and Todo is the default (a new `linear` task due today or earlier starts in In Progress instead; step 2b).
- The Today filter shows MECA family tasks in an In Progress column (plus non-Linear tasks due today or overdue), so column accuracy matters. It queries `##MECA`, which includes the project boards.
- Every comment you add in Todoist uses notifyUsers ["none"].

## Board columns ⇄ Linear statuses (MEC team)
Section ids below are MECA's own. Every project board has columns with the same names and its own section ids.

| Todoist section | MECA section id | Linear state id |
|---|---|---|
| Todo | 6hq4mHmh4rpJRMR9 | 3936c76b-e83e-4956-a17e-2601478ec9e3 |
| In Progress | 6hq4mHp67rGCFfgh | 46d112fe-0d6f-4433-a044-7894ac4ac045 |
| In Review | 6hq4mHpjf2X2fF7h | 971b1c36-d6e1-4cd6-8fc7-7e0571507b28 |
| Blocked | 6hq4mHp6Vp2pR7rh | 4395df6e-3ae9-4d44-b3bb-9bd3772fcde8 |

MEC completed state: "Completed" (3e3d36fd-b367-4e3f-9a4f-42f72bbdb6de). Completion is a checkoff, not a column.

At the start of the run, call mcp__Todoist__find-sections for every project in the MECA family and match columns by NAME (MECA's ids above are a fast path; if one is missing or renamed, use what the names say and report it). "X's column" in the steps below always means the column named X in the mirror's home H. For an issue on another team, call mcp__Linear__list_issue_statuses for that team and match by status name; if that team's status has no column with the same name, create new mirrors in H's Todo, skip status sync (step 4a–f) for that mirror while its status stays unmatched (never push its column to Linear), and report it.

To move a card, call update-tasks with id and sectionId only. A sectionId in another project moves the task into that project too. Never send projectId with it.

## Project boards
A project board is a child project of MECA that holds the mirrors of one Linear project.
- Name: the Linear project's name, exactly.
- Description: "[Linear project](<Linear project url>) · lp:<Linear project id>". The `lp:` id is the link between the two. Never remove it.
- Board view, color charcoal, columns Todo, In Progress, In Review, Blocked.

Run this in step 2, after reading Linear. Let P = the distinct Linear project ids of the IN-SCOPE issues, each with the project name from the issues' `project` field.
1. mcp__Todoist__find-projects with archivedStatus "all", limit 200. The MECA family is MECA plus the active projects whose parentId is 6hhGx42gGrMJP7M9. Map each family project whose description holds `lp:<id>` to that id. Two active projects with one `lp:` id: use neither, report it, and treat those issues as having no board this run.
2. For each id in P with no board, call mcp__Linear__get_project for its url.
   - An active MECA child whose name equals the Linear project name and has no `lp:` id: adopt it. update-projects its description to the convention, keeping any existing description text above the line.
   - An archived project whose description holds that `lp:` id (archived results may omit parentId, so match on the id alone): someone archived it on purpose. Do not unarchive or recreate it. Treat those issues as having no board (home = MECA) and report it.
   - Otherwise create it: mcp__Todoist__add-projects with name, parentId 6hhGx42gGrMJP7M9, viewStyle "board", color "charcoal", and the description. Then mcp__Todoist__add-sections with Todo, In Progress, In Review, Blocked, one call per section in that order so the columns line up.
   If get_project or a create fails, report it, treat those issues as having no board this run, and let the next run retry.
3. **Unlinked boards.** An active MECA child project whose description still has no `lp:` id after items 1 and 2 is a board Michael started in Todoist. For each one, oldest first:
   a. mcp__Linear__list_projects with query = its trimmed name, includeArchived false, fields [id,uuid,name,url]. Keep only results whose name equals that trimmed name exactly.
   b. Exactly one match: link to it. More than one: skip the board and report "<name> matches several Linear projects; add its lp: line by hand". None: create it with mcp__Linear__save_project: name = the trimmed name, addTeams ["MEC"], lead "me", state "planned", description "_Created from Todoist · tp:<Todoist project id>_". If the create fails, report it and let the next run retry. A run that stops after the create but before the link is safe: the next run finds the project by name in (a) and links it.
   c. To link, update-projects the Todoist project's description to the convention, using the Linear project's `uuid` (not its P-MEC-## id) as the `lp:` id and keeping any existing description text above the line. Map the board to that id.
4. For each board you map: if its viewStyle is not "board", set it to "board" (update-projects). Call find-sections, and add any of the four columns it is missing (add-sections, one call per column in table order) and report it. Never touch other sections on it.
5. If a board in P has a name that differs from its Linear project's name, rename it (update-projects name). This is the only project rename allowed.

Boards are never deleted or archived. A board with no open tasks stays, listed as empty in the summary so Michael can archive it.

update-projects requires `color`. Send the project's current color so the call changes nothing else.

## Comment markers
Written on Todoist mirror tasks by the sync. They are never copied to Linear.
- "Completed by Linear sync: ..." — the sync completed the mirror because Linear closed the issue.
- "Left mirror scope in Linear" — the sync completed the mirror because the issue left scope.
- "Closed in Linear by sync" — the user completed the mirror in Todoist and the sync then closed the Linear issue.
- "Not closed in Linear: ..." — the sync deliberately did not close the Linear issue for a hand-completed mirror (reason follows). Do not retry it.
- "Status conflict: ..." — informational (step 4f); no effect on later runs.
- "Due date conflict: ..." — informational (step 5f); no effect on later runs.
- "Linear sync: ..." — informational (description conflicts, migrated notes, issues created from Todoist).

A completed mirror with any of the first four markers needs no further action.

## Mirror convention
- Title: "MEC-### <exact Linear title>"
- Description = metadata line, then a blank line, then the body (omit the blank line and body when the body is empty).
- Metadata line: "[Linear](<issue url>) · <Linear status name>", then " · <Urgent|High>" only when Linear priority is Urgent or High, then " · ↳ MEC-###" when the issue has a Linear parent, then " · due YYYY-MM-DD" or " · no due", then " · synced <stamp>". Example: "[Linear](https://linear.app/meca-therapies/issue/MEC-868/persist-roster-problem) · In Progress · ↳ MEC-819 · due 2026-10-30 · synced 2026-10-22T16:07Z".
  - **The status in that line is the last-synced status** (R in step 4): the second " · "-separated segment.
  - **The due segment is the last-synced due date** (D in step 5): the segment just before the stamp, "due YYYY-MM-DD" or "no due". A metadata line with neither predates due date sync; treat it as D = none.
  - **The stamp S is when the sync last wrote the description**, UTC to the minute. It is always the last segment. Set it to the current UTC minute every time you write a description and at no other time. A missing stamp means the mirror predates description sync (step 6a).
- Body = render(Linear description):
  - Replace every `<tag ... href="URL" ...>TEXT</tag>` (issue, user, document, project mentions) with `[TEXT](URL)`; a tag without href becomes just TEXT.
  - Keep everything else verbatim. An empty Linear description renders as an empty body.
  - If the rendered body is longer than 15,000 characters, cut it at the last paragraph break before 15,000 and add a final line "_…truncated. Full description in [Linear](<issue url>)._" A truncated body is read-only: never push Todoist edits from it (step 6).
- Project: its home H. Section: H's column whose name equals the Linear status.
- Due date: the Linear due date as a date-only Todoist due date (dueString "YYYY-MM-DD"), or none when Linear has none.
- Labels: `linear`; plus `waiting` when the status is "Blocked".
- Priority: Linear Urgent (1) or High (2) maps to Todoist "p2"; anything else maps to "p4".
- Always top level (no parentId).
- update-tasks replaces the whole description, so any description write sends the metadata line plus the full current body. Make at most ONE description write per mirror per run: apply every metadata and body change for a mirror in a single update.

## Comment convention
A comment pair links a comment to its copy on the other side. The footer is the link; never remove it.
- **Linear → Todoist copy** content:
  "**<author display name>** in Linear · <created time, America/Denver, YYYY-MM-DD HH:MM>"
  then, for a reply, "↪ reply to <parent comment author>"; for an inline description comment, "> <quotedText>";
  then a blank line and the rendered body (same rendering as descriptions; list any attachments as "(attachment: <title>, open in Linear)"; never paste signed download URLs);
  then a blank line and the footer "[Linear](<issue url>) · lc:<Linear comment id> · v<Linear comment updatedAt>".
  Cut the body so the whole comment stays under 14,000 characters, ending the cut with "…truncated, see Linear".
- **Todoist → Linear copy** body: Michael's comment text verbatim (note any file attachment as "(attachment in Todoist: <file name>)"), then a blank line and the footer "_via Todoist · td:<Todoist comment id>_".
- The side that has no footer is the origin. Edits sync from origin to copy only; an edit made to a copy is overwritten. Deletions are not synced.

## Scope
Which Linear issues should have an open mirror: every issue assigned to "me" whose statusType is
- (a) "started" (In Progress, In Review, Blocked, or any other started status), or
- (b) "unstarted" (Todo), regardless of priority, due date, estimate, cycle, or project.

Everything else is out of scope: Backlog (statusType "backlog"), Triage, completed, canceled, and anything not assigned to Michael.

## Steps
1. **Read Todoist completed mirrors.** First find the MECA family ("Project boards" item 1). Then, for each family project, mcp__Todoist__find-completed-tasks with that projectId, labels ["linear"], since = today minus 30 days, until = now (page with cursor). Key each by the MEC-### prefix at the start of its title (regex ^MEC-\d+). Ignore completed `linear` tasks with no prefix (never-promoted tasks; they are not mirrors). For each keyed one, fetch its comments (mcp__Todoist__find-comments) and note any marker above.

2. **Read Linear, Todoist open mirrors, and Todoist activity.**
   - mcp__Linear__list_issues with assignee "me", state "started", limit 100, fields [id,title,url,priority,status,statusType,parentId,team,updatedAt,dueDate,project,projectId]. Then the same with state "unstarted". Follow cursors while hasNextPage is true.
   - mcp__Todoist__find-tasks with filter "##MECA", labels ["linear"], responsibleUserFiltering "all", limit 100 (page with cursor). This covers MECA and every child project. Key by MEC-### prefix. Note each mirror's projectId and sectionId. If two open mirrors share one key, do not modify either; report it and leave that key out of every later step. Open tasks whose title has no MEC-### prefix are NEW TASKS for step 2b, not mirrors.
   - IN-SCOPE set = started issues ∪ unstarted issues (all priorities, including No priority).
   - Set up project boards ("Project boards" items 1 to 5; items 1 and 3 also map the boards new tasks sit on), then find-sections for every family project. Each in-scope issue's home H is now known.
   - For each family project, mcp__Todoist__find-activity with that projectId, objectType "task", eventType "updated", dateFrom = the earliest stamp S among open mirrors (or 30 days ago if none has a stamp or it is older), limit 100 (page with cursor). Keep only events on open mirror ids whose extraData has both `description` and `lastDescription`. These are DESCRIPTION EVENTS.
   - For each family project, mcp__Todoist__find-activity with that projectId, objectType "comment", eventType "added", dateFrom = 30 days ago, limit 100 (page with cursor). Map comment id (objectId) → client and task id (parentItemId). These are COMMENT EVENTS.
   If the task activity read fails, step 6 only applies pending metadata changes from steps 4 and 5 (metadata + current body, old stamp kept) and does nothing else. If the comment activity read fails, skip step 8b. Report either failure; everything else still runs.

2b. **Todoist → Linear: create issues for new tasks.** For each NEW TASK from step 2 (open, `linear` label, title not starting with MEC-###), oldest first, at most 20 per run (report how many are left):
   a. **Shape checks.** If it has a parentId (subtask), skip it and report "make it a top-level task to send it to Linear". If its title is empty after trimming, skip and report.
   b. **Linear project.** If the task is in MECA itself, the issue gets no project. If it is on a board mapped to an `lp:` id ("Project boards" items 1 and 3), the issue gets that project. If it is in a family project with no usable `lp:` mapping (none, or a duplicate id), skip it and report.
   c. **Status.** The task's column name in its project, matched to the MEC status of the same name (table above). No column means In Progress when the task's due date (date part, America/Denver, recurring or not) is today or earlier, and Todo otherwise, including when it has no due date. A column name with no matching MEC status: skip and report.
   d. **Interrupted-run guard.** mcp__Linear__list_issues with assignee "me", query = the trimmed task title, includeArchived true, limit 25. If any result's description contains `tt:<this task's id>`, a previous run already created the issue but did not finish: do not create another; use that issue for f.
   e. **Create.** mcp__Linear__save_issue with team "MEC", assignee "me", title = the trimmed task title, state = the status from c (by state id), project = the id from b when there is one, priority = 1 (Urgent) for Todoist p1, 2 (High) for p2, 0 otherwise, dueDate = the task's due date (date part, America/Denver) when it has one and is not recurring (a recurring due date is not sent; report it), and description = the task's Todoist description verbatim, then a blank line, then "_Created from Todoist · tt:<task id>_" (just the footer when the Todoist description is empty). Then get_issue (fields identifier,url,title,status,statusType,priority,dueDate,description,updatedAt,projectId,parentId) to confirm it exists with the right status. On failure, change nothing in Todoist, report it, and let the next run retry (the guard in d prevents a duplicate).
   f. **Turn the task into its mirror** with one update-tasks call: content = "MEC-### <Linear title>", description = the metadata line (status, Urgent/High, due segment from the Linear dueDate, fresh stamp) + blank line + render(Linear description), labels = the task's current labels plus `waiting` if the status is Blocked, and sectionId = H's column for the status from c, only if the task had no column. Leave its priority and due date as they are. Then add the Todoist comment "Linear sync: created MEC-### in Linear from this task".
   g. Add the issue to the IN-SCOPE set and the task to the open mirrors under its new key, so steps 4–8 handle it like any mirror (step 8 copies Michael's existing comments on the task to Linear).

3. **Todoist → Linear: close issues Michael checked off.** For each completed mirror from step 1 that has NO marker:
   a. Call mcp__Linear__get_issue (fields id,status,statusType,assignee,team,parentId,completedAt,canceledAt).
   b. If the issue is already completed or canceled in Linear: add Todoist comment "Closed in Linear by sync (already <status> in Linear)" and move on.
   c. Legacy cascade check: if this mirror was a Todoist subtask (it had a parentId) AND its parent mirror was also completed by hand with a completedAt within 2 minutes of this one, do NOT close it in Linear; add comment "Not closed in Linear: completed together with its parent mirror; close it in Linear yourself if it is done" and report it.
   d. If the issue is not assigned to Michael, or get_issue fails: do NOT close it; add comment "Not closed in Linear: <reason>" and report it.
   e. Otherwise close it: mcp__Linear__save_issue with id = the MEC-### identifier and state = the team's completed state (for MEC: "Completed"). Verify with get_issue that statusType is now "completed". On success, add comment "Closed in Linear by sync (moved to Completed)". On failure, add no marker (so the next run retries) and report the error.

   Remove any issue closed in this step from the IN-SCOPE set.

4. **Status sync for open mirrors** (three-way merge). For each open mirror whose key is IN-SCOPE, compare three values:
   - R = the status recorded in its metadata line (last synced),
   - T = the name of the column it sits in now, in whatever family project holds it (or "none" if it has no section),
   - L = the issue's current Linear status name.

   a. **T = R and L = R**: nothing to do for status.
   b. **T = none** (card dragged to the no-section column, or a legacy mirror): move it to L's column. Set R := L. Never write Linear for this case.
   c. **T = R, L ≠ R** (changed in Linear): move the card to L's column (update-tasks sectionId). Set R := L.
   d. **T ≠ R, L = R** (Michael moved the card): if the issue is assigned to Michael, mcp__Linear__save_issue with id = MEC-### and state = T's Linear state (by id for MEC, by name for other teams). Verify with get_issue that the status is now T. On success set R := T. On failure, leave the card where it is, keep R unchanged (next run retries), and report it.
   e. **T ≠ R, L ≠ R, T = L** (both sides agree): set R := L.
   f. **T ≠ R, L ≠ R, T ≠ L** (both sides changed differently): Linear wins. Move the card to L's column, set R := L, add comment "Status conflict: Linear moved this to <L>, so your move to <T> was not applied" and report it.
   g. Then reconcile the rest of the metadata line and labels with Linear: the line needs rewriting if R changed, or the Urgent/High text or the "↳" parent text differs from Linear. Do not write the description yet; carry the pending metadata change into step 6, which makes the single description write. Set priority to the mapped value only if the Urgent/High bucket actually changed versus what was recorded. Add or remove `waiting` only when the card entered or left the Blocked column. Pass the full label list so other labels survive.
   h. If the mirror has a Todoist parentId (legacy subtask), move it to its column (sectionId lifts it to the top level) and add " · ↳ MEC-###" to its metadata line (via step 6).
   i. If nothing recorded differs, change nothing, even if the user edited priority or labels by hand.
   j. If the Linear title differs from the mirror title, do not rename it; just report it.
   k. **Project placement.** After a–h, the card belongs in H's column named R. If it is not there, move it with one update-tasks call (sectionId of H's column R). Fold any move from b, c, f, or h into this same call, so each mirror moves at most once. This is how an issue that joins, leaves, or changes Linear project follows it, how mirrors from before project boards reach their board, and how a card dragged to another board goes back (Linear's project always wins). Report each project move as "MEC-###: <old project> → <H>". Never write the project to Linear.

5. **Due date sync for open in-scope mirrors** (three-way merge). For each open mirror whose key is IN-SCOPE, compare three dates (each "YYYY-MM-DD" or none):
   - D = the due date recorded in its metadata line (last synced; none for "no due" or a line with no due segment),
   - T = the mirror's Todoist due date: its `dueDate` from step 2, date part only (a timed due date counts as its date in America/Denver), or none when it has no due date,
   - L = the issue's Linear `dueDate` from step 2, or none.

   If the mirror is a recurring Todoist task, skip this step for it (a Linear due date cannot hold a recurrence) and report it.
   a. **T = D and L = D**: nothing to do.
   b. **T = D, L ≠ D** (changed in Linear): set the Todoist due date to L (see "Writing the Todoist due date" below). Set D := L.
   c. **T ≠ D, L = D** (Michael changed it in Todoist): if the issue is assigned to Michael, mcp__Linear__save_issue with id = MEC-### and dueDate = T (or null when T is none). Verify with get_issue (fields dueDate) that it now equals T. On success set D := T. On failure, leave the Todoist date as is, keep D unchanged (next run retries), and report it.
   d. **T ≠ D, L ≠ D, T = L** (both sides agree): set D := L.
   e. A mirror whose line has no due segment and whose T and L differ follows the cases above with D = none, so a date on one side only is copied to the other side.
   f. **T ≠ D, L ≠ D, T ≠ L** (both sides changed differently): Linear wins. Set the Todoist due date to L, set D := L, add comment "Due date conflict: Linear has <L, or no due date>, so your Todoist due date <T, or removal> was not applied" and report it.
   g. If D changed, or the line has no due segment yet, the metadata line needs rewriting. Do not write the description here; carry the pending metadata change into step 6, which makes the single description write.

   Writing the Todoist due date (never send dueString with a recurrence, and never touch deadlineDate):
   - L is none: update-tasks with id and dueString "remove".
   - The mirror has no due date: update-tasks with id and dueString = L.
   - The mirror has a due date: mcp__Todoist__reschedule-tasks with id and date = L (it keeps any time of day already set).
   If the write fails, keep D unchanged and report it.

6. **Description sync for open in-scope mirrors.** Let B_T = the mirror's current body (everything after the metadata line and blank line), S = its stamp.
   a. **No stamp (legacy mirror).** Call get_issue (fields description,updatedAt,assignee). If B_T is empty or equals render(L), write metadata + render(L). Otherwise keep Linear: add comment "Linear sync: notes moved here from the description when description sync started:" followed by B_T, then write metadata + render(L). Never push a legacy body to Linear.
   b. **Did Michael edit it in Todoist?** Look at this mirror's DESCRIPTION EVENTS with eventDate after S. An event is a Todoist edit when its `description` and `lastDescription` have the same metadata line (same stamp) and different bodies. Sync writes always change the stamp, so they never qualify. If any qualify: todoistChanged = true, and the base B = the body of `lastDescription` on the EARLIEST qualifying event.
      Otherwise todoistChanged = false and B = B_T.
   c. **Did Linear change?** If the issue's updatedAt (from step 2, or refreshed after a step 2b, 4 or 5 write) is at or before S, linearChanged = false and skip the fetch. Otherwise call get_issue (fields description,updatedAt,assignee) and set linearChanged = (render(L) ≠ B).
   d. Decide:
      - **Neither changed:** no body change. If step 4 or 5 left a pending metadata change, write metadata + B_T with a fresh stamp.
      - **Linear only:** write metadata + render(L) with a fresh stamp.
      - **Todoist only:** push it unless B_T is truncated (ends with the truncation line) or the issue is not assigned to Michael; then do not push, report it, and leave the mirror as is (apply any pending metadata change with B_T and keep the old stamp so the edit is detected again next run). To push: call mcp__Linear__save_issue with id and `patch` holding one "replace" op per changed passage, each old_string copied exactly from Linear's raw description (with its tags) and long enough to match once; use "append"/"prepend" for pure additions, and the full `description` field only when Linear's description is empty. Then get_issue again and confirm render(new L) contains Michael's edit. On success write metadata + render(new L) with a fresh stamp. On failure (patch rejected, edit missing) change nothing in Todoist, report it, and let the next run retry.
      - **Both changed:** if B_T = render(L), just restamp (write metadata + B_T). Otherwise Linear wins: add comment "Linear sync: description conflict. Linear's version replaced your Todoist edit. Your version was:" followed by B_T, write metadata + render(L) with a fresh stamp, and report it.
   e. Compare bodies ignoring trailing whitespace and line-ending differences only. Everything else counts as a change.

7. **Create missing mirrors**, for each IN-SCOPE issue with no open mirror:
   - If a completed mirror from step 1 has marker "Not closed in Linear": do NOT create a new mirror; list it in the summary as still open in Linear.
   - Otherwise (no mirror, or completed with "Completed by Linear sync" / "Left mirror scope in Linear" because it came back into scope): get_issue for its description, then create one with mcp__Todoist__add-tasks per the convention (metadata line with its due segment and a fresh stamp + render(L)), with sectionId = H's column for its Linear status (no projectId needed), and dueString = its Linear due date ("YYYY-MM-DD") when it has one. Include it in step 8.

8. **Comment sync for open in-scope mirrors.** For each mirror, read all Linear comments (mcp__Linear__list_comments with issueId, orderBy createdAt, limit 250, follow cursors) and all Todoist comments (mcp__Todoist__find-comments with taskId, page with cursor). Build the pairs from footers: a Todoist comment with `lc:<id>` pairs with that Linear comment; a Linear comment with `td:<id>` pairs with that Todoist comment.
   a. **Linear → Todoist, new.** For each Linear comment with no `td:` footer and no Todoist copy: add-comments with the Linear → Todoist format. Oldest first.
   b. **Todoist → Linear, new.** For each Todoist comment with no `lc:` footer, no marker prefix, and no Linear copy: push it ONLY if its COMMENT EVENT exists and the client does not contain "Claude", and the issue is assigned to Michael. Push with mcp__Linear__save_comment (issueId = MEC-###, body = Todoist → Linear format). Count the rest as skipped; do not report them one by one.
   c. **Edits, origin wins.** For a Linear-origin pair, if the Linear comment's updatedAt differs from the copy's `v<...>` value, update-comments the Todoist copy with fresh content. For a Todoist-origin pair, if the Todoist text differs from the Linear copy's body without its footer, save_comment with id = the Linear copy's id and the fresh body. Never edit a Linear comment that has no `td:` footer.
   d. Make at most 40 new comment copies per run across all mirrors, oldest first. Report how many are left; the next run continues.
   e. If a write fails, report it and move on; the missing footer link makes the next run retry it.

9. **Close out-of-scope mirrors.** For each OPEN mirror whose key is NOT in the IN-SCOPE set: call mcp__Linear__get_issue (fields id,status,statusType,assignee).
   - statusType "completed" or "canceled": add comment "Completed by Linear sync: issue is <status> in Linear" then complete the task.
   - Otherwise (unassigned, reassigned, or moved to Backlog/Triage): add comment "Left mirror scope in Linear" then complete the task. Never delete.
   - If get_issue fails or the issue is not found: change nothing and report it.
   New tasks skipped in step 2b have no key and are never closed here.

10. **Sweep column-less MECA family tasks into Todo.** mcp__Todoist__find-tasks with filter "##MECA", responsibleUserFiltering "all", limit 100 (page with cursor). For every open task that has no sectionId, no parentId, and no `linear` label, move it to the Todo column of the project it is already in (update-tasks with only id and sectionId; batch up to 25). Change nothing else on these tasks. Skip subtasks: they follow their parent's column. (Column-less `linear` mirrors were already placed in steps 2b and 4b.)

11. **Summary.** Finish with a short plain-text run summary: Linear issues created from Todoist tasks (MEC id: task title) and new tasks skipped (with reason) or left for the next run, project boards created, adopted, renamed, switched to board view, or given missing columns, Linear projects created from Todoist boards and Todoist boards linked to an existing Linear project by name, boards skipped for matching several Linear projects, boards skipped as archived, empty boards, mirrors moved between projects (MEC id: from → to), tasks swept into Todo, status changes pushed to Linear (MEC id: from → to), cards moved because Linear changed, due dates pushed to Linear and pulled into Todoist (MEC id: from → to), recurring mirrors skipped for due dates, conflicts (status, due date, and description), MEC ids closed in Linear from Todoist checkoffs, descriptions pulled from Linear, description edits pushed to Linear, truncated descriptions, comments copied each way (counts per MEC id) and comment edits synced, comments skipped as assistant-written (count), comments left for the next run, mirrors created, updated (with what changed), completed (with reason), title drift, duplicates, and errors. If nothing changed, say "No changes" plus the count of in-scope issues checked.