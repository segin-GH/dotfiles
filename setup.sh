#!/usr/bin/env bash
set -euo pipefail

# dotfiles setup script
# Usage: ./setup.sh [--all|--packages|--kitty|--symlink|--zsh|--pyenv|--fzf]

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

C_INFO=$'\033[1;34m'
C_OK=$'\033[1;32m'
C_WARN=$'\033[1;33m'
C_ERR=$'\033[1;31m'
C_OFF=$'\033[0m'

info() { printf '%s[*]%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_WARN" "$C_OFF" "$*"; }
err()  { printf '%s[x]%s %s\n' "$C_ERR" "$C_OFF" "$*"; }

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --all        run every step (default)
  --packages   apt packages (i3, xorg, vim, curl, wget, zsh, ...)
  --gh         install GitHub CLI (gh) from official repo
  --kitty      install kitty + desktop integration
  --symlink    symlink dotfiles into place
  --zsh        install oh-my-zsh + powerlevel10k
  --pyenv      install pyenv
  --node       install nvm + Node.js 24
  --rust       install rustup + Rust toolchain
  --nvim       install neovim (latest release to /opt)
  --fzf        install fzf
  --fonts      install Maple Mono NF + Font Awesome
  --skip-sudo  skip the sudo password prompt (system steps skipped)
  -h, --help   show this help
EOF
    exit 0
}

STEPS=()
RUN_ALL=1
SKIP_SUDO=0

for arg in "$@"; do
    case "$arg" in
        --all)       RUN_ALL=1 ;;
        --packages)  RUN_ALL=0; STEPS+=(packages) ;;
        --gh)        RUN_ALL=0; STEPS+=(gh) ;;
        --kitty)     RUN_ALL=0; STEPS+=(kitty) ;;
        --symlink)   RUN_ALL=0; STEPS+=(symlink) ;;
        --zsh)       RUN_ALL=0; STEPS+=(zsh) ;;
        --pyenv)     RUN_ALL=0; STEPS+=(pyenv) ;;
        --node)      RUN_ALL=0; STEPS+=(node) ;;
        --rust)      RUN_ALL=0; STEPS+=(rust) ;;
        --nvim)      RUN_ALL=0; STEPS+=(nvim) ;;
        --fzf)       RUN_ALL=0; STEPS+=(fzf) ;;
        --fonts)     RUN_ALL=0; STEPS+=(fonts) ;;
        --skip-sudo) SKIP_SUDO=1 ;;
        -h|--help)   usage ;;
        *) err "unknown option: $arg"; usage ;;
    esac
done

[[ $RUN_ALL -eq 1 ]] && STEPS=(packages gh kitty symlink zsh pyenv node rust nvim fzf fonts)

# Cache sudo credentials once so long apt runs never prompt mid-script.
SUDO_KEEPALIVE_PID=""
setup_sudo() {
    [[ $EUID -eq 0 ]] && return
    if ! sudo -v; then
        err "sudo password required for system package steps"
        exit 1
    fi
    ( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    trap '[[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}

link_file() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "backing up existing $2 -> $2.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
    ok "linked $1 -> $2"
}

install_packages() {
    local pkgs=(xorg i3 vim curl wget zsh lxappearance maim xclip brightnessctl chromium-browser fonts-font-awesome scrot imagemagick ripgrep fd-find lm-sensors htop neofetch)
    info "Installing system packages: ${pkgs[*]}"
    sudo apt update
    sudo apt install -y "${pkgs[@]}"
    sudo sensors-detect --auto
    ok "System packages installed"
}

install_gh() {
    if command -v gh >/dev/null 2>&1; then
        ok "gh already installed: $(gh --version | head -1)"
        return
    fi
    info "Installing GitHub CLI from official repo"
    type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)
    sudo mkdir -p -m 755 /etc/apt/keyrings
    local out
    out=$(mktemp)
    wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    sudo mkdir -p -m 755 /etc/apt/sources.list.d
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    rm -f "$out"
    sudo apt update
    sudo apt install gh -y
    ok "gh installed"
}

install_kitty() {
    if command -v kitty >/dev/null 2>&1; then
        ok "kitty already installed"
        return
    fi
    info "Installing kitty via https://sw.kovidgoyal.net/kitty/installer.sh"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n

    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "$HOME/.local/bin is not on PATH; add it to your shell rc"
    fi
    ok "kitty installed"
}

