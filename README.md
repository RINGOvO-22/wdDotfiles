# dotfiles

Personal macOS configuration managed with Git and GNU Stow.

## Packages

- `zsh`: `.zshrc` and `.zprofile`
- `starship`: `.config/starship.toml` (Pure preset)
- `wezterm`: `.wezterm.lua`

## Dependencies

Install Homebrew dependencies with:

```sh
brew bundle --file="$HOME/dotfiles/Brewfile"
```

Install the pinned Zsh plugins with:

```sh
"$HOME/dotfiles/scripts/install-zsh-plugins"
```

## Stow

Preview links before changing the home directory:

```sh
cd "$HOME/dotfiles"
stow --simulate --verbose --target="$HOME" zsh starship wezterm
```

Existing target files must be backed up before creating live links.
