# Using code examples

Render code with [Freeze](https://github.com/charmbracelet/freeze), the `freeze` CLI. Insert the resulting PNG where the code would appear in the card. Use this for code examples, commands, and code answers, whether on the front, back, or in supplemental fields. Keep surrounding prose as text. A technical name mentioned in prose does not need its own image.

## Render and inspect

The examples below were tested locally with Freeze v0.2.2. Check `freeze --help` if the installed version differs. If Freeze is unavailable, report the blocker and keep the code-bearing card pending; follow the repository's declarative package-management rules.

Write the exact code to a temporary file, then render it. A quoted heredoc preserves shell characters in the snippet without expanding them. These commands render the source without executing it.

```bash
anki_code_dir=$(mktemp -d /tmp/anki-freeze.XXXXXX)
cat > "$anki_code_dir/example.py" <<'PY'
def double_even(values):
    return [n * 2 for n in values if n % 2 == 0]

print(double_even([1, 2, 3, 4]))
PY

freeze "$anki_code_dir/example.py" \
  --config base --language python --theme github-dark \
  --font.size 22 \
  --padding 20 --margin 0 --window=false \
  --output "$anki_code_dir/code-example.png"
```

For a short snippet, stdin also works. Reuse the temporary directory above and set the language explicitly.

```bash
freeze --config base --language javascript --theme github-dark \
  --font.size 22 \
  --padding 20 --margin 0 --window=false \
  --output "$anki_code_dir/filter-example.png" <<'JS'
const values = [1, 2, 3, 4];
const evens = values.filter(n => n % 2 === 0);
JS
```

Specify a `.png` output explicitly. `--config base` selects the built-in base configuration; the other flags give syntax highlighting, readable type, and no window controls. Adjust the theme and spacing when the card needs it.

Open the PNG before presenting it. Check exact code, indentation, punctuation, clipping, contrast, and readability at the intended card width. Shorten or reformat long lines in the source while preserving meaning. Preview with an absolute path, for example `![Python code example](/absolute/path/code-example.png)`.

Keep answers out of prompt images, captions, and alt text. Anki cannot apply text cloze syntax to pixels. For a missing part of a snippet, render a prompt version with that part replaced by a visible blank and a complete answer version, or use image occlusion when appropriate. Preview the actual prompt and reveal.

## Preview and approval

A code image is the card's code content. Preview it in the same place as the code within the proposed Front, Back, or supplemental field. Reuse a render across options only when the code is identical. Selection of an option approves its displayed code image and placement along with its text. Existing authorization to add or update a card includes this rendering and upload step; no separate optional-illustration approval is needed. Changed code follows the usual content-review rules. Draft-only requests stop before uploads and note writes.

## Upload and embed

After the card is authorized, call `mcp__anki__store_media_file`. Use a unique filename such as `anki-code-<content-hash>.png` so a revision does not overwrite media used by another card. Pass the absolute PNG path when the MCP server can access it:

```json
{
  "filename": "anki-code-<content-hash>.png",
  "path": "/absolute/path/code-example.png"
}
```

If the server cannot read the local path, pass the actual file bytes as base64 in `data` instead. Supply exactly one of `path`, `data`, or `url`. Use the filename returned by the tool in the note field, never the local path or a data URI:

```html
<div>What does this Python code print?</div>
<img src="anki-code-RETURNED-FILENAME.png" alt="Python code example" style="max-width:100%;height:auto;">
```

Replace the example `src` with the returned filename. Keep the image in the field and position where the code belongs, preserving surrounding text and the recall task. For an existing note, read its complete field and use `mcp__anki__update_note_fields` patch mode to replace the exact code fragment with the image tag. For a new note, include the tag in the corresponding field passed to `mcp__anki__add_note` or `mcp__anki__add_notes`. Upload first; note-field tools reference stored media rather than attaching the file themselves.

Read the note back with `mcp__anki__notes_info` and confirm the filename with `mcp__anki__get_media_files_names`. Check the image's field and position and confirm the note's cards remain in `All`. Retain source or generation provenance separately from the tested answer, following the existing note format.
