---
name: inbox
description: Adds a card to Michael's Todoist Inbox without leaving the current work. Use for /inbox, "Inbox it", or side work listed at the end of the last reply.
---

# Inbox

Add the cards, then go back to the current work. Ask no questions.

1. Choose the cards.
   - `/inbox <idea>` is one card, titled from the idea.
   - `/inbox` with no text is one card per side-work item listed at the end of your last reply.
2. Write each card's description: the repo (the owner and name in `git remote get-url origin`), the branch, and one sentence of context from this session. Outside a git repo, write only the sentence. Member names, IDs, and other member data stay out of the card.
3. Add each card with `td task add "<title>" --description "<description>"`. With no other options, the card lands in the Inbox at p4 with no date, and triage files it later.
4. Reply with `Inboxed: <title>` for each card, and continue the work in progress.
