---
name: linear-issue-context
description: Fetch Linear issue details from the current git branch name. Use when user says "linear context", "issue context", "get issue", or wants to understand the Linear ticket behind the current branch.
---

# Linear Issue Context

Pull Linear issue details into the conversation using the current git branch name.

## Workflow

1. Get the current branch name:
   ```bash
   git branch --show-current
   ```

2. Extract the issue identifier from the branch name. Branch names follow the pattern:
   ```
   <prefix>/<team>-<number>-<slug>
   ```
   Extract `<TEAM>-<number>` (uppercased team prefix). Examples:
   - `feature/mec-546-create-report` -> `MEC-546`
   - `fix/eng-12-broken-login` -> `ENG-12`
   - `mec-100-some-task` -> `MEC-100` (no prefix slash)

3. Call the Linear MCP tool to fetch the issue:
   ```
   mcp__plugin_linear_linear__get_issue(id: "<IDENTIFIER>")
   ```
   Include relations if the user asks for blockers or dependencies:
   ```
   mcp__plugin_linear_linear__get_issue(id: "<IDENTIFIER>", includeRelations: true)
   ```

4. Present a summary:
   - **Title** and **Status**
   - **Description** (full markdown)
   - **Assignee** and **Priority**
   - **Labels** and **Project** (if any)
   - **Sub-issues** or **Relations** (if any)

## Error handling

- If the branch name has no recognizable issue identifier, tell the user and ask them to provide one manually.
- If the Linear API returns no result, suggest the user verify the identifier.
