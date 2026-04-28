---
name: pull-request
description: Write a pull request for the current branch with the body focused on public interface changes. Use when the user wants to create a PR, write a PR description, open a pull request, or update a PR body.
---

# Pull Request

Write a PR for the current branch. The body emphasizes what changed at the **public interface** — the surface other modules depend on — over private implementation churn.

This mirrors Ousterhout's view: interface change is the change that matters to callers. Deep modules expose little; a good PR description reflects that by spending most of its words on the small surface that actually shifted, not the large body of internals that did.

## Process

### 1. Check branch state

```bash
git status
gh pr view --json number,url,title,body 2>/dev/null
```

If a PR already exists, ask: update the existing body, or abort?

If the working tree is dirty, show the uncommitted files and ask the user: stage and commit them (and if so, with what message), or abort so they can handle it themselves. Never stage/commit silently.

### 2. Ask draft or ready-for-review

Use the `AskUserQuestion` tool early to ask: **draft or ready-for-review?** Do this before drafting the body so the answer is ready when it's time to push.

### 3. Find the linked PRD issue

Check the conversation context for a referenced GitHub issue (PRD). If none, search:

```bash
gh issue list --label prd --json number,title,url --limit 20
```

Confirm the match with the user before proceeding. Add `Closes #<num>` at the end of the PR body so merging auto-closes it. If no PRD applies, skip.

### 4. Get the diff against the base branch

Default base branch is `dev` unless the user specified otherwise. No need to verify.

```bash
git log dev..HEAD --oneline
git diff dev...HEAD
```

### 5. Classify each change as public or private

A change is **public** if a caller outside the module/package would notice it:

- **Go**: capitalized identifiers (exported types, funcs, methods, consts, vars)
- **Python**: names not prefixed with `_`, or members of `__all__`
- **TS/JS**: `export`-ed names
- **HTTP/RPC**: routes, request/response shapes, status codes
- **CLI**: flags, subcommands, output format
- **Config**: env vars, settings keys, file formats

Everything else (local helpers, private methods, internal types, tests, refactors that preserve the surface) is private. When in doubt, ask: "would a caller notice this?" If no, it's private.

### 6. Reason about module depth

Before drafting, note for yourself:

- Did this PR **deepen** a module (smaller interface, more internals)?
- Did it **widen** one (more public entry points, more for callers to learn)?
- Did it **carve out** a new module from an existing one?

Mention this in "The Solution" if relevant — it's the highest-signal framing for an architecturally-minded reader.

### 7. Draft the title

