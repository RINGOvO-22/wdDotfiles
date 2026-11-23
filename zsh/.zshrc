# ============================================================
# .zshrc — macOS optimized
# ============================================================

# --- 本地密钥（不纳管，模板见 dotfiles/secrets.example.zsh）---
if [ -f "$HOME/.secrets.zsh" ]; then
  source "$HOME/.secrets.zsh"
fi

# --- 代理配置（不同代理软件若共用端口如 7890，启动时要确保其余软件完全关闭）---
export no_proxy=localhost,127.*,10.*,172.16.*,172.17.*,172.18.*,172.19.*,172.2*,172.30.*,172.31.*,192.168.*,*.local,*.linker.cc,.linker.cc
export NO_PROXY=$no_proxy

PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
PROXY_NETWORK_SERVICE="${PROXY_NETWORK_SERVICE:-Wi-Fi}"
PROXY_HTTP_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# 方便开关代理
unalias proxy-on proxy-off proxy-status 2>/dev/null

_proxy_endpoint_ready() {
  nc -z -w 2 "$PROXY_HOST" "$PROXY_PORT" >/dev/null 2>&1
}

_proxy_route_ready() {
  curl --proxy "$PROXY_HTTP_URL" -fsS -o /dev/null \
    --connect-timeout 3 --max-time 8 \
    https://www.google.com/generate_204
}

_proxy_system_enabled() {
  networksetup -getwebproxy "$PROXY_NETWORK_SERVICE" 2>/dev/null | awk '/^Enabled:/{print $2; exit}'
}

_proxy_env_first() {
  local v
  for v in "$@"; do
    [ -n "${(P)v}" ] && { printf '%s' "$v"; return 0; }
  done
  printf '未设置'
}

_proxy_tun_active() {
  route -n get default 2>/dev/null | awk '/interface:/{print $2}' | grep -q '^utun'
}

# git 代理配置的快照（只管理脚本会改的键）
_PROXY_MANAGED_KEYS=(
  http.proxy https.proxy core.sshCommand
  http.https://git.linker.cc.proxy https.https://git.linker.cc.proxy
  http.https://gitlab.linker.cc.proxy https.https://gitlab.linker.cc.proxy
)

_proxy_state_file() {
  printf '%s/proxy-state.tsv' "${XDG_CACHE_HOME:-$HOME/.cache}"
}

_proxy_state_save() {
  local f key val
  f="$(_proxy_state_file)"
  mkdir -p "${f:h}"
  : > "$f"
  for key in "${_PROXY_MANAGED_KEYS[@]}"; do
    val="$(git config --global --get "$key" 2>/dev/null)"
    if [ -z "$val" ]; then
      printf '%s\t__UNSET__\n' "$key" >> "$f"
    else
      printf '%s\t%s\n' "$key" "$val" >> "$f"
    fi
  done
}

_proxy_state_restore() {
  local f key val
  f="$(_proxy_state_file)"
  [ -f "$f" ] || return 1
  while IFS=$'\t' read -r key val; do
    [ -z "$key" ] && continue
    if [ "$val" = "__UNSET__" ]; then
      git config --global --unset-all "$key" 2>/dev/null || true
    else
      git config --global "$key" "$val"
    fi
  done < "$f"
  rm -f "$f"
  return 0
}

proxy-on() {
  if ! _proxy_endpoint_ready; then
    echo "无法开启：${PROXY_HOST}:${PROXY_PORT} 无人监听 —— 先启动代理软件或核对端口"
    return 1
  fi

  if ! _proxy_route_ready; then
    echo "无法开启：端口在听，但经代理出网失败 —— 换一个节点再试"
    return 1
  fi

  export http_proxy="$PROXY_HTTP_URL"
  export https_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export npm_config_proxy="$PROXY_HTTP_URL"
  export npm_config_https_proxy="$PROXY_HTTP_URL"

  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/ssh-proxy-off"

  if [ "$(_proxy_system_enabled)" != "Yes" ]; then
    echo "提示：系统代理未开启，浏览器等程序不会走代理（请在代理客户端里打开）"
  fi

  [ -f "$(_proxy_state_file)" ] || _proxy_state_save

  git config --global http.proxy "$PROXY_HTTP_URL"
  git config --global https.proxy "$PROXY_HTTP_URL"
  git config --global http.https://git.linker.cc.proxy ""
  git config --global https.https://git.linker.cc.proxy ""
  git config --global http.https://gitlab.linker.cc.proxy ""
  git config --global https.https://gitlab.linker.cc.proxy ""

  echo "Proxy enabled: $http_proxy"
}

