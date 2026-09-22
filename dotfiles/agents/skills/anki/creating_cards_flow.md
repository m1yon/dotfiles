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

Explain your reasoning in your own words.
```

## Draft and review the round's cards

Draft cards for the concept Michael has just demonstrated, following all applicable principles in $formulating-knowledge and the formatting and preferences in [SKILL.md](SKILL.md). Use the discussion to identify useful distinctions and facts to retain. Aim for a handful of cards, usually 3–5, but use fewer when the concept needs fewer. Keep every card within this round's concept.

Inspect each card on its own, with its answer hidden, using the checks in $formulating-knowledge. Repair unclear prompts and overloaded recall targets before showing the cards.

Present one card idea at a time using the template below. For every proposed card, offer exactly three distinct front/back options for the same recall target. Vary the wording or approach while keeping each option valid under $formulating-knowledge. Mark one option as recommended based on clarity and ease of recall. Show the complete proposed text for all three, then wait for Michael to choose or request changes before presenting another card idea.

Give each card idea a stable ID and track its options, selected version, and whether it is pending, approved, or removed. Choosing an option approves only that version. The recommendation is not a default selection; silence does not approve it. If approval does not identify an option, ask which one Michael wants.

Work with Michael on requested changes within the current round. When he dislikes a card, use the three-alternative workflow in [SKILL.md](SKILL.md). Use the same concise template for revised options and mark one recommendation. Keep other approvals intact unless those cards also change. If the discussion reveals a remaining misunderstanding, return to a focused understanding check before finalizing affected cards. Continue until every card idea in the round has an approved version or Michael has chosen to remove it.

Keep the current round's cards as drafts until the whole round is approved. Then add and verify them as described below before starting the next concept.

### Round display template

Render this template as Markdown in the conversation, replacing placeholders. Number card ideas across the whole set as C01, C02, and so on; keep those IDs through revisions. Options 1–3 are alternative versions of one card, not three cards to add. Mark the strongest option as recommended wherever it appears.

```markdown
### Round {round}: {concept}

C01 · {card idea}

| Option | Front | Back |
| --- | --- | --- |
| 1 | {Exact question.} | {Exact answer.} |
| 2 · Recommended | {Alternative question.} | {Alternative answer.} |
| 3 | {Alternative question.} | {Alternative answer.} |

Choose 1, 2, or 3, or tell me what to change.
```

Keep concept labels outside the card content. Omit repeated workflow reminders, approval totals, and recommendation rationales unless Michael asks. If code, images, or longer content would make the table hard to read, use three numbered blocks with compact Front and Back labels instead. Include any notes or media needed to approve an option, but keep them outside its prompt and answer.

Hide source references and citations in all review rounds, including revisions and alternatives. Retain them with each draft and include them in the final Anki card, separate from the tested answer and using the existing note format.

For cloze cards, replace Front and Back with **Prompt** and **Reveal**. Show the review prompt with the deletion as `[…]`, then the full text with the revealed answer in bold. Preview each distinct generated card when a note has multiple cloze numbers, so Michael can approve what he will actually review. Show proposed images inline.

On revision turns, show only the current card idea and its three options. Mark it as `C01 · {card idea} · Revised`. Accept natural-language selections and feedback without requiring the example reply syntax.

## Add the round and move on

Once Michael has demonstrated understanding and every retained card in the current round is approved, with no content or media pending, add that round's approved versions to the `All` deck through the Anki MCP. Completion of the round's approvals authorizes these writes without another confirmation. If Michael explicitly requested drafts only, deliver the approved drafts for that round and start the next concept without writing to Anki.

Read back the affected notes and verify their content, retained sources, formatting, and deck as required by [SKILL.md](SKILL.md). If only part of the round succeeds, track what was added before retrying so cards are not duplicated. Resolve or report a write or verification blocker before moving on; keep the round pending until it is resolved or Michael redirects the work.

After verification, briefly report how many cards were added for this concept and start the next round with its understanding question. If Michael removed every card, acknowledge that there is nothing to add and move on. After the last round, report the total added and any concepts Michael chose to leave unfinished.
