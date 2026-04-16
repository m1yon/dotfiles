// Slug helper for turning human-readable titles into git-branch-safe strings.
// Pure string manipulation — no I/O, no side effects. Extracted from
// `index.ts` so it can be imported from tests without triggering the
// orchestrator's top-level `main()` call.

/**
 * Slugify a title for use in a git branch name.
 *
 * Rules: lowercase; any character outside [a-z0-9] becomes `-`; runs of `-`
 * collapsed; leading/trailing `-` trimmed; total length capped near 40 chars.
 */
export function slugifyTitle(title: string): string {
  const lowered = title.toLowerCase();
  // Replace any non-[a-z0-9] with `-`. This covers unicode, emoji, whitespace, punctuation.
  const replaced = lowered.replace(/[^a-z0-9]+/g, "-");
  const collapsed = replaced.replace(/-+/g, "-");
  const trimmed = collapsed.replace(/^-+|-+$/g, "");
  const MAX = 40;
  if (trimmed.length <= MAX) return trimmed;
  // Cap near 40 chars and re-trim trailing `-` so we don't end on a dash.
  return trimmed.slice(0, MAX).replace(/-+$/g, "");
}
