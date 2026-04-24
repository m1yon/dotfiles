# Skill Building — Best Practices

Extracted from `dotfiles/agents/skills/write-a-skill/SKILL.md`. Reference for
writing new Claude Code agent skills.

## Directory Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

```md
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See [REFERENCE.md](REFERENCE.md)]
```

## The Description Is Load-Bearing

The `description` frontmatter is **the only thing the agent sees** when deciding
whether to load the skill. It sits in the system prompt alongside every other
installed skill's description; the agent picks based solely on this text.

**Must give the agent two things:**

1. What capability the skill provides.
2. When/why to trigger it — specific keywords, contexts, file types.

**Rules:**

- Max 1024 chars.
- Third person.
- First sentence: what it does.
- Second sentence: `Use when [specific triggers]`.

**Good:**

> Extract text and tables from PDF files, fill forms, merge documents. Use when
> working with PDF files or when user mentions PDFs, forms, or document
> extraction.

**Bad:**

> Helps with documents.

The bad version is indistinguishable from every other document-adjacent skill.

## When to Add Scripts

Bundle utility scripts when:

- The operation is deterministic (validation, formatting).
- The same code would otherwise be regenerated repeatedly.
- Errors need explicit handling.

Scripts save tokens and improve reliability over LLM-generated code.

## When to Split Files

Progressive disclosure — move content out of SKILL.md when:

- SKILL.md exceeds 100 lines.
- Content has distinct domains (e.g. finance vs. sales schemas).
- Advanced features are rarely needed.

Keep references **one level deep** — SKILL.md links to REFERENCE.md, not to a
chain of files.

## Review Checklist

- [ ] Description includes triggers (`Use when...`).
- [ ] SKILL.md under 100 lines.
- [ ] No time-sensitive info.
- [ ] Consistent terminology throughout.
- [ ] Concrete examples included.
- [ ] References one level deep.
