# dotfiles

Personal macOS configuration managed with Git and GNU Stow.

## Packages

- `zsh`: `.zshrc` and `.zprofile`
- `starship`: `.config/starship.toml` (Pure preset)
- `wezterm`: `.wezterm.lua`
- `ssh`: `.ssh/config`（只有 Host 规则；私钥和 known_hosts 不入库）
- `bin`: `bin/socks5-proxy`（SSH 的 ProxyCommand，先试本地 SOCKS5，失败自动直连）

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
stow --simulate --verbose --target="$HOME" zsh starship wezterm ssh bin
```

Apply them:

```sh
cd "$HOME/dotfiles"
stow --verbose --target="$HOME" zsh starship wezterm ssh bin
```

Existing target files must be backed up before creating live links.

`ssh` 包会链接成 `~/.ssh/config`，因此 `~/.ssh` 目录必须已存在；私钥、`known_hosts`
和 `config.bak.*` 都不入库。`bin` 包会链接成 `~/bin/socks5-proxy`，脚本本身是
Python 标准库实现，不依赖额外 brew 包。

换一台机器复原的最小步骤：`brew bundle` → `stow zsh starship wezterm ssh bin` →
运行 `scripts/install-zsh-plugins` → 生成 `~/.secrets.zsh`。
