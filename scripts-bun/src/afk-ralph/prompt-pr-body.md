You are writing a GitHub pull request description. Look at the commits on this branch (compared to {{baseBranch}}) using git log and git diff, then write a concise PR body in markdown.

The PR implements a Linear PRD:
- Identifier: {{prdIdentifier}}
- Title: {{prdTitle}}
- URL: {{prdUrl}}
- Description: {{prdDescription}}

Output ONLY the PR body markdown, nothing else. Focus on module and interface changes, NOT file-by-file diffs. Use this structure:

## Summary
One or two sentences on what this PR delivers end-to-end.

## Interface Changes
For each module or boundary that was added or modified, show a before/after using GitHub markdown diff blocks. Only show the public interface (types, function signatures, route definitions, schema shapes) — not implementation. For new modules, omit the before. Example format:

```diff
- function fetchUser(id: string): Promise<User>
+ function fetchUser(id: string, opts?: FetchOptions): Promise<UserWithRole>
```

Do NOT list individual file paths or line-level implementation changes.

## Key Decisions
Bulleted list of non-obvious implementation decisions (e.g. why a particular boundary was drawn, trade-offs made, patterns chosen).

## Testing
How the changes are verified — which boundaries are tested and how.

---
Linear: {{prdUrl}}