Use [Conventional Commits](https://www.conventionalcommits.org/) style: `<type>(<scope>): <subject>`.

- **type**: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`
- **scope**: optional — the module, package, or area (e.g., `nvim`, `auth`, `parser`)
- **subject**: imperative, lowercase, no trailing period, ≤ ~70 chars total

Add `!` after the type/scope for breaking public-interface changes: `feat(parser)!: drop legacy ParseURL signature`.

Pick the type from the dominant change in the diff — if the PR is mostly a fix with incidental refactor, it's `fix`.

### 8. Build "Files changed" anchor links

Each package breakdown gets a comma-separated `<sub>`-wrapped line linking every file in that package to its diff in the PR's Files changed tab.

GitHub's per-file anchor in `/files` is `#diff-<sha256(path)>`. Build each link as `<pr_url>/files#diff-<sha>`:

- Group the changed files (`git diff --name-only dev...HEAD`) by package.
- For each file, compute the anchor: `printf '%s' "<path>" | sha256sum | cut -d' ' -f1`.
- For a brand-new PR (no URL yet), get the URL after `gh pr create` returns, then `gh pr edit` the body in. For an existing PR, use the URL from `gh pr view --json url`.

Render as:

```md
<sub>**Files changed:** [`generator.go`](<pr_url>/files#diff-<sha>), [`filename.go`](<pr_url>/files#diff-<sha>)</sub>
```

Use the file's basename (not the full path) as the link text — the package heading already supplies the directory.

### 9. Draft the body

Use this template exactly:

````md
## 🐛 The Problem

[2-4 concise bullet points. Each bullet ≤ 1 line. The user-facing or developer-facing problem — what was broken, missing, or painful before. Skimmable at a glance.]

* Bullet one
* Bullet two

## 🛠 The Solution

[2-4 concise bullet points. Each bullet ≤ 1 line. The high-level approach. Mention deepening / widening / extraction if it applies. Skimmable at a glance.]

* Bullet one
* Bullet two

## 🏗 Architecture & Public Interface Changes
### 🗺 Interface Movements
| Interface / Symbol | Old Location / Status | New Location / Status | Notes |
| :--- | :--- | :--- | :--- |
| `ExampleFunc` | `oldpackage` | `newpackage` | Extracted for reuse |
| `ConfigStruct` | 🔒 Private | 🌐 Public | Exported for testing |

### 📦 Package Breakdowns
#### 1. `path/to/updated/package`
*Brief explanation of what this package now handles.*

<sub>**Files changed:** [`file_a.go`](<pr_url>/files#diff-<sha>), [`file_b.go`](<pr_url>/files#diff-<sha>)</sub>

<details>
<summary>🔍 View Interface Changes</summary>

```diff
# Highlight key additions (+) or deletions (-) here, or just leave a note.
+ func NewFeature() error
```
</details>

## 🧹 Housekeeping & Secondary Changes
* Renamed `oldVar` to `newVar` in `utils.go` for clarity.
* Fixed typos in comments across the `oversightreport` package.
* Bumped dependency `xyz` to version `1.2.3`.

Closes #<num>
````

Keep "The Problem" and "The Fix" as short, glanceable bullet points. Resist narrating every commit. Omit the `Closes` line if no PRD applies.

### 10. Push and create (or update)

Do not confirm the title or body with the user — just create the PR. Use the draft/ready answer from step 2. The base branch is `dev` unless the user said otherwise.

For a new PR: create it with placeholder anchor URLs (or omit the Files-changed line), capture the returned URL, then `gh pr edit` to inject the real `<pr_url>/files#diff-<sha>` links.

```bash
git push -u origin HEAD                                    # if branch is unpushed
gh pr create --base dev --title "<title>" [--draft] --body "$(cat <<'EOF'
<body>
EOF
)"
```

For an existing PR: `gh pr edit <num> --body "$(cat <<'EOF' ... EOF)"` (draft/ready is already set; don't change it unless asked).

Print the PR URL when done.

## Diff format for interface changes

Use fenced ```diff blocks. Strip implementations — show signatures only.

Separate logical groups (different symbols, removals vs. additions, related families) with blank lines. A wall of contiguous `-`/`+` lines is hard to scan; whitespace gives the eye anchor points.

Good:

````md
```diff
- const PearsuiteAppBaseURL = "https://app.pearsuite.com"

- type OversightReportGenerator struct{ ... }

- func NewOversightReportGenerator(
-   dl datalake.Datalake,
-   goldDatabase string,
-   filename FilenameGenerator,
- ) (*OversightReportGenerator, error)

- const mountainTimezone = "America/Denver"
+ const MountainTimezone = "America/Denver"
```
````

Good:

````md
```diff
- func ParseURL(s string) (*URL, error)
+ func ParseURL(s string, opts ...Option) (*URL, error)

+ type Option func(*parser)
+ func WithStrict() Option
```
````

Bad — bodies included, private helper leaked in:

````md
```diff
- func ParseURL(s string) (*URL, error) {
-   return parse(s, false)
- }
+ func ParseURL(s string, opts ...Option) (*URL, error) {
+   p := &parser{}
+   for _, o := range opts { o(p) }
+   return p.parse(s)
+ }
+ func newParser() *parser { ... }
```
````

For non-code interfaces (HTTP routes, CLI flags, config keys), use a similar before/after diff.

## Notes

- Never add `Co-Authored-By` or "Generated with Claude Code" footers unless asked.
- Always pass `--json` on `gh` subcommands that support it.
- Don't run tests/lint here; that's the author's job before invoking this skill.
