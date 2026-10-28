#!/bin/bash

# Run from your ~/workspace folder or from inside the .files repo

set -euxo pipefail
cleanup() {
    set +euxo pipefail
}
trap cleanup EXIT

SETUP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/setup"

# Handle --force flag: clear all state markers and re-run everything
if [[ "${1:-}" == "--force" ]]; then
    echo "Force mode: clearing all state markers..."
    rm -rf "$SETUP_STATE_DIR"
    shift
fi

is_done() {
    [[ -f "$SETUP_STATE_DIR/$1.done" ]]
}

mark_done() {
    mkdir -p "$SETUP_STATE_DIR"
    touch "$SETUP_STATE_DIR/$1.done"
}

init() {
    mkdir -p ~/install
}

setup_ssh() {
    local email="$1"
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"
    
    if [[ -z "$email" ]]; then
        echo "Usage: setup_github_ssh 'your_email@example.com'"
        return 1
    fi
    
    # Check if keys already exist
    if [[ -f "$key_file" ]] || [[ -f "$ssh_dir/id_rsa" ]]; then
        echo "SSH keys already exist"
        eval "$(ssh-agent -s)" > /dev/null 2>&1
        if [[ -f "$key_file" ]]; then
            ssh-add "$key_file" 2>/dev/null || true
        elif [[ -f "$ssh_dir/id_rsa" ]]; then
            ssh-add "$ssh_dir/id_rsa" 2>/dev/null || true
        fi
        return 0
    fi
    
    # Create .ssh directory
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Generate Ed25519 key
    ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N "" -q
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
    
    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$key_file"
    
    echo "SSH key generated: $key_file"
    echo "Public key:"
    cat "$key_file.pub"
    
    return 0
}

install_debs() {
    if is_done "install_debs"; then
        echo "install_debs: already done, skipping"
        return 0
    fi
    sudo apt update
    sudo apt install -y git tmux vim zsh curl wget
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall || true
    if [[ "$SHELL" != *"zsh"* ]]; then
        sudo chsh -s "$(which zsh)" "$USER"
    fi
    mark_done "install_debs"
}

install_tmux_plugins() {
    if is_done "install_tmux_plugins"; then
        echo "install_tmux_plugins: already done, skipping"
        return 0
    fi
    local plugins_dir="$HOME/.tmux/plugins"
    mkdir -p "$plugins_dir"

    # Install / update tmux-resurrect
    if [[ -d "$plugins_dir/tmux-resurrect" ]]; then
        echo "Updating tmux-resurrect..."
        git -C "$plugins_dir/tmux-resurrect" pull --depth=1 2>/dev/null || true
    else
        echo "Cloning tmux-resurrect..."
        git clone --depth=1 https://github.com/tmux-plugins/tmux-resurrect "$plugins_dir/tmux-resurrect"
    fi

    # Install / update tmux-continuum
    if [[ -d "$plugins_dir/tmux-continuum" ]]; then
        echo "Updating tmux-continuum..."
        git -C "$plugins_dir/tmux-continuum" pull --depth=1 2>/dev/null || true
    else
        echo "Cloning tmux-continuum..."
        git clone --depth=1 https://github.com/tmux-plugins/tmux-continuum "$plugins_dir/tmux-continuum"
    fi
    mark_done "install_tmux_plugins"
}

