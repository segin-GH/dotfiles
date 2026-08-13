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
  --packages   apt packages (vim, i3, curl, wget, zsh, gh, ...)
  --kitty      install kitty + desktop integration
  --symlink    symlink dotfiles into place
  --zsh        install oh-my-zsh + powerlevel10k
  --pyenv      install pyenv
  --fzf        install fzf
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
        --kitty)     RUN_ALL=0; STEPS+=(kitty) ;;
        --symlink)   RUN_ALL=0; STEPS+=(symlink) ;;
        --zsh)       RUN_ALL=0; STEPS+=(zsh) ;;
        --pyenv)     RUN_ALL=0; STEPS+=(pyenv) ;;
        --fzf)       RUN_ALL=0; STEPS+=(fzf) ;;
        --skip-sudo) SKIP_SUDO=1 ;;
        -h|--help)   usage ;;
        *) err "unknown option: $arg"; usage ;;
    esac
done

[[ $RUN_ALL -eq 1 ]] && STEPS=(packages kitty symlink zsh pyenv fzf)

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
    local pkgs=(vim i3 curl wget zsh lxappearance maim xclip brightnessctl chromium-browser)
    info "Installing system packages: ${pkgs[*]}"
    sudo apt update
    sudo apt install -y "${pkgs[@]}"
    ok "System packages installed"
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

setup_fzf() {
    info "Installing fzf..."
    if [[ ! -d "$HOME/.fzf" ]]; then
        info "Installing fzf from https://github.com/junegunn/fzf"
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    "$HOME/.fzf/install" --all
    ok "fzf installed"
}

main() {
    if [[ $SKIP_SUDO -eq 0 ]] && [[ " ${STEPS[*]} " == *" packages "* ]]; then
        setup_sudo
    fi
    for step in "${STEPS[@]}"; do
        case "$step" in
            packages) install_packages ;;
            kitty)    install_kitty ;;
            symlink)  symlink_dotfiles ;;
            zsh)      setup_zsh ;;
            pyenv)    setup_pyenv ;;
            fzf)      setup_fzf ;;
        esac
    done
    ok "Done"
}

main
