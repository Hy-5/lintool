#!/bin/bash
# Simple config installer
# Use with ./lintool.sh to install all configs, or specify -tmux or -nvim etc. to install only specific configs.

set -e

REPO_URL="https://raw.githubusercontent.com/Hy-5/lintool/main"
#https://raw.githubusercontent.com/Hy-5/lintool/main/lintool.sh

# Flags for selective install
INSTALL_TMUX=false
INSTALL_NVIM=false
INSTALL_ALL=true

# Arguments parsing
for arg in "$@"; do
    case $arg in
        -tmux)
            INSTALL_TMUX=true
            INSTALL_ALL=false
            ;;
        -nvim)
            INSTALL_NVIM=true
            INSTALL_ALL=false
            ;;
    esac
done

# Distro specific package install (more maybe...)
install_package() {
    if command -v apt &> /dev/null; then
        sudo apt update -qq && sudo apt install -y "$1"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$1"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "$1"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm "$1"
    else
        echo "Error: Cannot install $1 - unsupported package manager"
        exit 1
    fi
}

# Tmux config details
install_tmux() {
    echo "Installing tmux..."
    
    # Install tmux if not present
    if ! command -v tmux &> /dev/null; then
        install_package tmux
    fi
    
    # Backup existing config
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup"
        echo "Backed up existing .tmux.conf"
    fi
    
    # Download and install config
    curl -fsSL "$REPO_URL/tmux/tmux.conf" -o "$HOME/.tmux.conf"
    echo "tmux configuration installed"
}

# Neovim config details
install_nvim() {
    echo "Installing neovim..."
    
    # Install neovim if not present
    if ! command -v nvim &> /dev/null; then
        install_package neovim
    fi
    
    # Create config directory
    mkdir -p "$HOME/.config/nvim" "$HOME/.config/nvim/autoload" "$HOME/.config/nvim/colors"
    
    # Backup existing config
    if [ -f "$HOME/.config/nvim/init.vim" ]; then
        cp "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.backup"
        echo "Backed up existing nvim config"
    fi
    
    # Download and install config
    curl -fsSL "$REPO_URL/nvim/init.vim" -o "$HOME/.config/nvim/init.vim"
    curl -fsSL "$REPO_URL/nvim/autoload/plug.vim" -o "$HOME/.config/nvim/autoload/plug.vim"
    curl -fsSL "$REPO_URL/nvim/colors/molokai.vim" -o "$HOME/.config/nvim/colors/molokai.vim"
    echo "neovim configuration installed"
}

# Main installation
if [ "$INSTALL_ALL" = true ]; then
    install_tmux
    install_nvim
else
    [ "$INSTALL_TMUX" = true ] && install_tmux
    [ "$INSTALL_NVIM" = true ] && install_nvim
fi

echo "Installation complete!"