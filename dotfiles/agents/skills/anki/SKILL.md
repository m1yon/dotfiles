---
name: anki
description: Work with Michael's Anki cards through the Anki MCP. Use when creating, editing, inspecting, or reviewing cards in Anki.
---

# Anki

Use the Anki MCP for all interactions with Anki. If it is unavailable, explain the blocker before attempting app operations.

Always use the deck named `All`. Scope searches and reviews to that deck and add new cards there. Keep existing cards in `All`; do not create topic decks or subdecks.

Before drafting or revising cards, invoke $formulating-knowledge. It governs card formulation; this skill supplies Anki workflow and Michael's preferences. A request to draft cards stays a draft. A request to add or update cards authorizes the corresponding MCP writes.

Before adding or editing cards, inspect representative existing notes in `All` through the MCP. Match the formatting of comparable cards, including note type, field layout, HTML, emphasis, code formatting, and cloze syntax. Inspect the note type's fields, templates, and styling as needed. Reuse those conventions without changing shared templates or CSS merely to format new content. If no comparable cards exist, use the simplest suitable existing note type.

Michael is a software engineer and a gamer. When examples help, prefer software engineering examples; gaming examples are also welcome. Choose examples that clarify the concept and preserve its meaning. Examples are optional.

After writes, read back the affected notes through the MCP to verify their content and formatting, and confirm their cards are in `All`. Report what changed.