proxy-off() {
  local flush_dns="" env_set="" sys_on="" git_set=""

  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
  touch "${XDG_CACHE_HOME:-$HOME/.cache}/ssh-proxy-off"

  [ "$1" = "--flush-dns" ] && flush_dns=1

  [ -n "${http_proxy}${https_proxy}${HTTP_PROXY}${HTTPS_PROXY}${npm_config_proxy}" ] && env_set=1
  [ -n "$(git config --global --get http.proxy 2>/dev/null)$(git config --global --get https.proxy 2>/dev/null)" ] && git_set=1

  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY \
    npm_config_proxy npm_config_https_proxy

  if [ "$(_proxy_system_enabled)" = "Yes" ]; then
    echo "提示：系统代理仍开着（由代理客户端控制，本脚本不会关闭）"
  fi

  local git_restored=""
  _proxy_state_restore && git_restored=1

  local cleared=()
  [ -n "$env_set" ] && cleared+=("环境变量")

  [ -n "$git_restored" ] && [ -n "$git_set" ] && cleared+=("git 代理（已还原）")

  if [ ${#cleared[@]} -eq 0 ]; then
    echo "Proxy disabled（原本就没有开启）"
  else
    echo "Proxy disabled"
    echo "已清理：${(j: / :)cleared}"
  fi

  if [ -n "$flush_dns" ]; then
    sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    echo "DNS 缓存已清"
  fi
}

proxy-status() {
  local terminal_proxy git_http_proxy git_https_proxy ssh_route \
    ssh_proxy_host ssh_proxy_port

  echo "① 内核层 · 端口"
  if _proxy_endpoint_ready; then
    echo "Available at ${PROXY_HOST}:${PROXY_PORT}"
    echo "Listening process: $(lsof -nP -iTCP:"$PROXY_PORT" -sTCP:LISTEN 2>/dev/null \
      | awk 'NR>1 {print $1" (pid "$2")"}' | head -n 1)"
  else
    echo "Unavailable at ${PROXY_HOST}:${PROXY_PORT}"
  fi

  echo $'\n② 系统层 · 系统代理'
  echo "HTTP:  $(networksetup -getwebproxy "$PROXY_NETWORK_SERVICE" 2>/dev/null | awk '/^Enabled:/{print $2; exit}')"
  echo "HTTPS: $(networksetup -getsecurewebproxy "$PROXY_NETWORK_SERVICE" 2>/dev/null | awk '/^Enabled:/{print $2; exit}')"
  echo "SOCKS: $(networksetup -getsocksfirewallproxy "$PROXY_NETWORK_SERVICE" 2>/dev/null | awk '/^Enabled:/{print $2; exit}')"

  echo $'\n③ 程序层 · 终端环境变量（仅当前会话）'
  terminal_proxy="$(env | grep -Ei '_proxy=' | grep -vEi '^no_proxy=' | sort)"
  if [ -n "$terminal_proxy" ]; then
    echo "$terminal_proxy"
  else
    echo "Disabled（未设环境变量；命令行工具默认直连，可显式指定代理）"
  fi

  echo $'\n③ 程序层 · git / ssh（持久配置：~/.gitconfig、~/.ssh/config）'
  git_http_proxy="$(git config --global --get http.proxy 2>/dev/null)"
  git_https_proxy="$(git config --global --get https.proxy 2>/dev/null)"
  echo "HTTP:  ${git_http_proxy:-Disabled}"
  echo "HTTPS: ${git_https_proxy:-Disabled}"
  if [ -f "${XDG_CACHE_HOME:-$HOME/.cache}/ssh-proxy-off" ]; then
    ssh_route="socks5-proxy（proxy-off 状态 → 直连）"
  elif ssh -G github.com 2>/dev/null | grep -qi '^proxycommand'; then
    ssh_proxy_host="${SOCKS5_PROXY%%:*}"
    ssh_proxy_port="${SOCKS5_PROXY##*:}"
    [ -z "$ssh_proxy_host" ] && ssh_proxy_host="127.0.0.1"
    [ -z "$ssh_proxy_port" ] && ssh_proxy_port="7890"
    if nc -z -w 2 "$ssh_proxy_host" "$ssh_proxy_port" >/dev/null 2>&1; then
      ssh_route="socks5-proxy（${ssh_proxy_host}:${ssh_proxy_port} 可用 → 走代理）"
    else
      ssh_route="socks5-proxy（${ssh_proxy_host}:${ssh_proxy_port} 不通 → 直连）"
    fi
  else
    ssh_route="direct（未配置 ProxyCommand）"
  fi
  echo "SSH → GitHub: $ssh_route"

  echo $'\n③ 程序层 · 其它工具（仅会话环境变量）'
  printf 'curl  会话: %s\n' "$(_proxy_env_first http_proxy https_proxy ALL_PROXY)"
  printf 'npm   会话: %s\n' "$(_proxy_env_first npm_config_proxy npm_config_https_proxy)"
  printf 'pip   会话: %s\n' "$(_proxy_env_first http_proxy https_proxy)"
  echo "未检测持久配置（~/.curlrc、~/.npmrc、pip.conf 需自行确认）"

  echo $'\n④ 链路层 · DNS 与连通性'
  _proxy_network_check

  if _proxy_tun_active; then
    if [ "$_PROXY_ROUTE_OK" = "1" ]; then
      echo $'\n结论：TUN 已接管，且节点可达。'
    elif _proxy_endpoint_ready; then
      echo $'\n结论：TUN 已接管，但节点不通 —— 换一个节点。'
      return 1
    else
      echo $'\n结论：TUN 已接管；端口未监听，节点未检测。'
    fi
  elif ! _proxy_endpoint_ready; then
    echo $'\n结论：内核没在跑（'"$PROXY_PORT"' 无人监听）。'
    return 1
  elif [ "$(_proxy_system_enabled)" != "Yes" ]; then
    echo $'\n结论：内核在跑，但系统代理未开 —— 浏览器会直连。'
    return 1
  elif [ "$_PROXY_ROUTE_OK" != "1" ]; then
    echo $'\n结论：系统代理已开，但节点不通 —— 换一个节点。'
    return 1
  else
    echo $'\n结论：四层都通。'
  fi
}

_proxy_network_check() {
  local host ip active_dns baidu_direct_code google_direct_code proxy_code

  _PROXY_ROUTE_OK=0
  _PROXY_DIRECT_OK=0

  echo "Active DNS servers:"
  active_dns="$(scutil --dns 2>/dev/null \
    | awk '/nameserver\[[0-9]+\]/{print $3}' \
    | sort -u)"
  if [ -n "$active_dns" ]; then
    echo "$active_dns"
  else
    echo "No active DNS server reported"
  fi

  echo $'\nDNS resolution:'
  for host in www.baidu.com www.google.com; do
    ip="$(dig +short "$host" 2>/dev/null | head -n 1)"
    if [ -n "$ip" ]; then
      echo "RESOLVED $host -> $ip"
    else
      echo "FAILED $host"
    fi
  done

  echo $'\nWebsite access:'
  if baidu_direct_code="$(curl --noproxy '*' -sS -o /dev/null \
    --connect-timeout 3 --max-time 8 -w '%{http_code}' \
    https://www.baidu.com 2>/dev/null)"; then
    _PROXY_DIRECT_OK=1
    echo "OK      Baidu direct (HTTP $baidu_direct_code)"
  else
    echo "FAILED  Baidu direct"
  fi

  if _proxy_endpoint_ready; then
    if proxy_code="$(curl -x "$PROXY_HTTP_URL" -sS -o /dev/null \
      --connect-timeout 3 --max-time 8 -w '%{http_code}' \
      https://www.google.com/generate_204 2>/dev/null)"; then
      if [ "$proxy_code" = "204" ]; then
        _PROXY_ROUTE_OK=1
        echo "OK      Google through proxy (HTTP 204)"
      else
        echo "REACHED Google through proxy (HTTP $proxy_code)"
      fi
    else
      echo "FAILED  Google through proxy"
    fi
  else
    echo "SKIPPED Google through proxy: local proxy is not running"
  fi

  if google_direct_code="$(curl --noproxy '*' -sS -o /dev/null \
    --connect-timeout 1 --max-time 2 -w '%{http_code}' \
    https://www.google.com/generate_204 2>/dev/null)"; then
    if [ "$google_direct_code" = "204" ]; then
      echo "OK      Google direct (HTTP 204)"
    else
      echo "REACHED Google direct (HTTP $google_direct_code)"
    fi
  else
    echo "FAILED  Google direct"
  fi
}

# --- Starship 提示符 ---
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# --- 补全路径 ---
fpath=(
  "$HOME/.docker/completions"
  "$HOME/.zsh/zsh-completions/src"
  $fpath
)

# --- 启用 Zsh 补全 ---
zstyle ':completion:*' menu select
autoload -Uz compinit && compinit

# --- 历史搜索 ---
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# --- 实用别名 (macOS) ---
alias ls='ls -G'
alias l='ls -lh'
alias ll='ls -lAh'
alias la='ls -A'
alias grep='grep --color=auto'

# --- Git 别名 ---
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'

# --- 临时别名 ---
alias yazi='env -u TERM_PROGRAM -u TERM_PROGRAM_VERSION yazi'

# --- 目录导航 ---
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias h='history'

# --- Colima 环境（Docker Desktop 替代）---
# 开机后跑一次：启动 VM → 确认 docker 可达 → 自愈 DNS → 启用 qemu → 重探 builder → 切 context → 自检
# 背景见 Obsidian: WorkObsidian/docker desktop 切换到 colima.md
colima-up() {
  local platforms i

  if colima status >/dev/null 2>&1; then
    echo "==> colima 已在运行"
  else
    echo "==> 启动 colima ..."
    colima start || return 1
  fi

  # VM 活着不代表宿主机连得上：睡眠/网络切换后 socket 转发会死掉，文件还在但没人监听
  if ! docker info >/dev/null 2>&1; then
    echo "!! docker 连不上（socket 转发可能已失效），重启 colima ..."
    colima restart || return 1
    for i in 1 2 3 4 5; do
      sleep 2
      docker info >/dev/null 2>&1 && break
    done
    if ! docker info >/dev/null 2>&1; then
      echo "!! 重启后仍连不上，手动查："
      echo "   colima status"
      echo "   colima ssh -- systemctl status docker"
      return 1
    fi
    echo "==> docker 已恢复"
  fi

  if colima ssh -- sh -c 'getent hosts docker.io >/dev/null 2>&1' 2>/dev/null; then
    echo "==> VM 内 DNS 正常"
  else
    echo "!! VM 内 DNS 异常，重写 resolv.conf ..."
    colima ssh -- sh -c '
      sudo rm -f /etc/resolv.conf
      printf "nameserver 223.5.5.5\nnameserver 119.29.29.29\noptions timeout:2 attempts:3\n" | sudo tee /etc/resolv.conf >/dev/null
      sudo systemctl restart docker' || return 1
  fi

  if colima ssh -- sh -c 'grep -q "^enabled" /proc/sys/fs/binfmt_misc/qemu-x86_64 2>/dev/null' 2>/dev/null; then
    echo "==> qemu-x86_64 已启用"
  else
    echo "==> 启用 qemu-x86_64 ..."
    colima ssh -- sh -c 'echo 1 | sudo tee /proc/sys/fs/binfmt_misc/qemu-x86_64 >/dev/null' || return 1
  fi

  # builder 在 VM 启动时就完成了平台探测，qemu 后开的话它看不到 amd64，必须重启一次
  platforms="$(docker buildx inspect multiarch 2>/dev/null | grep -i '^Platforms:' || true)"
  if [[ "$platforms" != *linux/amd64* ]]; then
    echo "==> builder 缺 amd64，重启以重新探测 ..."
    if docker restart buildx_buildkit_multiarch0 >/dev/null 2>&1; then
      for i in 1 2 3 4 5; do
        sleep 2
        platforms="$(docker buildx inspect multiarch 2>/dev/null | grep -i '^Platforms:' || true)"
        [[ "$platforms" == *linux/amd64* ]] && break
      done
    else
      echo "!! 找不到 buildx_buildkit_multiarch0，需要新建 builder"
    fi
  fi

  docker context use colima >/dev/null 2>&1
  echo "==> context 已切到 colima"
  echo

  docker info --format '  daemon : {{.ServerVersion}} / {{.OperatingSystem}}'
  docker info --format '  mirrors: {{json .RegistryConfig.Mirrors}}'

  case "$platforms" in
    *linux/amd64*)
      echo "==> buildx : linux/amd64 可用"
      echo "  $platforms" ;;
    *)
      echo "!! buildx : 缺少 linux/amd64，重建 builder："
      echo '  docker buildx rm multiarch && docker buildx create --name multiarch \'
      echo '    --driver docker-container --config ~/.docker/buildkitd.toml --use' ;;
  esac
}

