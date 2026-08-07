# FlashSpace

[FlashSpace](https://github.com/wojciech-kulik/FlashSpace) provides fast,
app-based virtual workspaces on top of one native macOS Space per display.
The Homebrew cask, workspace definitions, app assignments, shortcuts, and
startup are managed declaratively.

## Workspace map

| Workspace | Purpose | Icon | Assigned apps |
| --- | --- | --- | --- |
| 1 | Browser | Globe | Google Chrome (opens on activation) |
| 2 | Codex | Magic wand and stars | Codex (opens on activation) |
| 3 | Terminal | Terminal | Ghostty (opens on activation) |
| 4 | Notes | Note | Obsidian (opens on activation) |
| 5 | Spreadsheets | Table cells | Microsoft Excel |
| 6 | Database | Database cylinder | DataGrip |
| 7 | Email | Envelope | Superhuman |
| 8 | Planning | Checklist | Linear, Todoist |
| 9 | Communication | Conversation bubbles | Teams, Slack, Discord |
| 0 | Calendar | Calendar | Calendar (opens on activation) |

Superwhisper is configured as a floating app, so it remains visible across
workspaces.

The native FlashSpace configuration lives in `dotfiles/flashspace` and is
linked directly into `~/.config/flashspace` with an out-of-store Home Manager
symlink:

- `profiles.json` defines workspaces, shortcuts, app assignments, and apps to
  open when a workspace is activated.
- `settings.json` defines global FlashSpace behavior and focus shortcuts.

After the initial rebuild creates the symlink, configuration edits do not
require another rebuild. Restart FlashSpace to reload them.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Control+1` … `Control+9` | Activate workspace 1 … 9 |
| `Control+0` | Activate the Calendar workspace |
| `Control+Tab` | Activate the most recently used workspace |
| `Control+H/J/K/L` | Focus the app left/down/up/right |
| `Control+Shift+1` … `Control+Shift+9` | Assign the focused app to workspace 1 … 9 |
| `Control+Shift+0` | Assign the focused app to the Calendar workspace |

## One-time setup

1. Rebuild the Darwin configuration.
2. Log out and back in once. Changing “Displays have separate Spaces” requires
   a new login session.
3. Grant FlashSpace **Accessibility** permission when macOS asks.
4. Keep one native macOS Space per display, then use the FlashSpace workspaces.

## If the shortcuts do nothing

- Confirm FlashSpace is enabled under **Accessibility** in **System
  Settings → Privacy & Security**.
- Quit and reopen FlashSpace after changing its Accessibility permission.

FlashSpace assigns entire applications to workspaces. It cannot place
individual windows from the same application in different workspaces.
