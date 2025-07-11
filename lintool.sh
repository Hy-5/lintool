#!/bin/bash
# Simple config installer
# Use with ./lintool.sh to install all configs, or specify -tmux or -nvim etc. to install only specific configs.

set -e

REPO_URL="https://raw.githubusercontent.com/Hy-5/lintool/main"

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

    echo "Installing nvim-lspconfig..."
    sudo apt install -y git
    
    # In case lspconfig already exists, skip git cloning
    if [ ! -d "$HOME/.config/nvim/pack/nvim/start/nvim-lspconfig" ]; then
        git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
    else
        echo "nvim-lspconfig already exists, skipping clone"
    fi


    sudo apt install -y npm
    sudo apt install -y clangd ccls
    sudo npm i -g pyright
    sudo npm install -g neovim
    sudo localectl set-locale LANG=en_US.UTF-8
    set LC_ALL=en_US.UTF-8
    sudo locale-gen "en_US.UTF-8"
    
    # Create config directory
    mkdir -p "$HOME/.config/nvim" "$HOME/.config/nvim/colors"
    
    # Backup existing config
    if [ -f "$HOME/.config/nvim/init.vim" ]; then
        cp "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.backup"
        echo "Backed up existing nvim config"
    fi
    
    # Download and install config
    curl -fsSL "$REPO_URL/nvim/init.vim" -o "$HOME/.config/nvim/init.vim"
    curl -fsSL "$REPO_URL/nvim/colors/molokai.vim" -o "$HOME/.config/nvim/colors/molokai.vim"

    # Auto-install plugins
    echo "Auto PlugInstalling neovim plugins..."
    nvim --headless +PlugInstall +qall
    
    echo "neovim configuration and plugins installed"
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