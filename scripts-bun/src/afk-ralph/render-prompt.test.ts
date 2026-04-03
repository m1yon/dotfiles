import { describe, it, expect } from "bun:test";
import { renderPrompt } from "./render-prompt";

describe("renderPrompt", () => {
  it("replaces a single variable", () => {
    expect(renderPrompt("Hello {{name}}!", { name: "Ralph" })).toBe(
      "Hello Ralph!",
    );
  });

  it("replaces multiple distinct variables", () => {
    expect(
      renderPrompt("{{greeting}}, {{name}}!", {
        greeting: "Hi",
        name: "Ralph",
      }),
    ).toBe("Hi, Ralph!");
  });

  it("replaces repeated occurrences of the same variable", () => {
    expect(renderPrompt("{{x}} and {{x}}", { x: "A" })).toBe("A and A");
  });

  it("replaces missing keys with empty string", () => {
    expect(renderPrompt("a {{missing}} b", {})).toBe("a  b");
  });

  it("leaves non-placeholder braces untouched", () => {
    expect(renderPrompt("{ not a {{var}} }", { var: "X" })).toBe(
      "{ not a X }",
    );
  });

  it("handles empty template", () => {
    expect(renderPrompt("", { a: "1" })).toBe("");
  });

  it("handles template with no placeholders", () => {
    expect(renderPrompt("no vars here", { a: "1" })).toBe("no vars here");
  });

  it("handles empty string values", () => {
    expect(renderPrompt("PRD: {{title}}\n", { title: "" })).toBe("PRD: \n");
  });

  it("handles multiline template", () => {
    const template = `# {{title}}

{{body}}

-- {{author}}`;
    expect(
      renderPrompt(template, {
        title: "Hello",
        body: "Some content",
        author: "Ralph",
      }),
    ).toBe(`# Hello

Some content

-- Ralph`);
  });
});
