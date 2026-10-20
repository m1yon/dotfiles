---
name: github-media
description: Upload images and videos to GitHub pull requests, issues, and comments with `gh --attach` so they render inline. Use when a PR or issue needs a screenshot, recording, or before-and-after video, when media in a PR body shows as a link or poster image instead of a player, or when someone suggests committing media to a branch to link it.
---

# GitHub media

`gh` 2.102.0 added `--attach`, which uploads a local image or video as a GitHub attachment (`https://github.com/user-attachments/assets/...`). GitHub renders attachments inline: images as `<img>`, videos as a player. This works in private repositories.

Don't commit media to a branch to link it. A `blob/` or `raw/` link to a file in a private repository renders as a plain link, and the file stays in the repository's history. Use `--attach` instead.

## Commands

These commands accept `--attach`:

| Command | Body flag given | No body flag |
| --- | --- | --- |
| `gh pr create`, `gh issue create` | The attachment is appended, or replaces a matching reference | The attachment is appended |
| `gh pr edit`, `gh issue edit` | The new body replaces the old one | The existing body is kept and the attachment is appended |
| `gh pr comment`, `gh issue comment` | The attachment is appended, or replaces a matching reference | The attachment becomes the comment |

`gh pr review` and `gh release create` don't accept `--attach`. For a review, post the media as a PR comment. For a release, use `gh release upload`.

One command takes up to 50 `--attach` flags. Check that the flag exists with `gh pr edit --help`. Older `gh` versions don't have it.

## Place media in a body

1. Write the body to a file. Wherever a file should appear, reference it by the same path you pass to `--attach`:

   ```markdown
   ## Before and after

   ![Before and after](./before-after.mp4)

   Both captures use synthetic data.
   ```

2. Run the command from the directory those relative paths resolve against:

   ```bash
   gh pr edit 105 -F body.md --attach ./before-after.mp4 --attach './error.png#The login error state'
   ```

   `gh` uploads each file and rewrites the matching reference to the attachment URL. A file the body doesn't reference is appended to the end.

Image alt text comes after `#` in the `--attach` value. Without it, the filename is used. Alt text already written in the body's reference wins. A video has no alt text, so describe it in the text next to it.

If some uploads fail, `gh` still updates the PR or issue with the ones that succeeded, exits non-zero, and prints the URL. Check the body afterward instead of trusting the exit code alone.

## Replace linked media in an existing body

When a body links media that lives in a branch:

1. Save the current body before editing it: `gh pr view <n> --json body -q .body > original.md`.
2. Get each file locally. For a file on a branch, use `git show origin/<branch>:<path> > <file>`, or `gh api -H 'Accept: application/vnd.github.raw' 'repos/<owner>/<repo>/contents/<path>?ref=<branch>' > <file>`.
3. Replace each poster image or link with a `![...](./<file>)` reference. Delete the "Watch the video" links that pointed at the same file.
4. Run `gh pr edit <n> -F new.md --attach ./<file>` from the directory that holds the files.
5. Check the result (next section). Before you delete the branch that held the media, search every PR and issue for links to it. Deleting a branch is destructive, so get the user's approval first.

## Verify

Read the HTML GitHub renders, not the Markdown:

```bash
gh api -H 'Accept: application/vnd.github.html+json' repos/<owner>/<repo>/pulls/<n> -q .body_html | grep -oE '<(video|img)[^>]*>'
```

Each video should appear as a `<video ... controls>` tag, and each image as an `<img>` tag. Use `repos/<owner>/<repo>/issues/<n>` for an issue and `repos/<owner>/<repo>/issues/comments/<id>` for a comment. Confirm the Markdown body no longer links to the old branch.
