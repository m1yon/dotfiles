# Creating cards flow

Use this flow to work through Michael's source material one concept at a time. In each round, establish his understanding, review cards together, and add that round's approved cards to Anki before moving on.

## Read and organize

1. Read the source Michael provides. If it is inaccessible or incomplete, ask for the missing material before working on affected concepts.
2. Identify the concepts worth learning and their prerequisites. Organize rounds around one idea or concept each, with prerequisites first. Preserve the source's qualifications and provenance; resolve unsupported or ambiguous claims before using them to assess understanding or create cards.
3. Give a brief overview of the concepts to cover, then begin the first round. Draft each round's cards only after Michael demonstrates understanding of that concept.

## Test understanding

Start the round with a focused, open-ended question about its concept, then wait for Michael's answer. Ask one question at a time. Use questions that require him to explain the idea in his own words, explain why something happens, distinguish related ideas, or apply it to a concrete example. Keep the expected answer and proposed cards out of this initial question.

Assess the substance of his answer against the source, accepting equivalent wording. Understanding is demonstrated when he can explain the central idea accurately and reason through an application or relevant distinction without a material misconception. One answer can establish both; ask a follow-up only for evidence still missing. A claim of understanding or repetition of an answer just supplied is not sufficient evidence.

If his answer reveals a gap, explain that specific point and ask a fresh question that checks whether he can now use it. Continue the discussion until the gap is resolved. Once he meets the understanding criterion, briefly name what his answer demonstrated and proceed to cards. Avoid extra quizzes after the criterion is met.

### Understanding check template

Render this as Markdown, replacing the placeholders. Omit the total round count if it is not yet known.

```markdown
### Round {round} of {total rounds}: {concept}

Understanding check

{One focused question that requires explanation or application.}
```

## Draft and review the round's cards

Draft cards for the concept Michael has just demonstrated, following all applicable principles in $formulating-knowledge and the formatting and preferences in [SKILL.md](SKILL.md). Use the discussion to identify useful distinctions and facts to retain. Aim for a handful of cards, usually 3–5, but use fewer when the concept needs fewer. Keep every card within this round's concept.

Inspect each card on its own, with its answer hidden, using the checks in $formulating-knowledge. Repair unclear prompts and overloaded recall targets before showing the cards.

Present all card ideas and their options for the current round together in one message using the template below. For every proposed card, offer exactly three distinct front/back options for the same recall target. Vary the wording or approach while keeping each option valid under $formulating-knowledge. Mark one option per idea as recommended based on clarity and ease of recall. Show the complete proposed text for every option, then wait so Michael can choose for the whole round in one reply.

For each card, consider whether an image would help the learner understand, remember, or apply the idea. Evaluate the value of showing a concrete example, comparison, relationship, or demonstration, even when the text is already clear. If a visual would provide a useful recall cue or make an abstract explanation concrete, generate one suitable image using $imagegen and the image generation tool as described in [SKILL.md](SKILL.md). Omit images only when they would be decorative, redundant, or distracting.

Show the image preview directly below that card's three text options, before the next card. Label it Image and add a short caption stating what it depicts and where it belongs on the card. If an image cannot be obtained or displayed, identify the missing preview and keep its approval pending.

Number card ideas with plain integers starting at 1, continuing across the entire source-material session without resetting between rounds. For example, if round one has cards 1–3, round two starts with card 4. Keep a card's number through revisions and give each new idea the next unused number. Label each card's three options A, B, and C. Track the exact versions and approval status for each card and option.

Michael prefers one selection per line, with the card number followed by a period and the option letter:

```text
8. A
9. B
```

This example is internal guidance for interpreting replies; omit it from review messages. Also accept other unambiguous formats. A letter alone is sufficient when only one card is under discussion. Selections refer to the latest displayed version of that option. Unmentioned cards stay pending. The recommendation is not a default selection; silence does not approve it. If a response leaves the choice ambiguous, such as giving only a card number or selecting two alternatives for the same card, clarify only that choice and retain the unambiguous selections.

