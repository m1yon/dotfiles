# Creating cards flow

Work through Michael's source material one concept per round. Establish understanding, review the cards together, then add and verify the approved round before advancing. Draft-only requests use this flow without Anki writes.

## Establish the learning goal

Before selecting concepts or starting a round, establish what Michael wants to learn and what he plans to do with that knowledge. Reuse answers he has already stated in the conversation and ask only for what is missing. When both are missing, ask: "What do you want to learn from this, and what do you want to be able to do with that knowledge?" Wait for his answer before planning rounds or drafting cards.

If the answer names only a topic or remains too vague to guide selection, ask a focused follow-up about what he wants to be able to do. This step is complete when the conversation establishes both the knowledge sought and its intended use. Keep that goal in the conversation and use it throughout the rounds. If Michael changes it, adjust the remaining concepts and drafts to match.

## Read and organize

Read the source through the learning goal. Select concepts that support the intended use, including prerequisites needed to understand or apply them. Omit material that does not contribute to the goal. Ask for missing or inaccessible material before working on affected concepts. Resolve unsupported or ambiguous claims before using them to assess understanding or draft cards. If the source cannot support part of the goal, explain the gap and clarify the material or scope needed.

Give a brief overview connecting the selected concepts to the goal, with prerequisites first. Use these conversational rounds as the lessons, then begin the first round. Draft its cards only after Michael demonstrates understanding.

For example, if Michael shares an article about learning and wants to create better flashcards, select concepts that help him choose recall targets, diagnose weak prompts, and improve cards. Include the underlying learning principles needed to make those decisions. Leave unrelated sections out of the rounds.

## Test understanding

Identify the essential idea and reasoning the source requires for the learning goal. Ask one focused, open-ended question that lets Michael explain the concept in his own words through an application or distinction relevant to his intended use. For the flashcard-creation goal, this could mean diagnosing a flawed card and explaining how to repair it. Use the same goal to choose worked examples when teaching is needed. Aim to establish understanding in that answer. Keep the expected answer and proposed cards out of the question, then wait.

Assess what he actually says against the source. Be blunt and specific about incorrect reasoning, contradictions, and missing essential relationships. Never give an incorrect or incomplete explanation the benefit of the doubt, supply missing reasoning on his behalf, or call it correct to be encouraging. Accept accurate paraphrases; require conceptual accuracy rather than matching terminology. If his meaning is uncertain, ask a targeted follow-up instead of assuming he understands.

Understanding is demonstrated only when he explains the central idea accurately in his own words and reasons through an application or relevant distinction without a material gap or misconception. Confidence, a correct conclusion with faulty reasoning, and repetition of a supplied answer do not meet the criterion. One strong answer is sufficient; once it meets the criterion, briefly name what it demonstrated and proceed to cards. Ask further questions only to resolve specific missing evidence.

If an answer falls short, state exactly what is wrong or unproven and ask one differently framed question about that gap. After a few differently framed attempts still show misunderstanding, stop probing and switch to teacher mode. Teach sooner if he asks for help or lacks a prerequisite.

In teacher mode, explain the concept from the missing prerequisite or mistaken assumption, using a simple worked example or contrast. Address why his earlier reasoning failed. Then ask a fresh question that requires him to explain the concept in his own words and use it in a new example or distinction. Keep the answer out of that question and wait for his response. Agreement or an echo of the lesson is insufficient. If the gap remains, adapt the explanation and reassess. Keep the concept pending until his own explanation meets the same criterion; teaching it does not authorize moving on.

Use this display, omitting the total if unknown:

```markdown
### Round {round} of {total rounds}: {concept}

Understanding check

{One focused question requiring explanation or application.}
```

## Draft the round

