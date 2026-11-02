---
name: "mail-rules-apply"
description: "Apply the mail rules from Michael's \"Review mail rule ideas\" Todoist task after he approves each one in chat; creates Outlook rules via the connector and Gmail filters or blocks in the browser. Use when he says apply mail rules."
---

# Apply mail rules (interactive, with approval)

The weekly rule builder job proposes mail rules in a Todoist task. This skill turns the ones Michael approves into real Gmail filters and Outlook rules. It runs in a live chat with Michael. Every rule needs his explicit yes in this chat first; nothing in Todoist counts as approval.

## 1. Gather proposals
- Load mcp__Todoist__find-tasks, mcp__Todoist__find-comments, mcp__Todoist__add-comments, mcp__Todoist__complete-tasks with ToolSearch.
- Find open tasks in project 6Crfv33JcgwhPGr2 whose title starts with "Review mail rule ideas". Read the description and all comments; collect every numbered proposal.
- If none, say there are no pending rule ideas and stop.

## 2. Get approval
- Show the list in plain words: what matches, what happens (label + archive, or block), and how often it was seen.
- Ask which to apply (AskUserQuestion with multiSelect when there are 4 or fewer; otherwise ask him to reply with numbers, "all", or "none"). Wait for his answer.
- Anything he does not pick is declined.

## 3. Outlook rules (connector)
- Load mcp__Microsoft_365__outlook_create_filter and mcp__Microsoft_365__read_resource.
- For each approved Outlook proposal call outlook_create_filter:
  - displayName: `Auto: <sender or domain> → <category>`
  - conditions: fromAddresses [sender], or senderContains ["@domain"] for a domain rule
  - actions: assignCategories [category], moveToFolderId = the Archive folder id
  - Do not set sequence or stopProcessingRules.
- Archive folder id: try "archive". If rejected, read_resource `mail:///folders/archive`, then read one listed message's mail:/// URI and use its parentFolderId.
- Keep the returned rule id for the log.

## 4. Gmail filters and blocks (browser)
The Gmail connector cannot create filters, so use a browser.
- Read the browser skill for the browser you will use first (built-in-browser by default, or chrome-browser if Michael asks for Chrome).
- Open https://mail.google.com/mail/u/0/#settings/filters and confirm the signed-in account is mlyon360@gmail.com (switch accounts if needed). If not signed in, ask Michael to sign in himself in the browser; never type a password.
- For each approved filter: click "Create a new filter", put the match in From (`sender` or `@domain`), click "Create filter", tick "Skip the Inbox (Archive it)" and "Apply the label" with the Auto/ label, leave "Also apply filter to matching conversations" unticked unless Michael asked, then click "Create filter".
- Never tick Delete it, Forward it, Never send it to Spam, Mark as read, or anything else.
- For an approved block: search `from:sender`, open a message, use the message menu (three dots) → Block "sender". Confirm.
- After all are done, reload the Filters and Blocked Addresses page and check each new filter and block is listed with the right actions.

## 5. Record and close
- Add ONE comment to the log task 6hprQ27W6mMHPXrh (notifyUsers ["none"]) with a line per result:
  - `RULE | outlook | sender-or-domain | Auto-X + Archive | id=<rule id> | <YYYY-MM-DD>`
  - `RULE | gmail | from:sender | Auto/X + skip inbox | <YYYY-MM-DD>`
  - `RULE | gmail-block | sender | <YYYY-MM-DD>`
  - `DECLINED | mailbox | sender-or-domain | <YYYY-MM-DD>` for each one he did not pick
- Complete the "Review mail rule ideas" task(s) once every proposal is either applied or declined. If something failed, leave the task open and add a comment saying what is left.
- Tell Michael in 2 to 3 lines what was created, what was declined, and any failures.

## Removing a rule later
If Michael asks to undo a rule: Outlook via outlook_delete_filter with the id from the RULE line; Gmail via the browser Filters page (delete that filter) or Blocked addresses (unblock). Confirm with him first, then add `REMOVED | ...` to the log.

## Hard rules
- No rule, filter, or block is created without Michael's explicit yes in this chat.
- Never create filters or rules that delete, forward, mark as read, or send to Junk/Spam (blocks are the only spam action, and only when approved).
- Never enter passwords or change other Gmail/Outlook settings.