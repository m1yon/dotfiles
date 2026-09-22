---
name: formulating-knowledge
description: Create flashcards from source material or revise difficult spaced-repetition items using SuperMemo's twenty rules. Use for Anki, SuperMemo, cloze deletion, and image-occlusion card design.
---

# Formulating knowledge

Use this skill to draft cards, review an existing deck, or repair items the learner repeatedly misses. Follow the user's requested format and scope. If no format is specified, return a Markdown table with prompt, answer, and notes columns. Drafting cards does not authorize importing them into an app or changing review schedules.

## Establish the input

Read the supplied material and identify the learning objective. If either is missing and cannot be inferred, ask for it. For an existing deck, use any supplied review history to identify troublesome items. Avoid treating a missed answer as proof of poor formulation or lack of understanding.

When the learner reports confusion, explain the relevant concept and ask a focused comprehension question. Keep affected cards provisional until the gap is resolved; continue with independent material. When simply asked to draft a deck, flag unclear prerequisites without imposing an interactive lesson.

## Apply the article's guidance

The following is a concise adaptation of Piotr Wozniak's [Twenty rules of formulating knowledge](https://www.supermemo.com/en/blog/twenty-rules-of-formulating-knowledge). Numbers correspond to the article. The surrounding workflow is an implementation for this skill.

1. Resolve misunderstandings before committing material to memory.
2. Establish the overall explanation before extracting individual facts.
3. Put prerequisite concepts ahead of dependent details.
4. Give each item one independently gradable recall target.
5. Use cloze prompts when a missing phrase is unambiguous.
6. Choose pictures when they convey the tested relationship better.
7. Offer mnemonics for stubborn associations.
8. Test visual components by masking individual regions.
9. Break unordered collections into meaningful smaller questions.
10. Practice required sequences through overlapping short segments.
11. Distinguish confusable concepts with targeted contrasts.
12. Remove wording that contributes nothing to retrieval.
13. Connect new facts to established knowledge.
14. Include concrete examples and relevant personal associations.
15. Use vivid associations that remain useful outside review.
16. Supply enough domain context to disambiguate the prompt.
17. Add alternate retrieval directions when useful; accept equivalent answers.
18. Attach provenance separately from the tested answer.
19. Record dates or versions for changing claims.
20. Select material by usefulness and revise troublesome items.

## Draft and inspect

Use personal details only when the user supplies them. Label invented examples as hypothetical. Preserve qualifications, units, and exceptions from the source. Flag unsupported or conflicting claims rather than presenting them as settled answers.

Keep optional explanations and grading tolerances in notes. For app-specific exports, use the requested syntax and check that fields and media references survive the export. If an image is unavailable, describe the proposed occlusion and mark the card as pending media.

Inspect prompts with their answers hidden and without neighboring cards. Check whether the intended answer can be graded fairly, whether the prompt leaks it, and whether splitting an item lost a required relationship. Repair failures before delivery. For revisions, map each original item to its replacements and briefly explain the change. List unresolved factual or comprehension gaps separately.

## Example

Hypothetical source: "The Luma device shows amber while charging and green when fully charged."

An overloaded prompt asks, "What do Luma's lights mean?" Split it into:

| Prompt | Answer |
| --- | --- |
| On the Luma device, what does an amber light indicate? | Charging. |
| On the Luma device, what does a green light indicate? | Fully charged. |

If the task is troubleshooting an unfamiliar light, these prompts match that task. Add the reverse direction only if the learner also needs to predict which light should appear.
