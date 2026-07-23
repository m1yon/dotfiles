---
name: interview-prep-anki
description: Maintain Michael's Interview Prep Anki deck with the Anki tools. Use when the user asks to inspect, search, create, edit, tag, migrate, organize, review, or analyze interview-prep flashcards, or to turn Interview Prep 2026 material into Anki notes.
---

# Interview Prep Anki

Create durable interview-prep flashcards, maintain their canonical tag taxonomy, and operate the user's Anki collection safely.

## Route the request

Choose the workflow that matches the user's intent before using tools:

- **Draft or create cards:** Formulate cards, tag them, check for duplicates, obtain approval unless the user requested direct addition, and create the notes.
- **Inspect, search, or analyze:** Use read-only note and card tools. Do not mutate the collection.
- **Edit, tag, migrate, or organize:** Find and inspect the affected notes first. Preview material changes and mutate only the notes the user placed in scope.
- **Conduct a review session:** Follow the review-session workflow below. Do not use GUI inspection tools as substitutes for review tools.

## Card Formulation Principles

### 1. SuperMemo’s “20 Rules of Formulating Knowledge”

- **Atomic Facts:** Keep questions and answers simple, clear, and concise — one fact per card.
- **Minimum Information Principle:** Include only as much context as needed to answer accurately.
- **Active Recall:** Avoid recognition-only questions unless necessary.
- **Avoid Enumerations:** Split lists or multi-part answers into separate, individual cards.
- **Precision:** Use precise, concrete language; avoid unnecessary or vague words.
- **Unambiguous Prompts:** Ensure every question has exactly one correct answer. Use context so the card remains clear outside the original text.

### 2. Andy Matuschak’s Principles

- **Deep Understanding:** Frame questions to prompt deep thinking and connection, not just rote recall.
- **Causal Prompts:** Where relevant, use *"Why...?"* or *"How...?"* questions to promote understanding.
- **Mental Models:** Avoid isolated trivia — ensure cards connect to a broader mental model.
- **Examples & Contrasts:** Use concrete examples and contrasts when dealing with abstract concepts.

### 3. Control-Alt-Backspace’s Precision Guidance

- **Targeted Prompts:** Avoid overly broad or fuzzy prompts; keep them specific.
- **Single-Test Focus:** Ensure questions test only one thing at a time.
- **Speed Optimization:** Cards should be answerable within **5–10 seconds**.
- **Differentiate Similar Concepts:** For concepts that are easily confused, explicitly differentiate them in the question.

Use longer scenario cards only when the interview task requires integrated judgment. Keep the decision being tested narrow even when the scenario provides context.

## Use the canonical tag taxonomy

Treat this taxonomy as authoritative. Do not preserve a legacy tag merely because it already exists.

Assign three required facets:

1. **Track — exactly one:** Identify the primary interview-prep track.
   - `track::system-design`
   - `track::low-level-design`
   - `track::coding`
   - `track::ai-engineering`
   - `track::behavioral`
   - `track::engineering-judgment`
   - `track::interview-communication`
2. **Topic — one primary, optionally one related:** Identify the reusable subject at the most useful level of specificity.
   - `topic::distributed-systems::consistency`
   - `topic::data-storage::indexing`
   - `topic::algorithms::graph-traversal`
   - `topic::design-patterns::observer`
   - `topic::typescript::type-system`
   - `topic::leadership::conflict`
3. **Kind — exactly one:** Identify the cognitive operation being practiced.
   - `kind::definition`
   - `kind::mechanism`
   - `kind::cause-effect`
   - `kind::comparison`
   - `kind::tradeoff`
   - `kind::application`
   - `kind::estimation`
   - `kind::failure-mode`
   - `kind::example`

Prefer these stable first-level topic roots before introducing another:

| Track | Preferred topic roots |
| --- | --- |
| System design | `distributed-systems`, `data-storage`, `caching`, `messaging`, `networking`, `observability`, `security`, `capacity-planning` |
| Low-level design | `object-modeling`, `design-patterns`, `api-design`, `concurrency`, `testing`, `extensibility` |
| Coding | `algorithms`, `data-structures`, `typescript`, `practical-coding`, `debugging` |
| AI engineering | `llm-systems`, `retrieval`, `evaluation`, `agents`, `inference`, `safety` |
| Behavioral | `leadership`, `collaboration`, `conflict`, `failure`, `impact`, `career` |
| Engineering judgment | `tradeoffs`, `reliability`, `maintainability`, `delivery`, `incident-response`, `technical-strategy` |
| Interview communication | `requirements`, `clarification`, `problem-framing`, `explanation`, `tradeoff-communication`, `interview-structure` |

