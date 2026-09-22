# Creating cards flow

Work through Michael's source material one concept per round. Establish understanding, review the cards together, then add and verify the approved round before advancing. Draft-only requests use this flow without Anki writes.

## Read and organize

Read the source and identify the learning objective, useful concepts, and prerequisites. Ask for missing or inaccessible material before working on affected concepts. Resolve unsupported or ambiguous claims before using them to assess understanding or draft cards.

Give a brief overview with prerequisites first, then begin the first round. Draft its cards only after Michael demonstrates understanding.

## Test understanding

Ask one focused, open-ended question that requires explanation, a relevant distinction, or application. Keep the expected answer and proposed cards out of the question, then wait for Michael's answer.

Assess his answer against the source, accepting equivalent wording. Understanding is demonstrated when he explains the central idea accurately and reasons through an application or relevant distinction without a material misconception. One answer can establish both. Ask a follow-up only for missing evidence; a claim of understanding or repetition of an answer just supplied is insufficient.

If his answer reveals a gap, explain that point and ask a fresh question that checks whether he can use it. Once he meets the criterion, briefly name what his answer demonstrated and proceed to cards.

Use this display, omitting the total if unknown:

```markdown
### Round {round} of {total rounds}: {concept}

Understanding check

{One focused question requiring explanation or application.}
```

## Draft the round

Apply [Formulate and inspect](SKILL.md#formulate-and-inspect) to the concept Michael just demonstrated. Use the source and discussion to select useful facts and distinctions. Let those recall targets determine the number of cards; keep every card within the current concept.

For each target, prepare exactly three distinct options labeled A, B, and C. Vary wording or approach while testing the same target. Inspect every option before presenting it, then recommend one for clarity and ease of recall. These are alternatives for one card, not three cards to add.

Number ideas from 1 across the entire session. Preserve numbers through revisions and rounds; give new ideas the next unused number. Track the exact displayed versions and their approval status.

## Display the round

Show all ideas and complete option text together in one message. Put a star immediately after the recommended letter, as below, without a "Recommended" label. Consider images under [Choose useful images](SKILL.md#choose-useful-images), and include the conditional image block beneath that card's options.

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

Preview one proposed image per card beneath its text options, labeled with the proposed front or back placement and a short description of its role. Use a real preview path or URL. For occlusion, show the masked front and answer reveal so Michael can approve the recall task. If the image cannot be obtained or displayed, identify the missing preview and keep media approval pending.

Track text approval separately from approval of the image and its placement:

- "With image" approves the displayed image at its proposed placement.
- "On the front" or "on the back" selects the displayed image at that placement. Check that it works with the chosen text and preserves the recall task.
- "No image" approves omitting it.
- Text selection alone leaves an offered image pending.

Check that the chosen text works with the selected image and placement, or without the image if omitted. If this requires revised text, a new mask, or another image change, preview the revision and obtain approval for the changed parts. A placement request authorizes a straightforward move; preserve approvals for unchanged text and media. For existing cards, complete any pending image approval before writing the chosen revision.

## Review selections and revisions

Michael prefers one selection per line, such as `8. A`. Accept any unambiguous wording, including a letter alone when only one card is under discussion. A selection refers to the latest displayed version. Recommendations and silence never count as approval; unmentioned cards stay pending. Clarify only ambiguous choices and retain the rest.

For requested changes, show all changed or unresolved ideas together with three options each and one recommendation. Mark changed headings as `{card number}. {Card idea} · Revised`. Preserve numbering and approvals for unchanged versions; changed text requires a new selection. Follow [SKILL.md](SKILL.md) when Michael dislikes a card and the image approval rules above for media changes.

If discussion reveals a misunderstanding, return to a focused understanding check before finalizing affected cards. Keep the round as drafts until every retained idea has approved text and any offered image has an approved placement or an explicit decision to omit it. Michael may remove ideas from the round.

## Add the round and move on

Once understanding is demonstrated and every retained card is approved with no content or media pending, add the approved versions to `All` through the Anki MCP. These approvals authorize the writes without another confirmation. For draft-only requests, deliver the approved drafts and advance without writing.

Verify writes as required by [SKILL.md](SKILL.md#verify-writes). If only part of a round succeeds, track completed writes before retrying to avoid duplicates. Resolve or report write and verification blockers; keep the round pending until resolved or Michael redirects the work.

After verification, briefly report how many cards were added and begin the next concept with its understanding question. If Michael removed every card, acknowledge that there is nothing to add and advance. After the last round, report the total added and any concepts Michael chose to leave unfinished.
