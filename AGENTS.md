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
