import { describe, it, expect } from "bun:test";
import { slugifyTitle } from "./slug";

describe("slugifyTitle", () => {
  const cases: Array<{ name: string; input: string; expected: string }> = [
    { name: "empty title", input: "", expected: "" },
    {
      name: "all-punctuation title collapses to empty",
      input: "!!!@@@###",
      expected: "",
    },
    {
      name: "mixed-case title lowercases and hyphenates",
      input: "Fix: ParseError in Foo",
      expected: "fix-parseerror-in-foo",
    },
    {
      name: "emoji and non-ASCII unicode are stripped to hyphens",
      input: "Fix 🐛 on Ænglisc",
      expected: "fix-on-nglisc",
    },
    {
      name: "leading and trailing whitespace are trimmed",
      input: "  hello world  ",
      expected: "hello-world",
    },
    {
      name: "long title is truncated near the 40-char cap with no trailing dash",
      // After slugify: "one-two-three-four-five-six-seven-eight-nine-ten" (48 chars).
      // slice(0, 40) would end with "-eight-" → trailing "-" stripped.
      input: "one two three four five six seven eight nine ten",
      expected: "one-two-three-four-five-six-seven-eight",
    },
  ];

  for (const c of cases) {
    it(c.name, () => {
      expect(slugifyTitle(c.input)).toBe(c.expected);
    });
  }

  it("collapses runs of non-alphanumerics into a single dash", () => {
    expect(slugifyTitle("a    b   c")).toBe("a-b-c");
    expect(slugifyTitle("a---b")).toBe("a-b");
    expect(slugifyTitle("a.,;:b")).toBe("a-b");
  });

  it("never returns a result longer than 40 characters", () => {
    const veryLong = "x".repeat(200) + " " + "y".repeat(200);
    const out = slugifyTitle(veryLong);
    expect(out.length).toBeLessThanOrEqual(40);
  });

  it("never returns a result with leading or trailing dashes", () => {
    const inputs = [
      "",
      "!!!",
      "   spaced   ",
      "-dash-on-both-",
      "one two three four five six seven eight nine ten",
    ];
    for (const input of inputs) {
      const out = slugifyTitle(input);
      expect(out.startsWith("-")).toBe(false);
      expect(out.endsWith("-")).toBe(false);
    }
  });
});