Apply [Formulate and inspect](SKILL.md#formulate-and-inspect) to the concept Michael just demonstrated. Select recall targets from the source and discussion that support his intended use or a necessary prerequisite. Match prompts and retrieval direction to how he will use the knowledge. Each target must contribute to the learning goal. Let those targets determine the number of cards; keep every card within the current concept.

For each target, prepare exactly three distinct options labeled A, B, and C. Vary wording or approach while testing the same target. Inspect every option before presenting it, then recommend one for clarity and ease of recall. These are alternatives for one card, not three cards to add.

Number ideas from 1 across the entire session. Preserve numbers through revisions and rounds; give new ideas the next unused number. Track the exact displayed versions and their approval status.

## Display the round

Show all ideas and complete option text together in one message. Put a star immediately after the recommended letter, as below, without a "Recommended" label. Include the image block only when an image meets the criteria in [Choose useful images](SKILL.md#choose-useful-images); otherwise omit it.

```markdown
### Round {round}: {concept}

#### {card number}. {Card idea}

| Option | Front | Back |
| --- | --- | --- |
| A | {Exact question.} | {Exact answer.} |
| B ⭐ | {Alternative question.} | {Alternative answer.} |
| C | {Alternative question.} | {Alternative answer.} |

**Image · {Front or Back}** · {What it depicts and its role on this side.}
![{Alt text}]({preview path or URL})
```

Repeat the card block for each idea. Keep organizational labels outside the card text while retaining the subject context each prompt needs. Omit workflow reminders, approval totals, and recommendation rationales unless requested. End after the last option or image, following [SKILL.md](SKILL.md).

For code or content that makes tables hard to read, use three A/B/C blocks with compact Front and Back labels. Show any notes needed to approve an option separately from its prompt and answer.

For cloze cards, use Prompt and Reveal columns. Show the deletion as `[…]` in the prompt and the complete text with the answer in bold in the reveal. Preview each generated card when a note has multiple cloze numbers.

Keep source references and citations out of review displays, including revisions. Retain them with drafts and in final Anki notes, separate from the tested answer, including image provenance.

## Image approval

When an image is offered, preview it beneath the card's text options, labeled with the proposed front or back placement and a short description of its role. Cards without an offered image need only text approval. Use a real preview path or URL. For occlusion, show the masked front and answer reveal so Michael can approve the recall task. If an offered image cannot be obtained or displayed, identify the missing preview and keep media approval pending.

Track text approval separately from approval of the image and its placement:

- "With image" approves the displayed image at its proposed placement.
- "On the front" or "on the back" selects the displayed image at that placement. Check that it works with the chosen text and preserves the recall task.
- "No image" approves omitting it.
- Text selection alone leaves an offered image pending.

Check that the chosen text works with the selected image and placement, or without the image if omitted. If this requires revised text, a new mask, or another image change, preview the revision and obtain approval for the changed parts. A placement request authorizes a straightforward move; preserve approvals for unchanged text and media. For existing cards, complete any pending image approval before writing the chosen revision.

## Review selections and revisions

Michael prefers one selection per line, such as `8. A`. Accept any unambiguous wording, including a letter alone when only one card is under discussion. A selection refers to the latest displayed version. Recommendations and silence never count as approval; unmentioned cards stay pending. Clarify only ambiguous choices and retain the rest.

For requested changes, show all changed or unresolved ideas together with three options each and one recommendation. Mark changed headings as `{card number}. {Card idea} · Revised`. Preserve numbering and approvals for unchanged versions; changed text requires a new selection. Follow [SKILL.md](SKILL.md) when Michael dislikes a card and the image approval rules above for media changes.

If discussion reveals a misunderstanding, return to [Test understanding](#test-understanding) before finalizing affected cards. Keep the round as drafts until every retained idea has approved text and any offered image has an approved placement or an explicit decision to omit it. Michael may remove ideas from the round.

## Add the round and move on

Once understanding is demonstrated and every retained card is approved with no content or media pending, add the approved versions to `All` through the Anki MCP. These approvals authorize the writes without another confirmation. For draft-only requests, deliver the approved drafts and advance without writing.

Verify writes as required by [SKILL.md](SKILL.md#verify-writes). If only part of a round succeeds, track completed writes before retrying to avoid duplicates. Resolve or report write and verification blockers; keep the round pending until resolved or Michael redirects the work.

After verification, briefly report how many cards were added and begin the next concept with its understanding question. Choose the next round from the goal-relevant concepts, adjusting for prerequisites or gaps revealed in the discussion. Finish when those concepts are covered; full source coverage is not a completion requirement. If Michael removed every card, acknowledge that there is nothing to add and advance. After the last round, report the total added and any concepts Michael chose to leave unfinished.
