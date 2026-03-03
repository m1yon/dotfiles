---
description: Resolve feedback
agent: build
---

For each feedback comment received, I want you to:
1. Ask me using the answer tool if I'd like you to resolve this feedback
    - If yes, continue to 2.
    - If no, move on to the next feedback comment and start again from 1.
2. Spawn a sub-agent, giving it the feedback and instructing it to fix the feedback.
3. Once the sub-agent completes, use the answer tool to ask if I approve the feedback, or if I'd like to work with you more on the feedback.
4. If I do approve it, I'd like you to stage and commit the changes, then move on to the next feedback comment and start again from 1.
