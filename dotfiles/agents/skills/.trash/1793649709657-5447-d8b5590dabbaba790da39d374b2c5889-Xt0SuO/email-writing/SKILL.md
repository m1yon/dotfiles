---
name: "email-writing"
description: "Write emails in Michael Lyon's voice and format. Use whenever drafting, replying to, rewriting, or polishing an email (or a Teams/Outlook message that reads like an email) for Michael, including new threads, replies, forwards, follow-ups, and subject lines."
---

# Email writing in Michael's voice

Michael writes short, direct, friendly-professional emails. He leads with the point, explains cause and next step plainly, and closes the same way every time. Match this exactly. These rules come from his Outlook Sent Items (about 75 sent emails from May to October 2026, to internal teammates, health plan partners, and vendors).

## Structure

Every standard email has this shape:

```
Hey <First name>,

<Point in the first sentence. 1-3 short paragraphs total.>

<Optional closing line: an ask, an offer, or a friendly note.>

Thanks,
Michael Lyon
```

- Put one blank line between the greeting, each paragraph, and the sign-off.
- Put "Thanks," and "Michael Lyon" on separate lines. Never use "Best," "Regards," "Cheers," "Sincerely," or a title or company signature block.
- Keep "Thanks," as the sign-off even when the body already thanked them ("Thanks for passing this along!" followed by "Thanks,").

## Greeting

- Default: "Hey <First name>," for everyone, including external partners at health plans and vendors.
- Two people: "Hey Dolly and Stefanie,"
- Internal group or team: "Hey Team," or "Hey Everyone,"
- Shared mailbox or unknown person: "Hey,"
- "Hi <First name>," is acceptable only for a cold first message to someone he has never emailed.
- Use the name the person goes by if it is known from the thread (for example "Cindy" for Cynthia). Otherwise use the first name from the sender field. Never use last names or "Mr./Ms."

## Length and openers

- Most emails are 1-4 sentences. A long email is about 150 words. If a draft is longer, cut it.
- The first sentence after the greeting carries the main point. No warm-up. Never write "I hope this email finds you well," "I hope you're doing well," or "I'm reaching out to...".
- Openers he uses:
  - "Thanks for the update." / "Thanks for the detailed walkthrough!" (then go straight to the substance)
  - "Attached is/are ..." for attachments: "Attached is our proposal for maintaining/improving the MECA website."
  - "Here's the <thing>: <link>"
  - "Confirmed." as a one-word first sentence when confirming a plan
  - "I've <done X>." when reporting finished work: "I've updated the Payer ID for UnitedHealthcare to 87748 across all billing hubs."
  - "I wanted to give you a heads-up on ..." for a problem the reader doesn't know about yet
  - "You can ignore this; ..." to wave off an automated or mistaken email

## Voice

- Use contractions everywhere: we'll, I've, it's, don't, they're, we'd.
- Use "we/our team" for company work and decisions, and "I" for work he personally did or found.
- Be plain and concrete. Name the actual report, system, date, ID, or error. Spell out what happened, why, what was done, and what is needed from the reader, in that order.
  - Example: "I've investigated this, and the issue was caused by adding the new 'Referred back to MCO' to our reporting logic but not adding it to the rules service logic. I've since updated the rules service to account for this, so it'll be fixed moving forward, but we do need someone on our side to contact Jocelyn's team to resolve these overbilled claims."
- Make ownership explicit when it matters: "Isaiah and I manage the claims config, but Vera and her team manage actual operations around billing."
- Ask politely and directly with "Could you ...?" or "Can you confirm if ...?" Soften with "when you get a chance" for internal asks.
- When a change is optional or needs their decision, offer it instead of pushing: "If you'd like us to scope out a change to ..., just let us know."
- Apologies are one short clause, not a paragraph: "Sorry for the inconvenience, have a great weekend!" or "Sorry, didn't mean to send an email."
- No corporate filler: no "please don't hesitate to reach out," "circle back," "touch base," "at your earliest convenience," "per my last email," or "going forward" when "moving forward" or nothing works.
- Use at most one or two exclamation points per email, usually on a friendly closing line ("We'll send the real one tomorrow!", "Let me know if you need anything else!"). The body stays calm.
- Semicolons are fine for joining two short related clauses: "The emails that begin with 'Report Ready' are just emails; they don't have an approval step."
- Do not use em dashes. Use a period, a comma, or a semicolon instead.
- Use straight quotes and apostrophes.

## Closing line (optional, before "Thanks,")

Pick one or none. Use only when it adds something:
- "Let us know if you have any questions." (external, or speaking for the team)
- "Let me know if you need anything else!" (personal help)
- "Let us know if you have any questions or need any clarification on the notes."
- "Let us know if you'd like us to adjust."

## Formatting

- Default to plain paragraphs. No headers.
- Use a bulleted list when there are 2 or more parallel items (notes, current behaviors, discrepancies). Introduce it with a short line ending in a colon: "Things to note:" or "Currently, we've been:". Each bullet is one or two full sentences.
- When replying to several topics, start each paragraph with the topic name in bold and a colon, then the answer: "**Molina:** I went ahead and updated the Payer ID in Pear Suite to MLNNM."
- Bold a word only to contrast two key terms the reader could confuse ("anchor to the **completion date**, not the **due date**"). Never bold whole sentences.
- Put quoted error messages in italics inside quotes: *"This account lacks permission to send envelopes over SMS."*
- Link files with the file name as the link text ("Here's the BCBS Compliance Report: bcbs_compliance_report_2026-06-12.xlsx"), not "click here."
- Write dates as "September 5" or "Thursday's meeting". Use "by EOD" for same-day deadlines. Include time zone for exact times ("1:50 PM MDT").

