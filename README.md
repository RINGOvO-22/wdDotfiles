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

The `Brewfile` is maintained by hand: it lists what a fresh machine needs to be
usable, not everything installed on this one. Do not commit `brew bundle dump`
output wholesale.

Install the pinned Zsh plugins with:

```sh
"$HOME/dotfiles/scripts/install-zsh-plugins"
```

## Secrets

Secrets are never tracked. They live in `~/.secrets.zsh` (mode `600`), which
`.zshrc` sources only when it exists:

```sh
cp "$HOME/dotfiles/secrets.example.zsh" "$HOME/.secrets.zsh"
chmod 600 "$HOME/.secrets.zsh"
```

`secrets.example.zsh` is the tracked template; keep it free of real values.

## Stow

Preview links before changing the home directory:

```sh
cd "$HOME/dotfiles"
stow --simulate --verbose --target="$HOME" zsh starship wezterm
```

Existing target files must be backed up before creating live links.
