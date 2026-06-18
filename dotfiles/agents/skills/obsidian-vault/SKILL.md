---
name: obsidian-vault
description: Search, create, manage, and format notes in Michael's Obsidian vault with the obsidian CLI, numbered folders, tag stub notes, templates, wikilinks, embeds, callouts, properties, and Obsidian Flavored Markdown. Use when the user wants to find, create, organize, or edit Obsidian notes, or mentions wikilinks, callouts, frontmatter, tags, embeds, or Obsidian Markdown.
---

# Obsidian Vault

Search, create, manage, and format notes in Michael's Obsidian vault.

## Core Rules

- Vault path: `~/My Vault`; use `/home/michael/My Vault` for absolute filesystem paths.
- Prefer the `obsidian` CLI for normal vault operations when Obsidian is open, and always target `vault="My Vault"` explicitly.
- Use direct filesystem tools for filename inventory, template edits, attachment inspection, and precise in-place edits the CLI cannot express safely.
- Put durable notes in `6 - Full Notes/` by default.
- Put source material in `2 - Source Material/`, with raw meetings in `2 - Source Material/Meetings/`.
- Put tag stub notes in `3 - Tags/` as lowercase kebab-case files.
- Do not create root-level Markdown notes, index notes, YAML frontmatter, native `#tags`, or attachment reorganizations by default.
- Use wikilinks for internal vault links and tag stubs, such as `[[Effect]]` and `[[effect-ts]]`.
- Preserve rough notes and raw source material unless the user asks to clean them up.
- Use actual files in `5 - Templates/` as the source of truth for note templates.

## References

- [CLI usage](references/CLI.md): command syntax, path/file targeting, and fallback behavior.
- [Vault conventions](references/VAULT_CONVENTIONS.md): folder layout, naming, note shape, tags, templates, and avoid list.
- [Workflows](references/WORKFLOWS.md): search, create, update, backlinks, tags, indexes, and promotion workflows.
- [Obsidian Markdown](references/OBSIDIAN_MARKDOWN.md): wikilinks, block IDs, comments, highlights, math, Mermaid, and footnotes.
- [Callouts](references/CALLOUTS.md): callout types, aliases, folding, nesting, and CSS customization.
- [Embeds](references/EMBEDS.md): note, image, PDF, audio, base, list, and search embeds.
- [Properties](references/PROPERTIES.md): YAML property syntax and native Obsidian tags when explicitly requested.

Load the relevant reference before doing detailed vault work instead of relying on memory.
