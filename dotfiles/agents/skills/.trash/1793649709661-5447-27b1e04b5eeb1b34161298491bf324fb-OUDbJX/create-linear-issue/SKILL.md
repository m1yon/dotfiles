---
name: "create-linear-issue"
description: "Use whenever creating a Linear issue for Michael: defaults the status to Todo and always assigns the issue to him."
---

# Create Linear Issue

Follow these defaults every time you create a Linear issue (`save_issue` without an `id`).

## Defaults

- **Assignee:** always `me` (Michael Lyon, michael.lyon@mecatherapies.com). Do this even when the request doesn't mention an assignee.
- **Status:** `Todo`, unless Michael names another status (for example Backlog, In Progress, or Triage). If the team has no status called `Todo`, use its status of type `unstarted`.
- **Team:** use the team Michael names. If he doesn't name one, use MECA Therapies for work items and Personal for personal or side-project items. Ask only if it's unclear which applies.
- **Priority and due date:** set them only when Michael gives them. Linear's numbers are 1 Urgent, 2 High, 3 Medium, 4 Low. "Priority two" or "P2" means 2.

## Steps

1. If Michael points to context (emails, meetings, prior chats), gather it first and use it to write the description.
2. Write a short, specific title.
3. Write a brief Markdown description: what is being asked, why, and any open questions. Link the sources you used.
4. Create the issue with the defaults above.
5. Reply with the issue ID and link, plus one line saying the status, assignee, priority, and due date that were set.