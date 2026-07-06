#!/bin/bash
# Simple config installer
# Use with ./lintool.sh to install all configs, or specify -tmux or -nvim etc. to install only specific configs.

set -e

REPO_URL="https://raw.githubusercontent.com/Hy-5/lintool/main"

# Flags for selective install
INSTALL_TMUX=false
INSTALL_NVIM=false
INSTALL_ALL=true
# Flags for selective uninstall
DELETE_MODE=false
DELETE_TARGET=""

show_help() {
    cat << "EOF"
Lintool - personal Linux setup script

Install:
  curl -fsSL lin.ismco.me | bash
  curl -fsSL lin.ismco.me | bash -s -- -tmux
  curl -fsSL lin.ismco.me | bash -s -- -nvim

Delete:
  curl -fsSL lin.ismco.me | bash -s -- -del
  curl -fsSL lin.ismco.me | bash -s -- -del nvim
  curl -fsSL lin.ismco.me | bash -s -- -del tmux

Help:
  curl -fsSL lin.ismco.me | bash -s -- -help

No flag installs everything.
Available install flags: -tmux, -nvim
Available delete targets: all, tmux, nvim
EOF
}

# Arguments parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
    -help|--help|-h)
        show_help
        exit 0
        ;;
    -tmux)
        INSTALL_TMUX=true
        INSTALL_ALL=false
        shift
        ;;
    -nvim)
        INSTALL_NVIM=true
        INSTALL_ALL=false
        shift
        ;;
    -del)
        DELETE_MODE=true
        INSTALL_ALL=false

        if [[ -n "$2" && "$2" != -* ]]; then
            DELETE_TARGET="$2"
            shift 2
        else
            DELETE_TARGET="all"
            shift
        fi
        ;;
    *)
        echo "Unknown argument: $1"
        echo "Run with -help for usage."
        exit 1
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
remove_package() {
    if command -v apt &> /dev/null; then
        sudo apt remove -y "$1"
    elif command -v dnf &> /dev/null; then
        sudo dnf remove -y "$1"
    elif command -v yum &> /dev/null; then
        sudo yum remove -y "$1"
    elif command -v pacman &> /dev/null; then
        sudo pacman -Rns --noconfirm "$1"
    else
        echo "Error: Cannot remove $1 - unsupported package manager"
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
delete_tmux() {
    echo "Deleting tmux configuration and package..."

    rm -f "$HOME/.tmux.conf"

    if [ -f "$HOME/.tmux.conf.backup" ]; then
        mv "$HOME/.tmux.conf.backup" "$HOME/.tmux.conf"
        echo "Restored previous .tmux.conf backup"
    fi

    if command -v tmux &> /dev/null; then
        remove_package tmux
    fi

    echo "tmux deleted."
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
        echo "Installing additional Neovim dependencies..."
        sudo apt install fd-find
        sudo apt install fzf
        sudo apt install lua5.1
        sudo apt install tree-sitter-cli
        echo "Additional Neovim dependencies done."
        echo "Installing dev dependencies (build essential)..."
        sudo apt install build-essential
        echo "Dev dependencies installed."
        grep -q 'alias vim="nvim"' ~/.bashrc || echo 'alias vim="nvim"' >> ~/.bashrc
        sleep 2 && source ~/.bashrc
        echo "Done."
    else
        echo "Another instance of Neovim is already installed."
    fi
        mkdir -p "$HOME/.config/nvim/lua/plugins" && curl -fsSL "$REPO_URL/nvim/blink.lua" -o "$HOME/.config/nvim/lua/plugins/blink.lua"
        echo "blink.lua plugin configuration installed."
        mkdir -p "$HOME/.config/nvim/colors" && curl -fsSL "$REPO_URL/nvim/colors/molokai.vim" -o "$HOME/.config/nvim/colors/molokai.vim"
        echo "molokai colorscheme installed."
        mkdir -p "$HOME/.config/nvim/lua/plugins" && curl -fsSL "$REPO_URL/nvim/colorscheme.lua" -o "$HOME/.config/nvim/lua/plugins/colorscheme.lua"
        echo "colorscheme configuration installed. Defaulting to molokai."
}
delete_nvim() {
    echo "Deleting Neovim, LazyVim, and related configuration..."

    # Remove LazyVim / Neovim config
    rm -rf "$HOME/.config/nvim"

    # Remove Neovim installed from GitHub tarball
    sudo rm -f /usr/local/bin/nvim
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo rm -rf /opt/nvim

    # Remove leftover downloaded/build files if present
    rm -rf "$HOME/nvim-linux-x86_64.tar.gz"
    rm -rf "$HOME/luarocks-3.12.2"
    rm -rf "$HOME/luarocks-3.12.2.tar.gz"

    # Remove vim alias added by the script
    sed -i '/alias vim="nvim"/d' "$HOME/.bashrc"

    echo "Neovim deleted except for some dependencies (nodejs and npm)."
}

if [ "$DELETE_MODE" = true ]; then
    case "$DELETE_TARGET" in
        all)
            delete_tmux
            delete_nvim
            ;;
        tmux)
            delete_tmux
            ;;
        nvim|neovim)
            delete_nvim
            ;;
        *)
            echo "Unknown delete target: $DELETE_TARGET"
            echo "Valid targets: all, tmux, nvim"
            exit 1
            ;;
    esac

    echo "Deletion complete!"
    exit 0
fi
# Main installation
if [ "$INSTALL_ALL" = true ]; then
    install_tmux
    install_nvim
else
    [ "$INSTALL_TMUX" = true ] && install_tmux
    [ "$INSTALL_NVIM" = true ] && install_nvim
fi

echo "Installation complete!"