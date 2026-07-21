# Native macOS Spaces

macOS Spaces provide the workspace layer. Native Control-number shortcuts
switch directly to each desktop. Hammerspoon adds matching window-movement
shortcuts without running a tiling window manager.

Hammerspoon's keyboard event tap re-emits ordinary Control-number input as
native macOS shortcuts and intercepts Control-Shift-number for window movement.
For movement, it holds a one-pixel title-bar drag while invoking the
corresponding native Mission Control shortcut. This works around
[Hammerspoon issue #3698](https://github.com/Hammerspoon/hammerspoon/issues/3698),
where `hs.spaces.moveWindowToSpace` returns success without moving the window on
Sequoia and Tahoe.

## Space map

| Space | Purpose | Assigned apps |
| --- | --- | --- |
| 1–5 | General and development | — |
| 6 | Database | DataGrip |
| 7 | Email | Superhuman |
| 8 | Planning | Linear, Todoist |
| 9 | Communication | Teams, Slack, Discord |
| 10 | Music | Spotify |

Space ordering is fixed by `system.defaults.dock.mru-spaces = false`.
Activating an app follows it to its assigned Space via the declarative
`workspaces-auto-swoosh` Dock preference.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Control+1` … `Control+9` | Switch to Space 1 … 9 |
| `Control+0` | Switch to Space 10 |
| `Control+Tab` | Switch to the previously active Space |
| `Control+Shift+B` | Open a new Chrome window in the current Space |
| `Control+Shift+T` | Open a new window in the existing Ghostty instance |
| `Control+H/J/K/L` | Focus the window left/down/up/right in the current Space |
| `Control+Shift+1` … `Control+Shift+9` | Move the focused window to Space 1 … 9 and follow it |
| `Control+Shift+0` | Move the focused window to Space 10 and follow it |

## One-time setup

1. Rebuild the Darwin configuration.
2. Grant Hammerspoon **Accessibility** permission when macOS asks.
3. Open Mission Control and create 10 native desktop Spaces.
4. Keep them in the order shown above.
5. Rebuild again. Home Manager will resolve the machine-local Space UUIDs and
   bind the apps declared in `dotfiles/spaces/apps.json`.
6. Log out and back in once so the configured startup apps launch into their
   assigned Spaces.

## If the shortcuts do nothing

- Confirm Hammerspoon is enabled under **Accessibility** in **System
  Settings → Privacy & Security**.
- Confirm all 10 desktop Spaces exist in Mission Control. Switching to a Space
  that does not exist shows a Hammerspoon alert.
- Open **Hammerspoon → Console** to see any `native-spaces` error.
- Quit and reopen Hammerspoon after changing its Accessibility permission.
