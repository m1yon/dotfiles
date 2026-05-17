---
description: Picks up issue .md files in a directory and solves them in individual sub-agents. 
---

## Instructions
- I'll specify a directory below. I want you to crawl through that directory and any sub-directories picking up any issue .md files as well as the PRD .md file.
- Read the PRD and determine the dependency order the issues must be solved in.
- For each issue, spawn an sub-agent to solve the issue sequentially. Give it a link to the local issue markdown file to view.
    - Each sub-agent should:
        - Read the issue markdown file and PRD markdown file.
        - Solve the issue. The sub-agent should use TDD (red-green-refactor) if tests are mentioned in the issue.
        - It should ensure the tests/linter passes (only run against files that were changed in order to conserve time).
        - Once everything is verified working, the sub-agent should update the status on the .md issue file.
        - It should make a commit using the conventional commits format.

## Issue Directory
