---
name: interview-prep-anki
description: Maintain Michael's Interview Prep Anki deck with the Anki tools. Use when the user asks to inspect, search, create, edit, tag, migrate, organize, or analyze interview-prep flashcards, or to turn Interview Prep 2026 material into Anki notes.
---

# Interview Prep Anki

Create durable interview-prep flashcards, maintain their canonical tag taxonomy, and operate the user's Anki collection safely.

## Route the request

Choose the workflow that matches the user's intent before using tools:

- **Draft or create cards:** Formulate cards in Anki Markdown, tag them, check for duplicates, preview every Front and Back, obtain explicit approval, and create the notes.
- **Inspect, search, or analyze:** Use read-only note and card tools. Do not mutate the collection.
- **Edit, tag, migrate, or organize:** Find and inspect the affected notes first. Preview the exact changes, obtain explicit approval, and mutate only the notes the user placed in scope.

## Card Formulation Principles

### Use simple, practical language

- Write like a practical engineer explaining the idea to another engineer.
- Prefer plain, conversational language over academic, textbook, or research-paper phrasing.
- Use the simplest words that preserve the technical meaning.
- Introduce jargon only when the term itself is useful for the interview; explain it plainly the first time.
- Favor concrete actions, consequences, examples, and tradeoffs over abstract definitions.
- Keep necessary technical precision, but do not make a card sound more formal or complicated than the idea requires.
- Give the Front enough context to know what the question relates to.

### Follow SuperMemo’s “20 Rules of Formulating Knowledge”

- Keep questions and answers simple, clear, and concise — one fact per card.
- Break down complex information into atomic facts.
- Use active recall and avoid recognition-only questions unless necessary.
- Avoid cloze deletions unless they make the card simpler and unambiguous.
- Use minimum information principle: include only as much as needed to answer.
- Make cards unambiguous — ensure the question has only one correct answer.
- Use context when needed so the meaning remains clear outside the original text.
- Avoid unnecessary or vague words; use precise, concrete language.
- Avoid “enumerations” — split lists into multiple cards.
- Use visuals only when they meaningfully support recall.

### Apply Andy Matuschak’s principles

- Frame questions to prompt deep thinking and connection, not just rote recall.
- Where relevant, use “Why…?” or “How…?” questions to promote understanding.
- Avoid trivia in isolation — cards should connect to a bigger mental model.
- Make the answer mentally satisfying to recall — aim for an “aha” moment.
- For abstract concepts, use examples and contrasts.

### Apply Control-Alt-Backspace’s “Precise” guidance

- Avoid overly broad or fuzzy prompts; make them specific and targeted.
- Ensure questions test only one thing at a time.
- Anticipate common wrong answers and adjust wording to avoid ambiguity.
- Optimize for recall speed — the card should be answerable in 5–10 seconds.
- For concepts that are similar or confusable, differentiate explicitly in the question.

Use longer scenario cards only when the interview task requires integrated judgment. Keep the decision being tested narrow even when the scenario provides context.

## Format fields with Anki Markdown

- Write all Front and Back content using Anki Markdown.
- Default to JavaScript for requested code examples.
- Keep formatting minimal and purposeful; formatting must support recall rather than decorate the card.
- Use inline code for identifiers, commands, types, and short expressions.
- Use fenced code blocks with a language identifier for multi-line code.
- Use emphasis, blockquotes, tables, and lists only when they materially improve clarity.
- Do not use a list to hide a multi-answer card that should be split under the formulation principles.
- Avoid raw HTML unless the required Anki behavior cannot be represented in Anki Markdown.
- Preserve the approved Markdown source exactly when writing it to Anki.

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

## Require explicit approval before writes

Treat approval as a mandatory two-step gate. The user's initial request to add or edit cards is not approval because the user has not yet seen the exact proposed result.

Before calling `add_note`, `add_notes`, or `update_note_fields`:

1. Prepare the final proposed content.
2. Show the exact Anki Markdown source for the Front and Back of every affected card.
3. Ask the user to approve that specific preview.
4. Wait for an explicit confirmation before writing.

Preview new cards in this format:

```text
Card 1
Front: [Exact proposed Front]
Back: [Exact proposed Back]
```

For an edit, show the note ID plus its current and proposed values:

```text
Note 123
Current Front: [Current Front]
Current Back: [Current Back]
Proposed Front: [Exact proposed Front]
Proposed Back: [Exact proposed Back]
```

Do not require tags in a Front/Back approval preview. Show tags when the user asks to inspect them or when tags are also being changed.

Require a new preview and approval whenever any proposed Front or Back changes after approval. Do not interpret questions, requested revisions, silence, or approval of an earlier draft as approval of the current content.

For tag-only, deck-placement, or card-state mutations, preview the exact change and affected scope and obtain explicit approval. Do not require every Front and Back when note text will remain unchanged.

For every card, verify:

- Does the prompt make sense in isolation?
- Does the Front provide enough context to know what the question relates to?
- Does it test one thing with one intended answer?
- Does it use simple, practical language instead of academic phrasing?
- Is the answer as short as accuracy permits?
- Can it normally be answered within 10 seconds?
- Do the tags use the canonical spelling and required facets?

## Create cards safely

Use this default Anki configuration:

- **Deck:** `Interview Prep`
- **Note type:** `Basic`, unless the user requests another type
- **Fields:** `Front` for the question and `Back` for the answer, both containing the approved Anki Markdown

Before the first write in a task:

1. Verify the deck with `list_decks`, the note type with `model_names`, and its fields with `model_field_names`. If they are missing or incompatible, stop and report the mismatch; do not create or change collection structure unless requested.
2. Search the `Interview Prep` deck with `find_notes` and inspect likely matches with `notes_info`. Do not add a semantic duplicate merely because its wording differs.
3. Preserve duplicate protection. Never enable duplicate creation unless the user explicitly requests it.
4. Complete the mandatory preview-and-approval gate above.

Use `add_note` for one card and `add_notes` for multiple cards. After writing, report which notes were created, skipped, or failed; never imply that a partial batch fully succeeded.

## Inspect, edit, and organize

- Use `find_notes` followed by `notes_info` when content or metadata matters.
- Use `cards_stats` for scheduling analysis when note text is unnecessary.
- Use `update_note_fields`, `tag_management`, or `card_management` only for mutations the user requested.
- Preserve note IDs and scheduling history when editing or retagging existing notes.

For a tag migration:

1. Inventory the deck's tags and affected notes.
2. Build an old-to-canonical mapping with note counts; separate ambiguous tags.
3. Present the proposed mapping and wait for explicit approval.
4. Apply tag changes to the scoped note IDs with batched `tag_management` operations.
5. Re-read representative notes and report migrated, skipped, ambiguous, and failed counts.
6. Clear unused collection-wide tags only when the user explicitly requests that separate cleanup.

## Example

**Source content**

> Unlike languages such as Java or C#, which use nominal typing, TypeScript uses structural typing. Two TypeScript types are compatible when their internal structures are compatible, regardless of their explicit names.

**Generated draft**

```text
Front: In `TypeScript`, what determines whether two types are compatible?
Back: Their **structure**, not their declared names.
Tags: track::coding, topic::typescript::type-system, kind::mechanism

Front: How does `TypeScript`'s compatibility rule differ from `Java` and `C#`?
Back: `TypeScript` compares structure; `Java` and `C#` primarily use declared type identity.
Tags: track::coding, topic::typescript::type-system, kind::comparison
```
