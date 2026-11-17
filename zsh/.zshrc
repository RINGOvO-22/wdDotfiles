# ============================================================
# .zshrc — macOS optimized
# ============================================================

# --- 本地密钥（不纳管，模板见 dotfiles/secrets.example.zsh）---
if [ -f "$HOME/.secrets.zsh" ]; then
  source "$HOME/.secrets.zsh"
fi

# --- 代理配置（一云梯 / Clash Verge 共用 7890，同一时间只能开一个）---
export no_proxy=localhost,127.*,10.*,172.16.*,172.17.*,172.18.*,172.19.*,172.2*,172.30.*,172.31.*,192.168.*,*.local,*.linker.cc,.linker.cc
export NO_PROXY=$no_proxy

PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
PROXY_NETWORK_SERVICE="${PROXY_NETWORK_SERVICE:-Wi-Fi}"
PROXY_HTTP_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# 方便开关代理
unalias proxy-on proxy-off proxy-status network-check 2>/dev/null

_proxy_endpoint_ready() {
  nc -z -w 2 "$PROXY_HOST" "$PROXY_PORT" >/dev/null 2>&1
}

_proxy_route_ready() {
  curl --proxy "$PROXY_HTTP_URL" -fsS -o /dev/null \
    --connect-timeout 3 --max-time 8 \
    https://www.google.com/generate_204
}

proxy-on() {
  if ! _proxy_endpoint_ready; then
    echo "Proxy not enabled: ${PROXY_HOST}:${PROXY_PORT} is unavailable"
    return 1
  fi

  if ! _proxy_route_ready; then
    echo "Proxy not enabled: ${PROXY_HOST}:${PROXY_PORT} cannot reach the internet"
    return 1
  fi

  export http_proxy="$PROXY_HTTP_URL"
  export https_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$https_proxy"
  export npm_config_proxy="$PROXY_HTTP_URL"
  export npm_config_https_proxy="$PROXY_HTTP_URL"

  networksetup -setwebproxy "$PROXY_NETWORK_SERVICE" "$PROXY_HOST" "$PROXY_PORT"
  networksetup -setsecurewebproxy "$PROXY_NETWORK_SERVICE" "$PROXY_HOST" "$PROXY_PORT"

  git config --global http.proxy "$PROXY_HTTP_URL"
  git config --global https.proxy "$PROXY_HTTP_URL"
  git config --global http.https://git.linker.cc.proxy ""
  git config --global https.https://git.linker.cc.proxy ""
  git config --global http.https://gitlab.linker.cc.proxy ""
  git config --global https.https://gitlab.linker.cc.proxy ""

  echo "Proxy enabled: $http_proxy"
}

proxy-off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY \
    npm_config_proxy npm_config_https_proxy

  networksetup -setwebproxystate "$PROXY_NETWORK_SERVICE" off
  networksetup -setsecurewebproxystate "$PROXY_NETWORK_SERVICE" off
  networksetup -setsocksfirewallproxystate "$PROXY_NETWORK_SERVICE" off

  git config --global --unset-all http.proxy 2>/dev/null || true
  git config --global --unset-all https.proxy 2>/dev/null || true
  git config --global --unset-all core.sshCommand 2>/dev/null || true
  git config --global http.https://git.linker.cc.proxy ""
  git config --global https.https://git.linker.cc.proxy ""
  git config --global http.https://gitlab.linker.cc.proxy ""
  git config --global https.https://gitlab.linker.cc.proxy ""

  echo "Proxy disabled"
}

proxy-status() {
  local terminal_proxy git_http_proxy git_https_proxy git_ssh_command
  terminal_proxy="$(env | grep -Ei '^(http|https|all)_proxy=' | sort)"

  echo "Terminal proxy:"
  if [ -n "$terminal_proxy" ]; then
    echo "$terminal_proxy"
  else
    echo "Disabled"
  fi

  echo $'\nmacOS system proxy:'
  echo "HTTP:"
  networksetup -getwebproxy "$PROXY_NETWORK_SERVICE" | sed -n '1,3p'
  echo "HTTPS:"
  networksetup -getsecurewebproxy "$PROXY_NETWORK_SERVICE" | sed -n '1,3p'
  echo "SOCKS:"
  networksetup -getsocksfirewallproxy "$PROXY_NETWORK_SERVICE" | sed -n '1,3p'

  echo $'\nGit proxy:'
  git_http_proxy="$(git config --global --get http.proxy 2>/dev/null)"
  git_https_proxy="$(git config --global --get https.proxy 2>/dev/null)"
  git_ssh_command="$(git config --global --get core.sshCommand 2>/dev/null)"
  echo "HTTP:  ${git_http_proxy:-Disabled}"
  echo "HTTPS: ${git_https_proxy:-Disabled}"
  echo "SSH(core.sshCommand): ${git_ssh_command:-Disabled}"
  echo "SSH → GitHub: $(ssh -G github.com 2>/dev/null \
    | awk '/^proxycommand/{found=1} END{print found ? "socks5-proxy（失败自动直连）" : "direct"}')"
  echo "git.linker.cc:    Direct"
  echo "gitlab.linker.cc: Direct"

  echo $'\nLocal proxy endpoint:'
  if _proxy_endpoint_ready; then
    echo "Available at ${PROXY_HOST}:${PROXY_PORT}"
    echo "Listening process: $(lsof -nP -iTCP:"$PROXY_PORT" -sTCP:LISTEN 2>/dev/null \
      | awk 'NR>1 {print $1" (pid "$2")"}' | head -n 1)"
  else
    echo "Unavailable at ${PROXY_HOST}:${PROXY_PORT}"
  fi

  echo
  network-check
}

network-check() {
  local host ip active_dns baidu_direct_code google_direct_code proxy_code

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
    echo "OK      Baidu direct (HTTP $baidu_direct_code)"
  else
    echo "FAILED  Baidu direct"
  fi

  if _proxy_endpoint_ready; then
    if proxy_code="$(curl -x "$PROXY_HTTP_URL" -sS -o /dev/null \
      --connect-timeout 3 --max-time 8 -w '%{http_code}' \
      https://www.google.com/generate_204 2>/dev/null)"; then
      if [ "$proxy_code" = "204" ]; then
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
