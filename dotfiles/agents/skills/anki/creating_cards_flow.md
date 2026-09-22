# Creating cards flow

Use this flow to turn Michael's source material into cards, review them together, and add the approved set to Anki.

## Read and draft

1. Read the source Michael provides. If it is inaccessible or incomplete, ask for the missing material before drafting affected cards.
2. Identify the concepts worth learning and their prerequisites. Draft cards that follow all applicable principles in $formulating-knowledge and the formatting and preferences in [SKILL.md](SKILL.md). Preserve the source's qualifications and provenance; resolve unsupported or ambiguous claims before treating a card as ready.
3. Inspect each card on its own, with its answer hidden, using the checks in $formulating-knowledge. Repair unclear prompts and overloaded recall targets before showing the cards.
4. Group cards with similar concepts into rounds. Put prerequisite rounds before dependent ones. Aim for 3–5 cards per round, using fewer when a concept group is small or the cards need more discussion.

## Review one round at a time

Use the round display template below. Give each card a stable ID and show its complete proposed prompt and answer, or cloze text, plus any notes or media Michael needs to approve. Ask which cards he approves and what he wants changed, then wait for his response before presenting the next round.

Track each card's current version and whether it is pending, approved, or removed. Approval applies only to the version Michael has seen. Treat partial approval as approval of only the named cards; silence does not approve the rest.

Work with Michael on requested changes within the current round. When he dislikes a card, use the three-alternative workflow in [SKILL.md](SKILL.md). Show revised cards for approval; selecting a fully shown alternative approves that version. Keep other approvals intact unless those cards also change. Continue until every card in the round is approved or Michael has chosen to remove it, then move to the next round.

Keep all cards as drafts throughout the rounds. Approval of an individual card or round does not trigger an Anki write.

### Round display template

Render this template as Markdown in the conversation, replacing placeholders and repeating the card block for each card. Use stacked card blocks instead of a table so longer answers, code, and images remain readable. Number cards across the whole set as C01, C02, and so on; keep those IDs through revisions.

```markdown
### Round {round} of {total rounds}: {shared concept}

{cards in this round} cards to review · {approved cards}/{total cards} approved overall
All cards stay in draft until the full set is approved.

#### C01 · {short concept label}

**Front**
{Exact question Michael would see during review.}

**Back**
{Exact answer.}

---

#### C02 · {short concept label}

**Front**
{Exact question.}

**Back**
{Exact answer.}

---

Approve this round, or tell me what to change.
You can reply "approve all", "approve C01; shorten C02", or "remove C02".
```

Keep concept labels and progress outside the card content. Omit the total round count if it is not yet known. Hide source references and citations in all review rounds, including revisions and alternatives. Retain them with each draft and include them in the final Anki card, separate from the tested answer and using the existing note format. Show other notes beneath the relevant answer only when they will be saved with the card or are needed for a decision. Avoid a rationale for every card.

For cloze cards, replace Front and Back with **Prompt** and **Reveal**. Show the review prompt with the deletion as `[…]`, then the full text with the revealed answer in bold. Preview each distinct generated card when a note has multiple cloze numbers, so Michael can approve what he will actually review. Show proposed images inline.

On revision turns, show only changed or unresolved cards using the same layout. Mark changed cards as `C02 · {concept label} · Revised` and briefly state what changed outside the card content. Summarize already approved IDs in one line. End with a request to approve the remaining cards; "approve all" applies only to the cards displayed in that turn, never unseen rounds. Accept natural-language feedback without requiring the example reply syntax.

## Add the approved set

Once every retained card across all rounds is approved and no content or media is pending, add the approved versions to the `All` deck through the Anki MCP. Completion of the approvals authorizes this final batch without another confirmation. If Michael explicitly requested drafts only, deliver the approved drafts and wait for a request to add them.

Read back the affected notes and verify their content, retained sources, formatting, and deck as required by [SKILL.md](SKILL.md). Report how many cards were added. If only part of the batch succeeds, track what was added before retrying so cards are not duplicated.
