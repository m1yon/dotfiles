---
name: file-pr
description: File a Pull Request. Use when the user asks to file, open, or create a PR.
---

Follow Google’s Engineering Practices Code Review Guidelines when creating or reviewing pull requests, including both the Change Author’s Guide and Code Reviewer’s Guide.

Before filing a PR, count the changed files relative to its base branch. If it changes more than 15 files, use $gh-stack to split the work into a stack of cohesive PRs, each changing at most 15 files relative to its own base branch.
