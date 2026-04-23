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

### 2. Get the diff against the base branch

```bash
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
git log <base>..HEAD --oneline
git diff <base>...HEAD
```

### 3. Classify each change as public or private

A change is **public** if a caller outside the module/package would notice it:

- **Go**: capitalized identifiers (exported types, funcs, methods, consts, vars)
- **Python**: names not prefixed with `_`, or members of `__all__`
- **TS/JS**: `export`-ed names
- **HTTP/RPC**: routes, request/response shapes, status codes
- **CLI**: flags, subcommands, output format
- **Config**: env vars, settings keys, file formats

Everything else (local helpers, private methods, internal types, tests, refactors that preserve the surface) is private. When in doubt, ask: "would a caller notice this?" If no, it's private.

### 4. Reason about module depth

Before drafting, note for yourself:

- Did this PR **deepen** a module (smaller interface, more internals)?
- Did it **widen** one (more public entry points, more for callers to learn)?
- Did it **carve out** a new module from an existing one?

Mention this in "The Fix" if relevant — it's the highest-signal framing for an architecturally-minded reader.

### 5. Draft the title

Use [Conventional Commits](https://www.conventionalcommits.org/) style: `<type>(<scope>): <subject>`.

- **type**: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`
- **scope**: optional — the module, package, or area (e.g., `nvim`, `auth`, `parser`)
- **subject**: imperative, lowercase, no trailing period, ≤ ~70 chars total

Add `!` after the type/scope for breaking public-interface changes: `feat(parser)!: drop legacy ParseURL signature`.

Pick the type from the dominant change in the diff — if the PR is mostly a fix with incidental refactor, it's `fix`.

### 6. Draft the body

Use this template exactly:

```md
## The Problem

[1-3 sentences. The user-facing or developer-facing problem this PR solves. Not what the code does — what was broken, missing, or painful before.]

## The Fix

[1-3 sentences. The high-level approach. Mention deepening / widening / extraction if it applies.]

## Public Interface Changes

[Fenced ```diff blocks. Show signatures only, never bodies. Group by module/package. If nothing public changed, write "None".]

## Other Interface Changes

[Private helpers, refactors, internal restructuring, test changes. Bullet list or short diff blocks. If nothing notable, write "None".]
```

Keep "The Problem" and "The Fix" tight. Resist narrating every commit.

### 7. Show the draft and iterate

Present the rendered title and body. Ask:

- Title accurate?
- Anything in "Other" that belongs in "Public" or vice versa?
- Anything missing?

### 8. Push and create (or update)

Before creating, ask the user: **draft or ready-for-review?**

```bash
git push -u origin HEAD                                    # if branch is unpushed
gh pr create --title "<title>" [--draft] --body "$(cat <<'EOF'
<body>
EOF
)"
```

For an existing PR: `gh pr edit <num> --body "$(cat <<'EOF' ... EOF)"` (draft/ready is already set; don't change it unless asked).

Print the PR URL when done.

## Diff format for interface changes

Use fenced ```diff blocks. Strip implementations — show signatures only.

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
