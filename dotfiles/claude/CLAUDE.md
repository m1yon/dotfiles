- When running project-specific commands (lint, test) use the `task` version if a Taskfile exists for the project.
- When using the `gh` CLI, always use the `--json` flag when the sub-command supports it.
- Before the first edit, run `pwd` and `git status`. If cwd is a worktree, edit there — don't use an absolute path to the main repo even if it resolves to the "same" file.

## Plan Mode

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Code Style

**STRICT COMMENTING PHILOSOPHY**
Your comments must capture information that the code itself cannot express. Code describes the "how"; comments must describe the "what" and the "why". When generating or modifying code, you must strictly obey these rules:

1. **Abstract, Don't Duplicate:** Never translate code into English. If a comment simply explains *how* the code underneath it works, do not write it. Assume the reader is a highly competent engineer.
2. **Document the Contract (Interfaces):** For exported functions, types, and packages, write high-level comments that explain *what* the entity does, its arguments, return values, and any hidden side-effects. Completely hide the implementation details in these comments.
3. **Explain the 'Why' (Implementation):** Inside a block of code, only write comments to document high-level design decisions, non-obvious business logic, or the rationale behind a counter-intuitive workaround. 
4. **Default to Silence:** Prioritize making the code obvious through clear naming and structural simplicity. If the code is self-documenting, omit the comment entirely.