Track text and image approval independently. For example, `8. A, with image` approves text A and the displayed image for card 8. When an image is offered, wait for approval of the image or an explicit request for no image; text approval alone does not approve an image. Verify that the chosen text and image work together, and show any necessary revision for approval.

Work with Michael on requested changes within the current round. When he dislikes a card, use the three-alternative workflow in [SKILL.md](SKILL.md). Use the same concise template for revised options and mark one recommendation. Keep other approvals intact unless those cards also change. If the discussion reveals a remaining misunderstanding, return to a focused understanding check before finalizing affected cards. Continue until every card idea in the round has an approved version or Michael has chosen to remove it.

Keep the current round's cards as drafts until the whole round is approved. Then add and verify them as described below before starting the next concept.

### Round display template

Render this template as Markdown in the conversation, replacing placeholders and including a block for every card idea in the round. Put the card number in its heading and label its options A, B, and C. Each block contains alternatives for one card, not three cards to add. Mark the recommended option with ⭐ immediately after its letter, without a "Recommended" text label. The example begins with card 1; use the next unused card numbers in subsequent rounds.

```markdown
### Round {round}: {concept}

#### 1. {First card idea}

| Option | Front | Back |
| --- | --- | --- |
| A | {Exact question.} | {Exact answer.} |
| B ⭐ | {Alternative question.} | {Alternative answer.} |
| C | {Alternative question.} | {Alternative answer.} |

**Image** · {Short description; front or back.}
![{Alt text}]({preview path or URL})

#### 2. {Second card idea}

| Option | Front | Back |
| --- | --- | --- |
| A ⭐ | {Exact question.} | {Exact answer.} |
| B | {Alternative question.} | {Alternative answer.} |
| C | {Alternative question.} | {Alternative answer.} |
```

The image block is conditional for each card. Use real preview paths or URLs in the rendered message. End the display after the last card's options or image, following the presentation guidance in [SKILL.md](SKILL.md).

Keep concept labels outside the card content. Omit repeated workflow reminders, approval totals, and recommendation rationales unless Michael asks. If code, images, or longer content would make the table hard to read, use three blocks labeled A, B, and C with compact Front and Back labels instead. Include any notes or media needed to approve an option, but keep them outside its prompt and answer.

Hide source references and citations in all review rounds, including revisions and alternatives. Retain them with each draft, including image sources or generation provenance, and include them in the final Anki card, separate from the tested answer and using the existing note format.

For cloze cards, replace Front and Back with **Prompt** and **Reveal**. Show the review prompt with the deletion as `[…]`, then the full text with the revealed answer in bold. Preview each distinct generated card when a note has multiple cloze numbers, so Michael can approve what he will actually review. Show proposed images inline.

On revision turns, show all changed or unresolved ideas together with three options each. Mark changed idea headings as `{card number}. {card idea} · Revised`. Keep the card number and A/B/C labels, but require a new selection if the previously approved text changes. Preserve approvals for unchanged selected versions. Accept natural-language selections and feedback without requiring the example reply syntax.

## Add the round and move on

Once Michael has demonstrated understanding and every retained card in the current round is approved, with no content or media pending, add that round's approved versions to the `All` deck through the Anki MCP. Completion of the round's approvals authorizes these writes without another confirmation. If Michael explicitly requested drafts only, deliver the approved drafts for that round and start the next concept without writing to Anki.

Read back the affected notes and verify their content, retained sources, formatting, and deck as required by [SKILL.md](SKILL.md). For selected images, verify that the media is stored in Anki and the note references it in the approved location. If only part of the round succeeds, track what was added before retrying so cards are not duplicated. Resolve or report a write or verification blocker before moving on; keep the round pending until it is resolved or Michael redirects the work.

After verification, briefly report how many cards were added for this concept and start the next round with its understanding question. If Michael removed every card, acknowledge that there is nothing to add and move on. After the last round, report the total added and any concepts Michael chose to leave unfinished.
