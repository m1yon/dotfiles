---
name: group-tasks-into-projects
description: Groups loose top-level tasks at the root of the MECA and Side Projects Todoist projects into effort projects. Moves a task into an existing child project it plainly belongs to, and proposes new projects in one Inbox review task. Applies approved proposals when Michael asks. Use for the weekly scheduled run, "group my tasks", or "apply project ideas".
---

# Group tasks into projects

Michael organizes Todoist by effort, not by repo. An effort is one outcome, such as a report change or a pipeline fix, and it can span several repos. Agents already file new tasks into an effort's project when one exists (the Work tracking rules in the global `AGENTS.md`). This skill handles what still lands at the root of `MECA` or `Side Projects`: Michael's own captures, the orchestrator's cards for unlinked PRs, and agent tasks whose effort had no project yet.

Run **Propose** unless Michael asks to apply ideas, then run **Apply**. Use the `td` CLI, plus read-only `gh pr view` for the cards described below. Write every task ref as `id:<id>`. Every `td ... --json` list prints `{"results": [...], "nextCursor": ...}` and holds only open items. Propose asks no questions and ends with the summary.

## Read the board

1. Run `td project list --json --all`. The roots are `MECA` and `Side Projects`. Their effort projects are the projects whose `parentId` is a root.
2. For each root, run `td task list --project <root> --json --all`. It lists the root's own tasks, not its child projects' tasks. The list is flat, so it holds subtasks too. The candidates are the tasks with `parentId` null. Drop a recurring task (`due.isRecurring` is true), a task with the label `linear`, a task whose id is another row's `parentId` (it already holds its own effort), and a task whose `id:<id>` appears in an open `Review project ideas` task or its comments.
3. A candidate with an empty description is usually the orchestrator's card for an unlinked PR. Read its `PR: <url>` comment with `td comment list id:<id> --json` and run `gh pr view <url> --json title,body`. Never run another `gh` command. With no description and no `PR:` comment, judge the task by its title.
4. For each effort project, read its description with `td project view id:<id> --json`, and its tasks with `td task list --project id:<id> --json --all`, to learn what the effort covers. When both are empty, judge from the project's name.

## Propose

1. **Move tasks into existing effort projects.** Move a candidate only when its title and description show that it is a step of that effort. When in doubt, leave it. Keep its column: `td task move id:<id> --project id:<effort project> --section "<name of its current section>"`. Look up that name with `td section list --project <root> --json`. Leave out `--section` when the task has no section or the effort project has no section of that name. Read the task back with `td task view id:<id> --json`, and check its `projectId` and `sectionId`.
2. **Group the rest.** Group the remaining candidates by the outcome they serve. Repos never decide a group, so one group can hold data-lake-sql and pearsuite-api-svc tasks. Propose a new project for a group of two or more tasks, or for one task whose description says its effort deserves its own project. Name it after the outcome in a few words.
3. **Write the proposals.** Look for an open Inbox task whose title starts with `Review project ideas`. If one exists, add one comment with the new proposals, numbered after its last number, and leave its title alone. Otherwise create it with `td task add "Review project ideas (<number of proposals>)" --project Inbox --labels from-agent --description "<lines>"`. Write one line per proposal, such as `1. New project "BCBS compliance report" under MECA: id:<a> (<title>), id:<b> (<title>). <One-sentence reason.>` Never copy a member's name or ID into a line. Keep the task's `id:<id>` and describe it in other words instead. End the description with `To apply, tell an agent "apply project ideas" and name the numbers.` Create nothing when there is no proposal.

## Apply

Apply only the numbers Michael approves. His approval is his permission to create those projects.

1. Read the review task with `td task view id:<id> --json --full` and its comments with `td comment list id:<id> --all --json`.
2. For each approved proposal, run `td project create --name "<name>" --parent <root> --view-style board --json`. Under `MECA`, create the sections `Todo`, `In Progress` and `Blocked` with `td section create --name "<section>" --project id:<new project>`. The orchestrator moves tasks between those sections by name. A project under `Side Projects` gets no sections, like its root.
3. Move each listed task that is still open and still at its root, as in Propose step 1.
4. Comment on the review task with what you applied. Complete the review task once every proposal in it is applied or declined.

## Rules

- Propose creates, renames and deletes no project or section. Its only writes are moves of root tasks into existing effort projects and the one review task with its comments.
- Never move a subtask. A parent's subtasks move with it.
- Never touch Inbox tasks other than the review task, and never touch tasks with the label `linear`.

## Summary

List each move as the task title and its new project, then each new proposal with its number, then any errors. Say "Nothing to group" when nothing qualified.