## HTML drafts (Outlook and other HTML mail)

Outlook shows `<p>` tags with no space between them, so a draft built from `<p>` paragraphs comes out with every line jammed together. The blank lines have to be real empty lines in the HTML.

- Put each line in its own `<div>`, and put `<div><br></div>` wherever a blank line belongs: after the greeting, between paragraphs, before "Thanks,", and after "Michael Lyon" so the quoted thread doesn't butt against the signature.
- "Thanks," and "Michael Lyon" are two back-to-back `<div>`s with no blank line between them.
- Don't use `<p>` for paragraphs in HTML drafts.
- Lists can stay as `<ul><li>`; put a `<div><br></div>` before and after the list.
- Template:

```html
<div>Hey Vera,</div>
<div><br></div>
<div>First paragraph.</div>
<div><br></div>
<div>Closing line!</div>
<div><br></div>
<div>Thanks,</div>
<div>Michael Lyon</div>
<div><br></div>
```

- For plain-text drafts (Gmail or bodyType "text"), use real blank lines (two newlines) in the same places.
- Editing a reply draft's body with an update tool usually replaces the whole body, quoted thread included. To fix a reply draft's wording or spacing, create a new reply draft and delete the old one instead.

## Subject lines (new threads)

- A short descriptive noun phrase in title case that names the specific thing: "Core Project Invoices Switching to Monthly", "SFTP Host Key Change", "Members Not Sharing to Sub-Organizations Bug", "Molina Disposition Report vs Report 83 Timeframe Data Discrepancy", "Report 83 v4 Instructions".
- No "Quick question," "Following up," "Urgent," or emojis.
- For replies, keep the existing subject.

## Variants

**Quick internal reply in an ongoing thread.** Can drop the greeting, and for a single line, the sign-off too:
- "If the CCP was completed before 10/11/2025, the only way to get it into the new format is by completing a new Care Plan activity."
- "I'm free anytime today or anytime past 9am tomorrow."

**Forward.** Usually no note. If adding one, write one or two sentences with no greeting or sign-off: "Did you want to respond to this one? This is the one we talked about, where I asked whether a name change affects Medicaid coverage."

**External partner, health plan, or vendor.** Same "Hey <First name>," and same tone. Slightly more context, since they don't know internal details. State the impact plainly, then the specific ask.

## Examples from Michael's sent mail

Short confirmation to an external partner:
```
Hey Andrew,

Confirmed. The October 5 submission will include the Disposition Report and the new Molina Monthly Compliance Report for comparison.

Thanks,
Michael Lyon
```

Problem report to a vendor:
```
Hey Henry,

After today's upgrade from Business Pro to Enterprise Pro, our production integration is failing whenever it attempts to send envelopes via SMS.

The error we're getting from DocuSign is: "This account lacks permission to send envelopes over SMS."

Since SMS delivery is essential for recipients without email addresses, this issue is preventing some signature requests from going through. It looks like the Send with SMS feature might not have transitioned to the new plan.

Could you review our subscription and re-enable SMS delivery for the MECA Therapies production account?

Thanks,
Michael Lyon
```

Internal team heads-up:
```
Hey Everyone,

This was a test generation that accidentally got sent out. If you ever see [DEV] in the email title, you can ignore it.

We'll send the real one tomorrow!

Thanks,
Michael Lyon
```

Reply covering several topics:
```
Hey Hannah,

Thanks for the updates! Here's where we're at with each:

**UnitedHealthcare:** Our team is responsible for getting the claims into the Generated status, then Jocelyn's team handles it from there. Any actual claim errors are typically handled by Vera and her team.

**Molina:** I went ahead and updated the Payer ID in Pear Suite to MLNNM.

**Presbyterian:** I'd forward this request to Vera. Isaiah and I manage the claims config, but Vera and her team manage actual operations around billing, including working with the health plan MPOCs.

Let me know if you need anything else!

Thanks,
Michael Lyon
```

Asking for alignment with a list:
```
Hey Dolly,

I agree, there's a lot of conflicting information in the Report 83 requirements. Your recap is accurate, and I appreciate you documenting BCBS's approach.

Following our discussion, can you confirm if there's anything we need to adjust for the compliance report? We want to ensure alignment with your expectations.

Currently, we've been:
- Including only members in tab 2 who have been leveled to CCL1 or CCL2 at some point during their delegation
- Refreshing past months when members become CCL1/CCL2 later in their delegation

We understand BCBS uses the full population in the details tab, so your percentages may differ. Let us know if you'd like us to adjust.

Thanks,
Michael Lyon
```

## Final check before returning a draft

1. Does it open with "Hey <name>," (or the right variant) and end with "Thanks," / "Michael Lyon"?
2. Is the main point in the first sentence?
3. Can any sentence be cut without losing information? Cut it.
4. Are there any em dashes, "I hope this finds you well," "Best regards," or corporate filler? Remove them.
5. Are there more than two exclamation points? Reduce them.
6. For an HTML draft, is every blank line a real `<div><br></div>` (not just separate `<p>` tags)?
7. Never include member or patient names, dates of birth, or Medicaid IDs unless Michael supplied them for this email and the recipient is internal or the health plan that owns the record.