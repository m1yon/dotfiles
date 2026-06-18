# Workflows

## Search For Notes

Prefer CLI search for content and Obsidian-aware lookups:

- Search content: `obsidian vault="My Vault" search query="keyword" limit=10`.
- Search with context: `obsidian vault="My Vault" search:context query="keyword" limit=10`.
- Narrow by folder: `obsidian vault="My Vault" search query="keyword" path="6 - Full Notes" limit=10`.
- Read a known note: `obsidian vault="My Vault" read file="Effect"`.
- Read an exact path: `obsidian vault="My Vault" read path="6 - Full Notes/Effect.md"`.
- Use Glob on `/home/michael/My Vault` only for filename-only search or broad filesystem inventory, such as `**/*keyword*.md`, `2 - Source Material/**/*.md`, or `3 - Tags/*.md`.

## Create A Full Note

1. Put the file in `6 - Full Notes/` unless the user requests another location.
2. Create it with the CLI and the template: `obsidian vault="My Vault" create path="6 - Full Notes/Note Title.md" template="Main Note" content="Body text" silent`.
3. Link tags with `[[lower-kebab-tag]]` and create missing tag stubs in `3 - Tags/`.
4. Add related notes and source URLs under `## References`.
5. Keep the note focused on one durable concept.

## Create Source Material

1. Put the file under the appropriate `2 - Source Material/` subfolder.
2. Use the source title or a clear descriptive title for the filename.
3. Create it with the CLI, using `path=` for the exact destination and `template="Main Note"` when the source note should follow the standard note shape.
4. Preserve useful source structure for articles, books, courses, videos, emails, and meetings.

## Create A Meeting Note

1. Put raw meeting notes in `2 - Source Material/Meetings/`.
2. Name the file `YYYY-MM-DD Meeting Title.md`.
3. Create it with the CLI and meeting template: `obsidian vault="My Vault" create path="2 - Source Material/Meetings/YYYY-MM-DD Meeting Title.md" template="Meeting Note" silent`.
4. Do not add a `Tags:` line unless it adds value.

## Update Existing Notes

- Read before changing: `obsidian vault="My Vault" read file="Note Title"`.
- Append simple additions: `obsidian vault="My Vault" append file="Note Title" content="\nNew line"`.
- Append by exact path when names may collide: `obsidian vault="My Vault" append path="6 - Full Notes/Note Title.md" content="\nNew line"`.
- For precise in-place edits, use direct filesystem editing only when append/create is insufficient, and preserve the note's existing structure.

## Find Related Notes

- Prefer backlinks: `obsidian vault="My Vault" backlinks file="Note Title" counts`.
- Use exact paths for tag notes or ambiguous names: `obsidian vault="My Vault" backlinks path="3 - Tags/effect-ts.md" counts`.
- Search for `[[Note Title]]` with `obsidian vault="My Vault" search query="[[Note Title]]"` when you need raw text matches.
- Also search for aliases or likely old names if a note may have been renamed.
- Search tag notes by looking for `[[tag-name]]` across the vault.

## Work With Tags

- List existing tag stub notes from `3 - Tags/*.md` before inventing a new tag. Use Glob for this because the CLI does not provide a generic file listing command.
- Reuse existing tags when possible.
- Create new tag stubs with the CLI: `obsidian vault="My Vault" create path="3 - Tags/new-tag.md" silent`.
- Inspect tag usage with backlinks: `obsidian vault="My Vault" backlinks path="3 - Tags/new-tag.md" counts`.
- Do not use Obsidian hashtag syntax for the note's primary categorization.
- Do not rely on `obsidian tags` for primary organization in this vault because primary categories are wikilink tag stub notes, not `#tags`.

## Work With Indexes

- `4 - Indexes/` exists but is currently empty.
- Do not create index notes as the default organization mechanism.
- If the user asks for an index/map note, create it with the CLI at `path="4 - Indexes/Index Title.md"` and make it a curated list of wikilinks with short context.

## Promote Or Clean Up Notes

- Rough notes in `1 - Rough Notes/` are scratch space. Ask before deleting or heavily rewriting them.
- When turning rough/source material into a durable concept note, use `obsidian read` for the source note, then `obsidian create` or `obsidian append` for a focused note in `6 - Full Notes/`.
- Keep raw source material intact unless the user asks to reorganize or remove it.
