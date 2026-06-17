---
name: obsidian-vault
description: Search, create, and manage notes in Michael's Obsidian vault with the obsidian CLI, numbered folders, tag stub notes, templates, and wikilinks. Use when the user wants to find, create, or organize Obsidian notes.
---

# Obsidian Vault

## Vault Location

`~/My Vault`

Use `/home/michael/My Vault` for tool calls that need an absolute path.

## Obsidian CLI

Prefer the `obsidian` CLI for normal vault operations when Obsidian is open. It talks to the running Obsidian app and keeps behavior aligned with the active vault.

- Always target this vault explicitly with `vault="My Vault"` as the first parameter: `obsidian vault="My Vault" search query="effect"`.
- Run `obsidian help` or `obsidian help <command>` when unsure. The local CLI help is the source of truth.
- Parameters use `name=value`; quote values with spaces: `path="6 - Full Notes/Effect.md"`.
- Boolean flags have no value: `silent`, `overwrite`, `open`, `newtab`, `total`, `counts`.
- Use `path=` for exact vault-relative paths and `file=` for wikilink-style note resolution.
- Use `\n` for newlines and `\t` for tabs in multiline CLI content.
- Use `silent` for create commands unless the user wants Obsidian to open the file.
- Use direct filesystem tools for filename-only inventory, template-file edits, attachment inspection, and precise in-place edits the CLI cannot express safely.
- If Obsidian is closed or the CLI fails because no vault is available, either ask the user to open Obsidian when app behavior matters or fall back to direct filesystem tools for simple read/write tasks.

## Folder Layout

- `1 - Rough Notes/`: scratch notes, inbox items, temporary TODOs, and unfinished work.
- `2 - Source Material/`: notes derived from external material. Subfolders are `Articles/`, `Books/`, `Courses/`, `Docs/`, `Emails/`, `Meetings/`, `Podcasts/`, and `Videos/`.
- `3 - Tags/`: empty tag stub notes named in lowercase kebab case, such as `effect-ts.md`, `pear-suite.md`, and `mental-health.md`.
- `4 - Indexes/`: reserved for explicit index/map notes. It is currently empty, so do not create index notes by default.
- `5 - Templates/`: Obsidian templates. Current templates are `Main Note.md`, `Meeting Note.md`, and `IFS Defender.md`.
- `6 - Full Notes/`: default destination for durable notes. Obsidian is configured to create new files here by default.
- Vault root: legacy loose notes plus images, PDFs, videos, canvases, and other attachments. Avoid adding new markdown notes at the root unless the user asks.

## Naming Conventions

- Durable notes use human-readable filenames, usually title case: `Effect Error Handling Best Practices.md`, `Care Coordination MCO Billing.md`.
- Preserve official casing, code identifiers, acronyms, and punctuation when they are part of the concept: `pyproject.toml.md`, `systemctl.md`, `1099-NEC Form.md`.
- Meeting notes use `YYYY-MM-DD Title.md`, especially under `2 - Source Material/Meetings/`.
- Tag stub notes use lowercase kebab case in `3 - Tags/`: `data-modeling.md`, `getting-things-done.md`.
- Rough notes may be messy. Do not rename, move, or clean them up unless the user asks.

## Note Shape

Most current notes are plain Markdown, not YAML-frontmatter notes. Do not add YAML frontmatter to new notes unless the user asks for it.

Use the actual template files in `5 - Templates/` as the source of truth instead of copying template bodies into these instructions.

- For durable notes, use CLI `template="Main Note"`.
- For meetings, use CLI `template="Meeting Note"`.
- For IFS defender notes, use CLI `template="IFS Defender"`.
- Read template files only when editing the templates themselves or when falling back to direct file creation.
- Fill template variables such as `{{date}}` and `{{time}}` with the current timestamp only when creating files directly.
- If the user wants template changes, edit the template file itself rather than duplicating template text in this skill.
- Tags are wikilinks to tag notes. Use direct links like `[[effect-ts]]`, not hashtag syntax.
- If a tag does not exist, create an empty stub note in `3 - Tags/<tag-name>.md`.
- Keep source URLs and related-note wikilinks under the references section supplied by the template.
- Prefer one durable concept per full note. Source-material notes may be longer and preserve source structure.
- Use `2 - Source Material/Meetings/` for raw meeting notes unless the user specifically wants a polished durable note.
- Add tags to meeting notes only when they are useful; many existing meeting notes have no `Tags:` line.

## Linking

- Use Obsidian wikilinks: `[[Note Title]]`.
- Use aliases when needed: `[[DBT Marts|Marts]]`.
- Use embeds for attachments: `![[CleanShot 2024-09-25 at 10.52.37.png]]`.
- Tags are wikilinks to stub notes in `3 - Tags/`, not `#tag` values.
- Preserve existing links when editing. Some older notes link tags with folder-qualified links like `[[3 - Tags/meca]]`; do not rewrite them unless the user asks.

