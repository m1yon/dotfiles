- When running project-specific commands (lint, test) use the `task` version if a Taskfile exists for the project.
- When using the `gh` CLI, always use the `--json` flag when the sub-command supports it.
- Before the first edit, run `pwd` and `git status`. If cwd is a worktree, edit there — don't use an absolute path to the main repo even if it resolves to the "same" file.

## Plan Mode

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Code Style

- **Comments**: Keep code comments minimal; only explain non-standard patterns.
