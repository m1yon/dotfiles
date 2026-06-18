# Properties (Frontmatter) Reference

Properties use YAML frontmatter at the start of a note. In Michael's vault, most current notes are plain Markdown, so do not add properties unless the user asks, an existing note already uses them, or a source/template specifically requires them.

```yaml
---
title: My Note Title
date: 2024-01-15
tags:
  - project
  - important
aliases:
  - My Note
  - Alternative Name
cssclasses:
  - custom-class
status: in-progress
rating: 4.5
completed: false
due: 2024-02-01T14:30:00
---
```

## Property Types

| Type | Example |
|------|---------|
| Text | `title: My Title` |
| Number | `rating: 4.5` |
| Checkbox | `completed: true` |
| Date | `date: 2024-01-15` |
| Date & Time | `due: 2024-01-15T14:30:00` |
| List | `tags: [one, two]` or YAML list |
| Links | `related: "[[Other Note]]"` |

## Default Properties

- `tags` - Note tags, searchable and shown in graph view
- `aliases` - Alternative names for the note, used in link suggestions
- `cssclasses` - CSS classes applied to the note in reading/editing view

## Tags

```markdown
#tag
#nested/tag
#tag-with-dashes
#tag_with_underscores
```

Tags can contain letters from any language, numbers when not the first character, underscores `_`, hyphens `-`, and forward slashes `/` for nesting.

In frontmatter:

```yaml
---
tags:
  - tag1
  - nested/tag2
---
```

For this vault's primary categorization, prefer wikilink tag stubs in `3 - Tags/`, such as `[[effect-ts]]`, over native `#tags`.
