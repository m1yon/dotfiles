---
name: anki
description: Work with Michael's Anki cards through the Anki MCP. Use when creating, editing, inspecting, or reviewing cards in Anki.
---

# Anki

Use the Anki MCP for all Anki operations. If it is unavailable, explain the blocker. Scope searches, reviews, and writes to the deck `All`; keep cards there without creating topic decks or subdecks.

Invoke $formulating-knowledge before drafting or revising cards. Use its formulation principles through the rules below; this skill defines Michael's interaction and approval flow.

## Choose the flow

For user-provided source material, follow [creating_cards_flow.md](creating_cards_flow.md), including for draft-only requests. Start with its learning-goal step. Each round checks understanding of one concept, reviews its cards, and adds approved cards before advancing. Draft-only requests follow the same review flow without Anki writes. Outside this flow, a request to add or update cards authorizes the corresponding writes.

When Michael dislikes a card, present exactly three distinct alternatives labeled A, B, and C with complete proposed text. Wait for his choice before writing. His choice authorizes updating an existing card without another confirmation; for a creation draft, it approves that version within the round.

Michael knows the review flow. End understanding checks with the question and suggestions with the final option or image. Omit reply examples, instructions to choose, closing approval prompts, and announcements that you are waiting. Clarify only unresolved choices.

## Formulate and inspect

Start from the learning objective and overall explanation, with prerequisites before dependent details. Select useful recall targets from the source and discussion. Whenever checking understanding, use [Test understanding](creating_cards_flow.md#test-understanding), including its teaching and reassessment loop. Keep affected cards provisional until Michael demonstrates understanding. A missed answer calls for diagnosis; evaluate his reasoning before deciding whether the problem is understanding, recall, or card formulation.

- Give each card one independently gradable recall target. Include enough subject context to answer without the round heading or neighboring cards, and remove wording that does not help retrieval.
- Write every proposed answer in casual, concise language that Michael can naturally say out loud. Prefer everyday words, contractions, and short phrases or sentences. Keep technical terms and qualifications needed for accuracy; put optional explanation in notes. Apply this to every answer option, including cloze reveals.
- Split unordered collections into meaningful questions and required sequences into overlapping short segments. Preserve any relationship the learner needs to recall.
- Use cloze for an unambiguous missing phrase and targeted contrasts for confusable concepts. Add reverse retrieval only when useful; accept equivalent answers.
- Connect new facts to established knowledge. Use simple examples, personal associations, or vivid mnemonics when they help, especially for stubborn associations. Michael knows programming and gaming; use those domains only when the connection fits. Use supplied personal details and label invented examples as hypothetical.
- Preserve source qualifications, units, and exceptions. Flag unsupported or conflicting claims and keep affected cards provisional. Retain provenance and dates or versions for changing claims separately from the tested answer. Put optional explanations and grading tolerances in notes.

Before presenting cards, inspect each prompt with the answer and neighboring cards hidden. Check for fair grading, missing context, answer leaks, overloaded targets, and relationships lost through splitting. Repair failures first. When revising existing items, map originals to replacements and briefly explain the change; keep unresolved gaps separate.

## Match existing notes

Before adding or editing, inspect representative notes in `All`. Match comparable note types, fields, HTML, emphasis, code formatting, and cloze syntax. Inspect templates and styling as needed; reuse them without changing shared templates or CSS merely to format content. If no comparable cards exist, use the simplest suitable existing note type. Match formatting while correcting formulation defects.

## Choose useful images

Generate an image only when it materially improves the recall task. Otherwise, present text-only options. When an image is useful, invoke $imagegen and use the image generation tool to create one image for that card. Generate alternatives only on request.

Recommend the front when the image supplies evidence or context the learner must interpret. Mask individual regions when recalling visual components. Recommend the back when the image explains or reinforces the answer. Inspect factual accuracy, legibility, and answer leakage in the proposed placement, including labels and captions.

Use the [image approval flow](creating_cards_flow.md#image-approval) for new and existing cards. Store approved media through the MCP in the existing note format, with its source or generation provenance separate from the tested answer.

## Verify writes

Read back affected notes through the MCP. Verify content, formatting, retained sources, and the `All` deck. For images, verify stored media, note references, approved placement, and any occlusion. Report what changed.
