# Dotfiles Repository

This is a dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a "package" that can be independently stowed. The directory structure within each package mirrors the target location relative to the user's home directory (`$HOME`).

## Usage

All packages stow to the user's home directory by default.

```bash
# Stow a package
stow <package>

# Unstow a package
stow -D <package>

# Restow (unstow then stow) a package
stow -R <package>

# Stow all packages
stow */
```

## Examples

A file at `vim/.vimrc` will be symlinked to `~/.vimrc` when the `vim` package is stowed.

A nested file at `alacritty/.config/alacritty/alacritty.toml` will be symlinked to `~/.config/alacritty/alacritty.toml` when the `alacritty` package is stowed.

## Splitting Packages

When splitting an existing package into multiple packages that share the same target directory:

1. **Unstow the old package first** - Do this BEFORE deleting or modifying the old package directory
2. **Then create the new packages** - Only after unstowing
3. **Delete the old package directory** - Only after unstowing
4. **Stow new packages sequentially**, not all at once

```bash
# Example: splitting hypr into hyprland, hyprlock, hyprpaper
stow -D hypr              # FIRST: unstow old package while it still exists
# Now create new package directories and move files...
rm -rf hypr               # THEN: remove old package
stow hyprland
stow hyprlock
stow hyprpaper
```

**Important:** If you delete the old package before unstowing, `stow -D` will fail and you'll need to manually remove the symlinks from `$HOME`.

Running `stow pkg1 pkg2 pkg3` simultaneously when packages share a directory path can cause stow internal errors.
