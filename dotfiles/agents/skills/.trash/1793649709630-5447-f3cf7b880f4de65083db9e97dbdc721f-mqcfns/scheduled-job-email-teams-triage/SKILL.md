---
name: "scheduled-job-email-teams-triage"
description: "Smart triage of Michael's Gmail, Outlook, and Teams: Todoist tasks and draft replies for real asks, and labels, archives, or spam-marks the noise. Used by the hourly weekday scheduled task or run on demand."
---

# Email and Teams triage (smart)

Triage Michael Lyon's email and Teams messages: turn real asks into Todoist tasks with draft replies, and clean the noise out of his inboxes. Assume no memory of earlier runs. Do the whole job yourself, then end with a short summary. Don't ask Michael questions; make reasonable calls. When unsure about any message, leave it in the inbox untouched.

## Context
- Michael Lyon. Personal Gmail: mlyon360@gmail.com. Work: Outlook + Teams at MECA Therapies (michael.lyon@mecatherapies.com). Timezone America/Denver. He has ADHD: keep titles short, verb-first, and concrete. Todoist is his single hub.
- Load tools with ToolSearch first: mcp__Todoist__* (find-tasks, search, fetch-object, find-comments, add-tasks, add-comments), mcp__Gmail__* (search_threads, get_thread, create_draft, list_labels, create_label, label_message, label_thread, unlabel_thread, mark_thread_spam), mcp__Microsoft_365__* (outlook_email_search, read_resource, outlook_create_reply_draft, outlook_create_label, outlook_modify_labels, outlook_batch_modify_labels, chat_message_search, teams_list_chats, get_me), mcp__Linear__list_issues and mcp__Linear__get_issue (read-only, for Sentry alerts).

## Todoist
- Inbox project id 6Crfv33JcgwhPGr2 is his "Triage" view. EVERY task you create goes here. He accepts items by moving them to a project.
- Projects (reference only, do not create tasks in them): Home & Family 6fpR3gJHfCJ8phg4, Money 6hhGx42xf79HXRV4, Core Project (his LLC) 6gf8RwrWXR94rM5c, MECA 6hhGx42gGrMJP7M9, Side Projects 6g747Frvj326c9VJ, Someday 6hpqFjWVMwxfRm39.
- Labels: from-email, from-teams (source), quick (clearly 10 minutes or less), waiting, linear.
- Inbox assistant log: task id 6hprQ27W6mMHPXrh (in Someday). You add one comment per run there listing what you filed (see Sorting log). Never complete or edit it.
- Linear is the source of truth for real MECA engineering work and another job mirrors Michael's assigned issues into Todoist (tasks titled like "MEC-123 ..."). Do NOT create Todoist tasks for things that are clearly Linear issue work (bugs/features to build, PR reviews, Linear notifications). Note them in the summary instead. Exception: Sentry issue alert emails follow the "Sentry issue alerts" section below. Never edit those mirrored tasks.
- Never edit existing task titles or descriptions. Updates go in comments only (add-comments with notifyUsers ["none"]).

## What to look at: untriaged messages only
There is no time window. Each run handles every message that no earlier run has triaged, however old, so nothing is missed when a run is skipped, late, or fails partway. The scheduled task runs weekdays hourly, 7:00 through 17:00 America/Denver; on-demand runs work the same way.

How "triaged" is recorded:
- Gmail: the top-level label Triaged on the MESSAGE (label_message, not label_thread). A new reply in an already-triaged thread has no label yet, so it is picked up. Create the label with create_label if missing. It is deliberately not under Auto/, so it never looks like a filing label.
- Outlook: the category "Triaged" on the message. Create it with outlook_create_label (color gray) if missing.
- Teams: no labels exist, so use a watermark. Find the most recent comment on task 6hprQ27W6mMHPXrh whose first line starts with `RUN |` and read its `teams-through` timestamp. Teams messages after that timestamp are untriaged. If no RUN line exists, use 24 hours ago.

Mark a message triaged once you have finished with it and it stays in the inbox: tasked, commented, drafted, FYI, left alone because unsure, or rescued. Do NOT mark mail you file (archive) or spam-mark: it leaves the inbox, so it will not come back up. If Michael later drags it back, it shows up untriaged with its Auto label, which is how a rescue is detected. Messages over the task cap also stay unmarked so the next run picks them up.

