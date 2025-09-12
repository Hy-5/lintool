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
    
    # Install neovim from github repo if not present
    if ! command -v nvim &> /dev/null; then
        echo "Installing dependencies..."
        sudo apt install -y wget git make lua5.4 liblua5.4-dev unzip ripgrep npm nodejs
        echo "Installing luarocks..."
        wget https://luarocks.org/releases/luarocks-3.12.2.tar.gz
        tar zxpf luarocks-3.12.2.tar.gz
        cd luarocks-3.12.2
        ./configure && make && sudo make install
        sudo luarocks install luasocket
        cd ..
        rm -rf luarocks-3.12.2.tar.gz

        if [[ -d "$HOME/.npm-global" ]]; then
            npm install --global @ast-grep/cli
        else
            sudo npm install --global @ast-grep/cli
        fi


        echo "Installing latest Neovim version..."
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        echo "Adding nvim to PATH..."
        sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
        rm -rf nvim-linux-x86_64.tar.gz
        echo "Setting up LazyVim..."
        git clone https://github.com/LazyVim/starter ~/.config/nvim
        rm -rf ~/.config/nvim/.git
        rm -rf luarocks-3.12.2/
        grep -q 'alias vim="nvim"' ~/.bashrc || echo 'alias vim="nvim"' >> ~/.bashrc && source ~/.bashrc
        echo "Done."
    else
        echo "Another instance of Neovim is already installed."
    fi

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