setup_dotfiles() {
    if is_done "setup_dotfiles"; then
        echo "setup_dotfiles: already done, skipping"
        return 0
    fi
    local url="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dotfiles_dir=""

    # Check if this script itself is located inside the .files repo
    if [[ -f "$script_dir/tmux.conf" && -f "$script_dir/gitconfig" ]]; then
        dotfiles_dir="$script_dir"
        echo "Using dotfiles from $dotfiles_dir..."
        git -C "$dotfiles_dir" pull origin master 2>/dev/null || true
    elif [[ -d ".files" ]]; then
        echo "Dotfiles repo already cloned at .files. Pulling latest master..."
        git -C ".files" pull origin master 2>/dev/null || true
        dotfiles_dir="$(pwd)/.files"
    else
        echo "Cloning dotfiles repo..."
        git clone "$url" .files
        dotfiles_dir="$(pwd)/.files"
    fi

    echo "Copying dotfiles directly (no symlinks)..."
    # Remove any existing files/symlinks to avoid symlink collisions or stale links
    rm -rf ~/.gitconfig ~/.vimrc ~/.tmux.conf ~/.zshrc ~/.p10k.zsh ~/helperbin ~/.config/terminator

    cp "$dotfiles_dir/gitconfig" ~/.gitconfig
    cp "$dotfiles_dir/vimrc" ~/.vimrc
    cp "$dotfiles_dir/tmux.conf" ~/.tmux.conf
    cp "$dotfiles_dir/zshrc" ~/.zshrc

    if [[ -f "$dotfiles_dir/p10k.zsh" ]]; then
        cp "$dotfiles_dir/p10k.zsh" ~/.p10k.zsh
    fi

    if [[ -d "$dotfiles_dir/helperbin" ]]; then
        cp -r "$dotfiles_dir/helperbin" ~/helperbin
    fi

    if [[ -d "$dotfiles_dir/terminator" ]]; then
        mkdir -p ~/.config
        cp -r "$dotfiles_dir/terminator" ~/.config/terminator
    fi

    # Ensure Vim undo and autoload directories exist
    mkdir -p ~/.vim/undo ~/.vim/autoload

    # Install vim plugins defined in ~/.vimrc
    vim +PlugInstall +qall || true

    # Reload tmux config if tmux is running
    tmux source-file ~/.tmux.conf 2>/dev/null || true
    
    echo "Dotfiles setup complete!"
    mark_done "setup_dotfiles"
}

install_ohmyzsh() {
    if is_done "install_ohmyzsh"; then
        echo "install_ohmyzsh: already done, skipping"
        return 0
    fi
    # Check if Oh My Zsh is already installed
    if [ -d ~/.oh-my-zsh ]; then
        echo "Oh My Zsh is already installed at ~/.oh-my-zsh"
        return 0
    fi
    
    # Create the install directory if it doesn't exist
    mkdir -p ~/install
    
    # Download only if the script doesn't already exist
    if [ ! -f ~/install/ohmyzshinstall.sh ]; then
        echo "Downloading Oh My Zsh installer..."
        wget -O ~/install/ohmyzshinstall.sh \
            https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/ohmyzshinstall.sh
    else
        echo "Installer script already exists at ~/install/ohmyzshinstall.sh"
    fi
    
    # Run the installation unattended (prevents starting interactive zsh subshell)
    echo "Running Oh My Zsh installer..."
    RUNZSH=no CHSH=no sh ~/install/ohmyzshinstall.sh --unattended
    
    echo "Oh My Zsh installation complete!"
    mark_done "install_ohmyzsh"
}

install_p10k() {
    if is_done "install_p10k"; then
        echo "install_p10k: already done, skipping"
        return 0
    fi
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        git -C "$p10k_dir" pull --depth=1 2>/dev/null || true
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi
    mark_done "install_p10k"
}

install_zsh_autosuggestions() {
    if is_done "install_zsh_autosuggestions"; then
        echo "install_zsh_autosuggestions: already done, skipping"
        return 0
    fi
    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ -d "$plugin_dir" ]]; then
        git -C "$plugin_dir" pull --depth=1 2>/dev/null || true
    else
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir"
    fi
    mark_done "install_zsh_autosuggestions"
}

init
install_debs
setup_ssh "rupanshu.ganvir@gmail.com"
install_tmux_plugins
install_ohmyzsh
install_p10k
install_zsh_autosuggestions
setup_dotfiles "https://github.com/theQmech/.files"