## Workflows

### Search For Notes

Prefer CLI search for content and Obsidian-aware lookups:

- Search content: `obsidian vault="My Vault" search query="keyword" limit=10`.
- Search with context: `obsidian vault="My Vault" search:context query="keyword" limit=10`.
- Narrow by folder: `obsidian vault="My Vault" search query="keyword" path="6 - Full Notes" limit=10`.
- Read a known note: `obsidian vault="My Vault" read file="Effect"`.
- Read an exact path: `obsidian vault="My Vault" read path="6 - Full Notes/Effect.md"`.
- Use Glob on `/home/michael/My Vault` only for filename-only search or broad filesystem inventory, such as `**/*keyword*.md`, `2 - Source Material/**/*.md`, or `3 - Tags/*.md`.

### Create A Full Note

1. Put the file in `6 - Full Notes/` unless the user requests another location.
2. Create it with the CLI and the template: `obsidian vault="My Vault" create path="6 - Full Notes/Note Title.md" template="Main Note" content="Body text" silent`.
3. Link tags with `[[lower-kebab-tag]]` and create missing tag stubs in `3 - Tags/`.
4. Add related notes and source URLs under `## References`.
5. Keep the note focused on one durable concept.

### Create Source Material

1. Put the file under the appropriate `2 - Source Material/` subfolder.
2. Use the source title or a clear descriptive title for the filename.
3. Create it with the CLI, using `path=` for the exact destination and `template="Main Note"` when the source note should follow the standard note shape.
4. Preserve useful source structure for articles, books, courses, videos, emails, and meetings.

### Create A Meeting Note

1. Put raw meeting notes in `2 - Source Material/Meetings/`.
2. Name the file `YYYY-MM-DD Meeting Title.md`.
3. Create it with the CLI and meeting template: `obsidian vault="My Vault" create path="2 - Source Material/Meetings/YYYY-MM-DD Meeting Title.md" template="Meeting Note" silent`.
4. Do not add a `Tags:` line unless it adds value.

### Update Existing Notes

- Read before changing: `obsidian vault="My Vault" read file="Note Title"`.
- Append simple additions: `obsidian vault="My Vault" append file="Note Title" content="\nNew line"`.
- Append by exact path when names may collide: `obsidian vault="My Vault" append path="6 - Full Notes/Note Title.md" content="\nNew line"`.
- For precise in-place edits, use direct filesystem editing only when append/create is insufficient, and preserve the note's existing structure.

### Find Related Notes

- Prefer backlinks: `obsidian vault="My Vault" backlinks file="Note Title" counts`.
- Use exact paths for tag notes or ambiguous names: `obsidian vault="My Vault" backlinks path="3 - Tags/effect-ts.md" counts`.
- Search for `[[Note Title]]` with `obsidian vault="My Vault" search query="[[Note Title]]"` when you need raw text matches.
- Also search for aliases or likely old names if a note may have been renamed.
- Search tag notes by looking for `[[tag-name]]` across the vault.

### Work With Tags

- List existing tag stub notes from `3 - Tags/*.md` before inventing a new tag. Use Glob for this because the CLI does not provide a generic file listing command.
- Reuse existing tags when possible.
- Create new tag stubs with the CLI: `obsidian vault="My Vault" create path="3 - Tags/new-tag.md" silent`.
- Inspect tag usage with backlinks: `obsidian vault="My Vault" backlinks path="3 - Tags/new-tag.md" counts`.
- Do not use Obsidian hashtag syntax for the note's primary categorization.
- Do not rely on `obsidian tags` for primary organization in this vault because primary categories are wikilink tag stub notes, not `#tags`.

### Work With Indexes

- `4 - Indexes/` exists but is currently empty.
- Do not create index notes as the default organization mechanism.
- If the user asks for an index/map note, create it with the CLI at `path="4 - Indexes/Index Title.md"` and make it a curated list of wikilinks with short context.

### Promote Or Clean Up Notes

- Rough notes in `1 - Rough Notes/` are scratch space. Ask before deleting or heavily rewriting them.
- When turning rough/source material into a durable concept note, use `obsidian read` for the source note, then `obsidian create` or `obsidian append` for a focused note in `6 - Full Notes/`.
- Keep raw source material intact unless the user asks to reorganize or remove it.

## Avoid

- Do not use any legacy Windows-mounted vault path.
- Do not assume the vault is flat.
- Do not create root-level markdown notes by default.
- Do not create index notes by default.
- Do not add YAML frontmatter to new notes by default.
- Do not reorganize attachments or legacy root files unless explicitly requested.
- Do not bypass the `obsidian` CLI for normal note search, read, create, append, backlink, or tag-stub operations when Obsidian is open.
