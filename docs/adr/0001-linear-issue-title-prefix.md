# Linear issue title prefix

Issues created via the `linear-triage`, `linear-to-prd`, and `linear-to-issues` skills must prefix their titles with `[<repo>] ` (bracketed repo name, single space, then the title — e.g. `[dotfiles] store repo in linear issues`). This lets one Linear team back multiple repos and lets `tide` validate at run-start that the working repo matches the issue.

`<repo>` is derived at issue-creation time by parsing `git remote get-url origin`: take the last path segment and strip a trailing `.git`. If `origin` is unset, the skill hard-stops — same pattern as the missing-`.tide/config.ts` hard-stop.

## Considered options

- **Format:** `<repo>: <title>` (rejected — colon collides with common title punctuation), `<repo>/<title>` (rejected — slash reads as a path), `[<repo>] <title>` (chosen).
- **Source of `<repo>`:** `basename($(git rev-parse --show-toplevel))` (rejected — silently drifts when a clone is renamed), new `repo.name` field in `.tide/config.ts` (rejected — adds config-migration friction; tide already needs git available), `git remote get-url origin` parse (chosen — survives folder rename, no new config).
