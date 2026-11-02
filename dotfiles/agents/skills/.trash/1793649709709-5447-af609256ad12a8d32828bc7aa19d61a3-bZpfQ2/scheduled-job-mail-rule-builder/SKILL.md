---
name: "scheduled-job-mail-rule-builder"
description: "Weekly job: reads what the smart triage filed and proposes permanent Gmail and Outlook filter rules to Michael as a Todoist review task. Proposes only; never creates rules."
---

# Mail rule builder (propose only)

The hourly triage job files noise by hand each run and logs it. Your job: find senders it keeps filing the same way and propose permanent mail rules so that mail is handled on arrival. You only PROPOSE. Michael approves and applies them later in a chat with the "mail-rules-apply" skill. Assume no memory of earlier runs. Don't ask questions; end with a short summary.

## Tools
Load with ToolSearch: mcp__Todoist__find-comments, mcp__Todoist__find-tasks, mcp__Todoist__search, mcp__Todoist__add-tasks, mcp__Todoist__add-comments. You may read mail with mcp__Gmail__search_threads and mcp__Microsoft_365__outlook_email_search to confirm a pattern, but never change anything in a mailbox.

## Inputs
- Inbox assistant log: Todoist task 6hprQ27W6mMHPXrh. Read ALL its comments (page through). Line formats:
  - `FILED | gmail|outlook | sender | label | subject`
  - `SPAM | gmail | sender | subject`
  - `RESCUED | mailbox | sender | label | subject` (Michael pulled it back to the inbox)
  - `RULE | mailbox | match | action | ...` (a rule already created)
  - `DECLINED | mailbox | match | ...` (Michael said no)
- Use the comment's posted date for each line.

## Find candidates
1. Take FILED lines from the last 14 days. Group by mailbox + exact sender address.
2. A sender is a candidate when: filed 3 or more times in 14 days, at least once in the last 7 days, and the same label 90% or more of the time.
3. If 2 or more candidate addresses share one domain and the same label, and the domain is a bulk/no-reply sender (not a company Michael works with directly), propose one domain rule instead (Gmail `from:@domain.com`; Outlook senderContains "@domain.com").
4. Spam: a sender (or domain) with 2 or more SPAM lines in 14 days is a block candidate (Gmail only).
5. Drop a candidate if any of these hold:
   - It has any RESCUED line ever.
   - It matches a DECLINED or RULE line (same mailbox and same sender or domain).
   - It is a person rather than an automated sender, or any human @mecatherapies.com address.
   - It is PHI/secure/roster/payer mail (BCBS, HCSC, Molina, Presbyterian, securemail), a calendar sender, or an individual production alert.
   - It already appears in an open proposal task (see below).

## Rule shapes
- Gmail filter: match `from:sender` (or `from:@domain`); actions: Skip the Inbox (archive) + Apply label <Auto/...>. Never Delete, Forward, Mark as read, or Send to spam.
- Gmail block (spam candidates only): Block sender (future mail goes to Spam).
- Outlook rule: condition fromAddresses [sender] (or senderContains ["@domain"]); actions: assignCategories [<Auto-...>] + move to Archive. Never delete, forward, or Junk.

## Propose
- Max 8 proposals per run, most-filed first.
- Look for an open task in project 6Crfv33JcgwhPGr2 whose title starts with "Review mail rule ideas". If one exists, add ONE comment to it with only the new proposals, numbered continuing after the last number already in that task and its comments. Do not create a second task.
- Otherwise create one task in project 6Crfv33JcgwhPGr2:
  - content: `Review mail rule ideas (N)`
  - labels: from-email, quick
  - description: one numbered line per proposal, then a blank line and: `To apply: tell Claude "apply mail rules". You'll approve each one first.`
  - Line format: `1. [Gmail] from:news@acme.com → Auto/Newsletters + archive (filed 6× in 14d)`; `2. [Outlook] from:no-reply@dtdg.co → Auto-Reports + Archive (filed 9×)`; `3. [Gmail block] spammer@x.biz (spam 3×)`
- If there are no candidates, create nothing.

## Hard rules
- NEVER create, change, or delete any mail rule, filter, block, label, or category. Never change any message. Read only.
- Only Todoist writes allowed: create the one proposal task in the Inbox, or comment on the open proposal task. Never touch other tasks, and never complete or edit the log task.

## Summary
Candidates found, proposals made (count, and the task title), candidates dropped and why (counts), any tool errors. If nothing qualified, say "No new rule ideas" with the count of FILED lines read.