# --- Shell 行为 ---
# 允许交互式命令行使用 # 行尾注释（zsh 默认关闭，bash 默认开启）
setopt INTERACTIVE_COMMENTS

# --- 历史记录 ---
HISTFILE="$HOME/.zsh_history"
SAVEHIST=100000
HISTSIZE=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS

# terminfo 未定义时（TERM=dumb、部分 IDE/ssh 终端）跳过，避免 "cannot bind to an empty key sequence"
if [[ -n "${terminfo[kcuu1]}" ]]; then
  bindkey "${terminfo[kcuu1]}" history-beginning-search-backward-end
fi
if [[ -n "${terminfo[kcud1]}" ]]; then
  bindkey "${terminfo[kcud1]}" history-beginning-search-forward-end
fi

# --- fnm (Node.js 版本管理) ---
FNM_PATH="/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --shell zsh)"
fi

# --- 加载插件 ---
if [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting 应最后加载
if [ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# >>> conda initialize >>>
# !! 本块原由 conda init 生成；conda init 会写回绝对路径，改动后需手动改回 !!
CONDA_HOME="${CONDA_HOME:-$HOME/miniforge3}"
if [ -x "$CONDA_HOME/bin/conda" ]; then
  __conda_setup="$("$CONDA_HOME/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "$CONDA_HOME/etc/profile.d/conda.sh" ]; then
    . "$CONDA_HOME/etc/profile.d/conda.sh"
  else
    export PATH="$CONDA_HOME/bin:$PATH"
  fi
  unset __conda_setup
fi
# <<< conda initialize <<<

# --- Java ---
# 默认 JDK 25；JDK_VERSION 可覆盖，指定版本缺失时回退到系统默认最高版本
JDK_VERSION="${JDK_VERSION:-25}"
if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home -v "$JDK_VERSION" 2>/dev/null ||
                /usr/libexec/java_home 2>/dev/null)"
  if [[ -n "$_java_home" ]]; then
    export JAVA_HOME="$_java_home"
  fi
  unset _java_home
fi

# --- yazi：退出时把当前目录带回 shell ---
# 用 `y` 启动；`q` 退出会 cd 到浏览到的目录，`Q` 退出不跟随
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