Backstop: process at most 60 untriaged messages per source per run, newest first, and say in the summary how many remain. Ignore untriaged mail older than 14 days (do not mark it); mention the count in the summary so Michael can decide.

## Sources to scan
1. Gmail: search_threads with "in:inbox -label:Triaged newer_than:14d". In each thread, handle only inbox messages that lack Triaged. Use get_thread (PLAIN_TEXT) only for messages that might be actionable; the search result is enough to bucket obvious noise.
2. Outlook: outlook_email_search with folderName "Inbox" and afterDateTime 14 days ago (ISO with -06:00/-07:00 offset), limit 25, page with offset. Skip messages whose categories include "Triaged". read_resource the mail:/// URI only for messages that might be actionable.
3. Teams: chat_message_search with query "*" and afterDateTime = the watermark; page through results. Also look for @mentions of Michael and direct 1:1 chats. Ignore messages Michael sent himself (except to detect that he already answered something). read_resource on a teams:/// URI if the summary is cut off. Note the newest message time you saw; that becomes the new watermark (if you stopped at the backstop, use the newest time you actually processed, oldest-first for Teams so nothing is skipped). Overlap at the boundary is fine; dedupe handles it.

## Bucket each message
needs a reply / needs an action / FYI / noise / junk.
- Strict bar: only create a task when Michael is genuinely being asked to do or decide something, or a real deadline affects him.
- Noise: newsletters, promotions, political fundraising, social notifications, receipts, statements, login/security alerts, automated reports and "report delivered" emails, digests (Datadog, Sentry weekly, CodeRabbit), vendor marketing. These become tasks only if they contain a real deadline/action for Michael (example: "update your MFA by Oct 27", "mail forwarding ends Nov 24"); then make the task AND leave the message in the inbox.
- Junk (Gmail only): unsolicited mail from senders Michael has no relationship with: scams, phishing, cold spam, "you've won", fake invoices.
- Group-thread messages where someone else is clearly handling it are FYI.
- Sentry issue alerts: not bucketed here; handle them with the "Sentry issue alerts" section.
- Sensitive work email (PHI, secure-message wrappers such as securemail@hcsc.net, rosters, member data): NEVER open protected contents or click secure links. Just link the Outlook message. Weekly BCBS "PHI Referrals" secure emails feed the existing recurring task "upload BCBS roster" (id 6gqR2J538Vx9vJm4): add a short comment there with the link instead of creating a new task.

## Sentry issue alerts
A Sentry issue alert is a single-issue email from Sentry (sender at md.getsentry.com or sentry.io) whose subject is `<SHORT-ID> - <error>`, for example `CD-DOCUMENTS-4M - *json.SyntaxError: invalid character '<' looking for beginning of value`, and whose body is headed "New issue", "Regressed issue", "Escalating issue" or similar. Sentry weekly reports and digests are NOT issue alerts; they stay noise (Auto-Reports). Sentry's Linear integration creates a Linear issue for alerting Sentry issues, titled with the error text (not the short ID), with an attachment linking to the Sentry issue.

For each untriaged Sentry issue alert:
1. Read it (read_resource) and note: the short ID (subject before " - "), the error text (subject after " - "), the Sentry numeric issue id from the "View on Sentry" link (the number after `/issues/`), the project, and the environment.
2. Find its Linear issue (read-only):
   - mcp__Linear__list_issues with query = a distinctive part of the error text (for example `json.SyntaxError`; drop a leading `*` or quotes if the search misses), limit 25, fields [id,title,status,statusType,assignee,url]. If nothing comes back, also try the short ID.
   - For each candidate, mcp__Linear__get_issue with fields [id,title,status,statusType,assignee,attachments,url]. Accept it only if one of its attachment URLs contains `/issues/<Sentry numeric id>/`. A title match alone is not enough: different Sentry issues can share one error message.
   - If more than one issue matches, prefer one whose statusType is not "completed" or "canceled"; otherwise take the newest.
   - If a Linear call fails, do not guess: leave the email in the inbox, do NOT mark it Triaged (so the next run retries), and report it.