symlink_dotfiles() {
    info "Symlinking dotfiles..."
    link_file "i3/config"                "$HOME/.config/i3/config"
    link_file "i3/scripts"               "$HOME/.config/i3/scripts"
    link_file "i3status/config"          "$HOME/.config/i3status/config"
    link_file "kitty/kitty.conf"         "$HOME/.config/kitty/kitty.conf"
    link_file "kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
    link_file "nvim"                     "$HOME/.config/nvim"
    link_file "lazygit/config.yml"       "$HOME/.config/lazygit/config.yml"
    link_file ".vimrc"                   "$HOME/.vimrc"
    link_file ".zshrc"                   "$HOME/.zshrc"
    link_file ".tmux.conf"               "$HOME/.tmux.conf"
    link_file ".gitconfig"               "$HOME/.gitconfig"
    ok "Dotfiles symlinked"
}

setup_zsh() {
    info "Setting up oh-my-zsh + powerlevel10k..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing oh-my-zsh"
        RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    local p10k="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$p10k" ]]; then
        info "Installing powerlevel10k theme"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
    fi
    ok "zsh configured"
}

install_nvim() {
    if command -v nvim >/dev/null 2>&1; then
        ok "neovim already installed: $(command -v nvim)"
        return
    fi
    local ver="nvim-linux-x86_64"
    local tarball="/tmp/${ver}.tar.gz"
    info "Downloading latest neovim release"
    curl -fL -o "$tarball" "https://github.com/neovim/neovim/releases/latest/download/${ver}.tar.gz"
    sudo rm -rf "/opt/${ver}"
    sudo tar -C /opt -xzf "$tarball"
    rm -f "$tarball"
    ln -sf "/opt/${ver}/bin/nvim" "$HOME/.local/bin/nvim"
    ok "neovim installed and linked to $HOME/.local/bin/nvim"
}

setup_pyenv() {
    info "Setting up pyenv..."
    if [[ ! -d "$HOME/.pyenv" ]]; then
        info "Installing pyenv via https://pyenv.run"
        curl https://pyenv.run | bash
    fi
    if ! grep -q 'pyenv init' "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" <<'EOF'

# pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOF
    fi
    ok "pyenv configured"
}

setup_node() {
    if [[ -d "$HOME/.nvm" ]]; then
        ok "nvm already installed"
    else
        info "Installing nvm v0.40.6"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
    fi
    if ! command -v nvm >/dev/null 2>&1 && [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        . "$HOME/.nvm/nvm.sh"
    fi
    if command -v nvm >/dev/null 2>&1; then
        info "Installing Node.js 24"
        nvm install 24
        nvm alias default 24
        ok "Node.js installed"
    else
        warn "nvm not available; install nvm manually or restart your shell and re-run this step"
    fi
}

setup_rust() {
    if command -v rustc >/dev/null 2>&1; then
        ok "rust already installed: $(rustc --version)"
        return
    fi
    info "Installing rustup + Rust toolchain"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    if [[ -s "$HOME/.cargo/env" ]]; then
        . "$HOME/.cargo/env"
        ok "rust installed: $(rustc --version)"
    else
        warn "rustup installed but ~/.cargo/env not found"
    fi
}

setup_fzf() {
    info "Installing fzf..."
    if [[ ! -d "$HOME/.fzf" ]]; then
        info "Installing fzf from https://github.com/junegunn/fzf"
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    "$HOME/.fzf/install" --all
    ok "fzf installed"
}

setup_fonts() {
    local fonts_dir="$HOME/.local/share/fonts"
    info "Installing Maple Mono NF + Font Awesome..."
    mkdir -p "$fonts_dir"
    local tmpdir url
    tmpdir="$(mktemp -d)"
    url="https://github.com/subframe7536/Maple-font/releases/download/v7.9/MapleMono-NF.zip"
    curl -fsSL -o "$tmpdir/MapleMono-NF.zip" "$url"
    unzip -o -q "$tmpdir/MapleMono-NF.zip" 'MapleMono-NF-*.ttf' -d "$tmpdir"
    cp "$tmpdir"/MapleMono-NF-*.ttf "$fonts_dir/"
    rm -rf "$tmpdir"
    fc-cache -f "$fonts_dir"
    ok "Maple Mono NF installed"
}

main() {
    if [[ $SKIP_SUDO -eq 0 ]] && [[ " ${STEPS[*]} " == *" packages "* || " ${STEPS[*]} " == *" gh "* || " ${STEPS[*]} " == *" nvim "* ]]; then
        setup_sudo
    fi
    for step in "${STEPS[@]}"; do
        case "$step" in
            packages) install_packages ;;
            gh)       install_gh ;;
            kitty)    install_kitty ;;
            symlink)  symlink_dotfiles ;;
            zsh)      setup_zsh ;;
            pyenv)    setup_pyenv ;;
            node)     setup_node ;;
            rust)     setup_rust ;;
            nvim)     install_nvim ;;
            fzf)      setup_fzf ;;
            fonts)    setup_fonts ;;
        esac
    done
    ok "Done"
}

main
