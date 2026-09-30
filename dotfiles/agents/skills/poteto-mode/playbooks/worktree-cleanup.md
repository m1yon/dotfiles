### Worktree and simulator cleanup

Audit disk use and worktrees before removing anything. Follow the Codex runtime for chat scope, managed worktrees, and destructive operations.

1. Record `df -h /`. Run the installed `scripts/worktree-audit.sh` against the confirmed repository. It classifies Git worktrees by size, merge state, edits, and PR state. Its optional `PSTACK_TRANSCRIPTS_DIR` accepts only a verified export directory scoped to this project. Without it, chat usage remains unknown.
2. Inspect `list_threads`, `list_artifacts`, and `list_agents` when available to determine which chats and workers still use each candidate. A clean or merged worktree can still be active. An audit bucket is advice, not permission.
3. Preserve uncommitted changes, untracked files, and needed ignored artifacts. Show any uncertain loss for a user decision. Use `archive_worktree` for Codex-managed worktrees after inspecting its restrictions; it preserves a recoverable snapshot. For an ordinary worktree, use `git worktree remove` on the confirmed path only after verifying the allowed removal. Avoid a force removal as the default.
4. For explicitly requested simulator cleanup, list devices and runtimes first and remove only the confirmed stale set. Inspect application caches through documented paths and the user's scope. Do not assume editor database or cache layouts from another product.
5. Re-list worktrees and record `df -h /`. Report reclaimed space, removed or archived paths, and what was kept with the reason.