3. Decide:
   - **Tracked**: a matching issue exists, it has an assignee (anyone), and its statusType is "unstarted" or "started" (Todo, In Progress, In Review, Blocked, or another started status). Archive the email: outlook_modify_labels with addCategories ["Auto-Sentry"] and moveToFolderId "archive" (create the Auto-Sentry category with outlook_create_label, color gray, if missing). Log it as `FILED | outlook | <sender> | Auto-Sentry | <subject> → MEC-###`. No task.
   - **Needs triage**: anything else. That is: no matching Linear issue; a match with no assignee; or a match whose statusType is "backlog", "triage", "completed", or "canceled" (a closed issue alerting again is likely a regression). Make a triage task (step 4).
4. Triage task:
   - Dedupe first: search open Todoist tasks (mcp__Todoist__search and find-tasks with searchText) for the short ID. If an open task already has it, add one brief comment with the new email link (skip if that exact link was already commented) instead of a new task.
   - Otherwise create ONE task in project 6Crfv33JcgwhPGr2:
     - content: `Triage Sentry <SHORT-ID>: <short error>`, kept under about 70 characters (for example "Triage Sentry CD-DOCUMENTS-4M: json.SyntaxError in PostGrid call").
     - description: first line says why it needs triage, in plain words: "Not in Linear yet." / "In Linear as [MEC-901](url) but unassigned (Todo, Urgent)." / "In Linear as [MEC-901](url), assigned to <name>, but in Backlog." / "[MEC-901](url) is Completed in Linear but Sentry is alerting again." Second line: project, environment, and the alert type (new / regressed / escalating). Then links: `[Sentry](https://meca-therapies.sentry.io/issues/<numeric id>/) · [Email](<Outlook webLink>)`.
     - labels: from-email. No draft reply.
   - Leave the email in the inbox and mark it Triaged, like any tasked message.
   - These count toward the 5-task cap and rank with work deadlines and direct asks (prod errors first).
   - Never create, assign, edit, or comment on the Linear issue yourself.

## For each "needs action" or "needs reply" item
1. Dedupe first. Search open Todoist tasks (mcp__Todoist__search and find-tasks with searchText) for the thread/message link, the subject keywords, and the sender topic. Also check whether a comment on a matching task already contains this message link. If a matching open task exists: add one brief comment with the update and link (skip if that exact link was already commented). Do not create a new task.
2. Otherwise create ONE task in project 6Crfv33JcgwhPGr2:
   - content: short verb-first title (for example "Reply to Kristen on PMPM billing timing").
   - description: 1 to 2 lines of what is being asked and by when, then a markdown link to the source (Gmail viewUrl, Outlook webLink, or Teams webUrl). If you made a draft, say "Draft reply saved in Gmail/Outlook Drafts (not sent)" and link the draft.
   - labels: from-email or from-teams; add quick when clearly 10 minutes or less.
   - deadlineDate (YYYY-MM-DD) only when the message states a real deadline.
3. For "needs reply" also create a DRAFT reply: Gmail create_draft with replyToMessageId and the sender in "to", or Outlook outlook_create_reply_draft with the message id (HTML body, bodyType "html"). Keep drafts short, in Michael's plain friendly voice, signed "Michael". Do not commit him to dates or decisions he has not made; offer to discuss or ask a clarifying question instead. Before drafting, check that Michael has not already replied in the thread, and check that a draft reply for this thread does not already exist (an earlier overlapping run may have made one); never make a second draft for the same thread.

## Sorting (noise and junk)
After tasks are handled, file every untriaged noise message that is still in the inbox. Leave needs-reply, needs-action, and FYI-from-a-person messages in the inbox.

Gmail labels (nested under Auto/). At the start, list_labels to get IDs; create any missing one with create_label:
- Auto/Receipts: order confirmations, payment receipts, invoices for things already paid.
- Auto/Statements: bank, card, utility, insurance statements and "your statement is ready".
- Auto/Newsletters: newsletters, blogs, digests he subscribed to.
- Auto/Promos: sales, marketing, vendor promotions.
- Auto/Political: political fundraising and campaign mail.
- Auto/Alerts: login, security, account-change notices that need no action.
- Auto/Notifications: social, app, shipping, and other automated notices.
To file a Gmail thread: label_thread with the Auto label ID, then unlabel_thread with ["INBOX"] (this archives it).
Gmail junk: mark_thread_spam. No label.

