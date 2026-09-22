---
name: anki
description: Work with Michael's Anki cards through the Anki MCP. Use when creating, editing, inspecting, or reviewing cards in Anki.
---

# Anki

Use the Anki MCP for all interactions with Anki. If it is unavailable, explain the blocker before attempting app operations.

Always use the deck named `All`. Scope searches and reviews to that deck and add new cards there. Keep existing cards in `All`; do not create topic decks or subdecks.

Before drafting or revising cards, invoke $formulating-knowledge. It governs card formulation; this skill supplies Anki workflow and Michael's preferences. When creating cards from user-provided source material, follow [creating_cards_flow.md](creating_cards_flow.md). Each round tests Michael's understanding of one concept, reviews cards for it, and adds the approved cards to Anki before moving on. A request to draft cards stays a draft. Outside that creation flow, a request to add or update cards authorizes the corresponding MCP writes.

When Michael says he doesn't like a card, first present exactly three distinct alternatives labeled A, B, and C with the proposed card text for each. In the creation flow, preserve the card's number across revisions and continue card numbering across rounds. Wait for him to choose before making any changes in Anki. For an existing Anki card, his choice authorizes updating the card with that alternative; apply it without asking for another confirmation. For a draft in the creation flow, his choice approves that version for the current round.

Before adding or editing cards, inspect representative existing notes in `All` through the MCP. Match the formatting of comparable cards, including note type, field layout, HTML, emphasis, code formatting, and cloze syntax. Inspect the note type's fields, templates, and styling as needed. Reuse those conventions without changing shared templates or CSS merely to format new content. If no comparable cards exist, use the simplest suitable existing note type.

Michael already knows the review flow. End understanding checks with the question and suggestion messages with the final card option or image. Omit response-format examples, instructions to reply or choose, and closing approval prompts. Wait for his response without announcing that wait. Ask a focused clarification only when his response leaves a choice unresolved.

Use examples only when they help clarify the concept; omit them when the card is clear on its own. Keep each card grounded in its subject and use the simplest fitting example. Michael is familiar with programming and gaming, so examples from those domains can help when the connection is natural and useful. Use those examples and terms only when they improve understanding, rather than as a default theme for cards.

Use images when they clarify the tested relationship, support a useful association, or enable image occlusion under $formulating-knowledge. Invoke $imagegen and use the image generation tool to create one suitable image per card when a visual is useful. Generate alternatives only if Michael requests them. Inspect images for factual accuracy, legibility, and whether they reveal the answer when placed on the front. In creation rounds, offer one image preview beneath the card's text options as described in [creating_cards_flow.md](creating_cards_flow.md). Add the selected image through the Anki MCP using the existing note format, and retain its source or generation provenance with the final card.

After writes, read back the affected notes through the MCP to verify their content and formatting, and confirm their cards are in `All`. Report what changed.
