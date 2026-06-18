# CLI Usage

Prefer the `obsidian` CLI for normal vault operations when Obsidian is open. It talks to the running Obsidian app and keeps behavior aligned with the active vault.

## Command Rules

- Always target this vault explicitly with `vault="My Vault"` as the first parameter: `obsidian vault="My Vault" search query="effect"`.
- Run `obsidian help` or `obsidian help <command>` when unsure. The local CLI help is the source of truth.
- Parameters use `name=value`; quote values with spaces: `path="6 - Full Notes/Effect.md"`.
- Boolean flags have no value: `silent`, `overwrite`, `open`, `newtab`, `total`, `counts`.
- Use `path=` for exact vault-relative paths and `file=` for wikilink-style note resolution.
- Use `\n` for newlines and `\t` for tabs in multiline CLI content.
- Use `silent` for create commands unless the user wants Obsidian to open the file.

## Filesystem Fallbacks

- Use direct filesystem tools for filename-only inventory, template-file edits, attachment inspection, and precise in-place edits the CLI cannot express safely.
- If Obsidian is closed or the CLI fails because no vault is available, ask the user to open Obsidian when app behavior matters.
- For simple read/write tasks where app behavior does not matter, fall back to direct filesystem tools.