Outlook categories. Create any missing one with outlook_create_label (color gray):
- Auto-Receipts, Auto-Newsletters, Auto-Promos, Auto-Alerts, Auto-Reports (automated reports, "Report Delivered", Datadog/Sentry/CodeRabbit digests and weekly reports), Auto-Sentry (Sentry issue alerts already tracked in Linear; only via the "Sentry issue alerts" section).
To file Outlook mail: outlook_batch_modify_labels (max 5 ids per call) or outlook_modify_labels with addCategories [the category] and moveToFolderId "archive". Outlook has no spam tool: treat junk as Auto-Promos and archive it.

Never file, archive, or spam:
- Mail from a person (not an automated sender) Michael knows or has emailed, or any human sender at @mecatherapies.com. Automated senders such as reporting@mecatherapies.com or no-reply addresses may be filed.
- Anything with a deadline, a direct question, or an action for Michael.
- PHI, secure-message, roster, BCBS, HCSC, Molina, Presbyterian, or Medicaid-member mail (except automated "Report Delivered" confirmations, which go to Auto-Reports).
- Calendar invitations and meeting updates.
- Individual production error alerts (single Sentry issue emails, Datadog monitor alerts that fired). The one exception is a Sentry issue alert found Tracked in Linear by the "Sentry issue alerts" section, which goes to Auto-Sentry. Otherwise only digests and weekly reports are filed.
- Anything you are not sure about.
Marking spam (Gmail): only for clear junk from unknown senders. Never for a company Michael has an account with, never for political mail (file it instead), never for anything that might be wanted.

Rescued mail: if an untriaged inbox message already carries an Auto/ label (Gmail) or Auto- category (Outlook), Michael moved it back on purpose. Do not file it again. Log it as RESCUED and mark it triaged so it is logged only once.

Do not change read/unread state.

## Sorting log
Every run adds ONE comment to task 6hprQ27W6mMHPXrh (add-comments, notifyUsers ["none"]). Its first line is always the Teams watermark:
`RUN | teams-through 2026-10-21T14:03:00-06:00`
Then one line per message you filed, spam-marked, or saw rescued:
`FILED | gmail | sender@domain.com | Auto/Newsletters | subject (first 40 chars)`
`FILED | outlook | sender@domain.com | Auto-Reports | subject`
`FILED | outlook | noreply@md.getsentry.com | Auto-Sentry | subject (first 40 chars) → MEC-901`
`SPAM | gmail | sender@domain.com | subject`
`RESCUED | gmail | sender@domain.com | Auto/Promos | subject`
Use the exact sender email address. The rule builder job reads these lines, so keep the format exact. Post the comment even when nothing was sorted (just the RUN line), so the watermark advances. If the run fails before Teams is done, do not advance the watermark: repeat the previous teams-through value.

## Cap
At most 5 new tasks per run. If more qualify, create the 5 most important (work deadlines, Sentry triage tasks, and direct asks from people first) and report the count of the rest in the summary; leave those messages in the inbox and do NOT mark them triaged, so the next run gets them. Comments on existing tasks do not count toward the cap. There is no cap on filing noise.

## Hard rules (never break)
- Mailbox changes allowed: only the Sorting actions above (apply Auto labels/categories, archive, Gmail mark-spam), marking messages triaged (Gmail Triaged label, Outlook Triaged category), and creating drafts.
- NEVER send, forward, delete, trash, unsubscribe, click links, change read state, or create, change, or delete filters/rules. Never move mail to Junk or Deleted Items. Never edit or delete any label or category other than creating the missing Auto ones and the Triaged label/category listed above. Never remove a Triaged mark. NEVER post or reply in Teams.
- Never complete, delete, move, or edit existing Todoist tasks. Only add tasks to the Inbox and add comments (including the log comment).
- Linear is read-only: you may only read issues with list_issues and get_issue for the Sentry check. Never create, edit, assign, or comment on Linear issues, and do not touch the Linear mirror tasks in Todoist.

## End with a short summary
- Tasks created (titles), comments added (to which tasks), drafts made.
- Sentry alerts: archived as tracked (short ID → MEC-###), triage tasks made (short ID and why), Linear lookups that failed.
- Filed: count per label/category, spam count, any rescued.
- FYI one-liners (one line each, max ~8).
- Linear-type items noted but not tasked.
- Anything skipped or over the cap (counts), and any tool errors.
- Untriaged left for next run (over the backstop) and untriaged mail older than 14 days, as counts.
- If nothing new needed action, say "Nothing new" plus counts scanned and filed.