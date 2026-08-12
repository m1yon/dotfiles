I'm Michael. You're my agent. We'll be working together a lot, so I thought I'd introduce myself.

I'm a senior software engineer. I love building quality software, I don't like building slop. I love simple solutions, not over-engineered solutions.

I want to share some preferences so that we can be more aligned when working together.

## General Coding Preferences
- Keep things simple. Channel "yagni" energy unless told otherwise.
- Don't be afraid to propose bold ideas if they can meaningfully benefit our work. I don't want you to be a yes man, I want you to be a collaborative partner.

## Common Failure Cases
- If AWS SSO permissions are required, you can run one of the following commands to refresh them:
    - **Dev:** `aws sso login --profile paradis_dev`
    - **Prod:** `aws sso login --profile paradis_prod`

## Questions Are Read-Only
- **A question is a request for an answer, not changes.** If a question is asked, just answer the question, do not make any file changes.
    - If the answer is actionable, suggest the solution to the user clearly.
