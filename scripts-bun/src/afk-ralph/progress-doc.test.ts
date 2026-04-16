import { describe, it, expect } from "bun:test";
import {
  filepath,
  buildProgressSection,
  formatEntry,
} from "./progress-doc";

describe("progress-doc filepath", () => {
  const cases: Array<{ name: string; input: string; expected: string }> = [
    {
      name: "simple epic id",
      input: "dotfiles-99s",
      expected: ".afk-ralph/progress-dotfiles-99s.md",
    },
    {
      name: "nested epic id with dot",
      input: "dotfiles-99s.10",
      expected: ".afk-ralph/progress-dotfiles-99s.10.md",
    },
    {
      name: "empty epic id (degenerate but pure)",
      input: "",
      expected: ".afk-ralph/progress-.md",
    },
  ];

  for (const c of cases) {
    it(c.name, () => {
      expect(filepath(c.input)).toBe(c.expected);
    });
  }
});

describe("buildProgressSection", () => {
  it("returns empty string for empty content", () => {
    expect(buildProgressSection("")).toBe("");
  });

  it("returns empty string when no separator is present", () => {
    expect(buildProgressSection("# Just a header\n\nsome intro\n")).toBe("");
  });

  it("returns empty string when only the header and separator exist", () => {
    const content =
      `# Progress — dotfiles-99s: Epic Title\n` +
      `\n` +
      `Running log.\n` +
      `\n` +
      `---\n`;
    expect(buildProgressSection(content)).toBe("");
  });

  it("returns empty string when entries region is whitespace-only", () => {
    const content =
      `# Progress — dotfiles-99s: Epic\n` +
      `\n` +
      `---\n` +
      `\n   \n\n`;
    expect(buildProgressSection(content)).toBe("");
  });

  it("wraps populated entries in a Prior Progress section", () => {
    const content =
      `# Progress — dotfiles-99s: Epic\n` +
      `\n` +
      `Intro text.\n` +
      `\n` +
      `---\n` +
      `\n` +
      `## dotfiles-99s.1: First sub-issue\n` +
      `\n` +
      `_2026-04-16T00:00:00Z · completed_\n` +
      `\n` +
      `Body of the entry.\n`;
    const out = buildProgressSection(content);
    expect(out).toContain("# Prior Progress");
    expect(out).toContain("## dotfiles-99s.1: First sub-issue");
    expect(out).toContain("Body of the entry.");
    expect(out.startsWith("\n# Prior Progress\n\n")).toBe(true);
    expect(out.endsWith("\n")).toBe(true);
  });

  it("preserves multiple entries verbatim", () => {
    const content =
      `# Header\n\n---\n\n` +
      `## a: one\n\n_ts · completed_\n\nbody A\n\n` +
      `## b: two\n\n_ts · blocked_\n\nbody B\n`;
    const out = buildProgressSection(content);
    expect(out).toContain("## a: one");
    expect(out).toContain("## b: two");
    expect(out).toContain("body A");
    expect(out).toContain("body B");
  });
});

describe("formatEntry", () => {
  const issue = { id: "dotfiles-99s.10", title: "Tests: slug + progress-doc" };

  it("emits an H2 heading with id and title", () => {
    const out = formatEntry(issue, "completed", "All done.");
    expect(out.startsWith(`## ${issue.id}: ${issue.title}\n`)).toBe(true);
  });

  it("includes an italic timestamped subhead with the status", () => {
    const out = formatEntry(issue, "completed", "body");
    // Timestamp line: `_<ISO-8601 seconds-precision Z> · <status>_`
    const timestampLine = out.split("\n").find((line) => line.startsWith("_"));
    expect(timestampLine).toBeDefined();
    expect(timestampLine!).toMatch(
      /^_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z · completed_$/,
    );
  });

  it("renders blocked status in the subhead", () => {
    const out = formatEntry(issue, "blocked", "body");
    const timestampLine = out.split("\n").find((line) => line.startsWith("_"));
    expect(timestampLine!).toMatch(/ · blocked_$/);
  });

  it("includes the body verbatim with surrounding whitespace trimmed", () => {
    const out = formatEntry(issue, "completed", "   \n\nBody text.\n\n  ");
    expect(out.endsWith("Body text.")).toBe(true);
  });

  it("separates heading, subhead, and body with blank lines", () => {
    const out = formatEntry(issue, "completed", "body");
    const lines = out.split("\n");
    // Expected shape:
    //   0: ## id: title
    //   1: (blank)
    //   2: _timestamp · status_
    //   3: (blank)
    //   4: body
    expect(lines[0]).toBe(`## ${issue.id}: ${issue.title}`);
    expect(lines[1]).toBe("");
    expect(lines[2]!.startsWith("_")).toBe(true);
    expect(lines[2]!.endsWith("_")).toBe(true);
    expect(lines[3]).toBe("");
    expect(lines[4]).toBe("body");
  });
});