Add optional facets only when the metadata is known and useful:

- **Source:** `source::<work-or-plan>::<locator>`
  - `source::interview-prep-2026::day-02`
  - `source::hello-interview::system-design`
  - `source::designing-data-intensive-applications::chapter-05`
- **Context:** Use only when a card is specific to a target rather than generally reusable.
  - `context::company::stripe`
  - `context::role::staff-engineer`

### Tag rules

- Use lowercase ASCII and kebab-case inside every segment.
- Use `::` only between hierarchy levels.
- Prefer full, recognizable terms over private abbreviations.
- Reuse the canonical spelling for an existing concept; never create synonyms such as both `topic::database` and `topic::data-storage`.
- Keep most cards to 3–5 tags: one track, one topic, one kind, and optional source or context.
- Add a second topic only when cross-topic retrieval is genuinely useful.
- Do not encode deck name, difficulty, mastery, due state, or scheduling state in tags. Use Anki scheduling, flags, and card state for those concerns.
- Do not invent a source or context tag.

Before drafting a batch, retrieve the deck's tags to catch spelling collisions and identify legacy tags. Map concepts to the canonical taxonomy rather than allowing the legacy vocabulary to shape new tags.

## Draft cards for approval

Unless the user requested direct addition, present cards before writing:

```text
Q: [Question]
A: [Answer]
Tags: [track tag, topic tag, kind tag, optional source/context]
```

For every card, verify:

- Does the prompt make sense in isolation?
- Does it test one thing with one intended answer?
- Is the answer as short as accuracy permits?
- Can it normally be answered within 10 seconds?
- Do the tags use the canonical spelling and required facets?

## Create cards safely

Use this default Anki configuration:

- **Deck:** `Interview Prep`
- **Note type:** `Basic`, unless the user requests another type
- **Fields:** `Front` for the question and `Back` for the answer

Before the first write in a task:

1. Verify the deck with `list_decks`, the note type with `model_names`, and its fields with `model_field_names`. If they are missing or incompatible, stop and report the mismatch; do not create or change collection structure unless requested.
2. Search the `Interview Prep` deck with `find_notes` and inspect likely matches with `notes_info`. Do not add a semantic duplicate merely because its wording differs.
3. Preserve duplicate protection. Never enable duplicate creation unless the user explicitly requests it.

Use `add_note` for one card and `add_notes` for multiple cards. After writing, report which notes were created, skipped, or failed; never imply that a partial batch fully succeeded.

## Inspect, edit, and organize

- Use `find_notes` followed by `notes_info` when content or metadata matters.
- Use `cards_stats` for scheduling analysis when note text is unnecessary.
- Use `update_note_fields`, `tag_management`, or `card_management` only for mutations the user requested.
- Preserve note IDs and scheduling history when editing or retagging existing notes.

For a tag migration:

1. Inventory the deck's tags and affected notes.
2. Build an old-to-canonical mapping with note counts; separate ambiguous tags.
3. Present the proposed mapping before applying it unless the user explicitly requested automatic migration.
4. Apply tag changes to the scoped note IDs with batched `tag_management` operations.
5. Re-read representative notes and report migrated, skipped, ambiguous, and failed counts.
6. Clear unused collection-wide tags only when the user explicitly requests that separate cleanup.

## Conduct a review session

1. Start `sync` and poll it to a terminal result before fetching cards.
2. Never choose a destructive one-way conflict resolution without the user's explicit direction. Cancel safely when the correct side is unknown.
3. Retrieve the next due card from `Interview Prep` in scheduler order with `get_due_cards`.
4. Show its question with `present_card` and wait for the user's answer.
5. Show its answer with `present_card`, evaluate the response, and suggest a rating.
6. Wait for the user to confirm or change the rating before calling `rate_card`.
7. Repeat until the user stops or no cards remain.
8. Sync again when the session ends.

## Example

**Source content**

> Unlike languages such as Java or C#, which use nominal typing, TypeScript uses structural typing. Two TypeScript types are compatible when their internal structures are compatible, regardless of their explicit names.

**Generated draft**

```text
Q: In TypeScript, what determines whether two types are compatible?
A: Their structure, not their declared names.
Tags: track::coding, topic::typescript::type-system, kind::mechanism

Q: How does TypeScript's compatibility rule differ from Java and C#?
A: TypeScript compares structure; Java and C# primarily use declared type identity.
Tags: track::coding, topic::typescript::type-system, kind::comparison
```
