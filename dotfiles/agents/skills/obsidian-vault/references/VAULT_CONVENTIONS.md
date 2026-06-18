# Vault Conventions

## Location

- Vault path: `~/My Vault`.
- Absolute path for filesystem tools: `/home/michael/My Vault`.
- Do not use any legacy Windows-mounted vault path.

## Folder Layout

- `1 - Rough Notes/`: scratch notes, inbox items, temporary TODOs, and unfinished work.
- `2 - Source Material/`: notes derived from external material. Subfolders are `Articles/`, `Books/`, `Courses/`, `Docs/`, `Emails/`, `Meetings/`, `Podcasts/`, and `Videos/`.
- `3 - Tags/`: empty tag stub notes named in lowercase kebab case, such as `effect-ts.md`, `pear-suite.md`, and `mental-health.md`.
- `4 - Indexes/`: reserved for explicit index/map notes. It is currently empty, so do not create index notes by default.
- `5 - Templates/`: Obsidian templates. Current templates are `Main Note.md`, `Meeting Note.md`, and `IFS Defender.md`.
- `6 - Full Notes/`: default destination for durable notes. Obsidian is configured to create new files here by default.
- Vault root: legacy loose notes plus images, PDFs, videos, canvases, and other attachments. Avoid adding new Markdown notes at the root unless the user asks.

## Naming

- Durable notes use human-readable filenames, usually title case: `Effect Error Handling Best Practices.md`, `Care Coordination MCO Billing.md`.
- Preserve official casing, code identifiers, acronyms, and punctuation when they are part of the concept: `pyproject.toml.md`, `systemctl.md`, `1099-NEC Form.md`.
- Meeting notes use `YYYY-MM-DD Title.md`, especially under `2 - Source Material/Meetings/`.
- Tag stub notes use lowercase kebab case in `3 - Tags/`: `data-modeling.md`, `getting-things-done.md`.
- Rough notes may be messy. Do not rename, move, or clean them up unless the user asks.

## Note Shape

- Most current notes are plain Markdown, not YAML-frontmatter notes. Do not add YAML frontmatter to new notes unless the user asks for it.
- Use actual template files in `5 - Templates/` as the source of truth instead of copying template bodies into instructions.
- For durable notes, use CLI `template="Main Note"`.
- For meetings, use CLI `template="Meeting Note"`.
- For IFS defender notes, use CLI `template="IFS Defender"`.
- Read template files only when editing the templates themselves or when falling back to direct file creation.
- Fill template variables such as `{{date}}` and `{{time}}` with the current timestamp only when creating files directly.
- If the user wants template changes, edit the template file itself rather than duplicating template text in this skill.
- Keep source URLs and related-note wikilinks under the references section supplied by the template.
- Prefer one durable concept per full note.
- Source-material notes may be longer and preserve source structure.
- Use `2 - Source Material/Meetings/` for raw meeting notes unless the user specifically wants a polished durable note.
- Add tags to meeting notes only when they are useful; many existing meeting notes have no `Tags:` line.

## Tags And Links

- Tags are wikilinks to tag notes. Use direct links like `[[effect-ts]]`, not hashtag syntax.
- If a tag does not exist, create an empty stub note in `3 - Tags/<tag-name>.md`.
- Use Obsidian wikilinks for internal notes, such as `[[Note Title]]`.
- Use aliases when needed: `[[DBT Marts|Marts]]`.
- Use embeds for attachments: `![[CleanShot 2024-09-25 at 10.52.37.png]]`.
- Preserve existing links when editing. Some older notes link tags with folder-qualified links like `[[3 - Tags/meca]]`; do not rewrite them unless the user asks.

## Avoid

- Do not assume the vault is flat.
- Do not create root-level Markdown notes by default.
- Do not create index notes by default.
- Do not add YAML frontmatter to new notes by default.
- Do not use native Obsidian `#tags` for primary categorization by default.
- Do not reorganize attachments or legacy root files unless explicitly requested.
- Do not bypass the `obsidian` CLI for normal note search, read, create, append, backlink, or tag-stub operations when Obsidian is open.
