# Run the Friday review

At 9am every Friday, a T3 Code scheduled task runs `/weekly-review` in a new thread. It marks stale cards, drafts an answer for every step below, and waits in that thread. Open the thread, and approve or fix the drafts. See [AI jobs](ai-jobs.md#weekly-review).

To review by hand instead, follow these steps:

1. Empty the Inbox. See [Triage the Inbox](triage.md).
2. Open the Review filter. For each `@stale` card, keep it, move it to Someday, or delete it. To keep a card, remove its `@stale` label.
3. Check each `@waiting` card. If the work is done, complete the card. If it's stuck, follow up or take it back. For an agent's card, check the PR linked in its comments.
4. Archive each feature project that shipped.

The job adds `@stale` at the start of its run, so the Review filter is current by 9am.
