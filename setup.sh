#!/bin/bash

# Run from your ~/workspace folder 

set -euxo pipefail
cleanup() {
    set +euxo pipefail
}
trap cleanup EXIT

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
        [[ -f "$key_file" ]] && ssh-add "$key_file" 2>/dev/null
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
    sudo apt install git
    sudo apt install tmux
    sudo apt install vim
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
    sudo apt install zsh
    sudo apt install curl
    sudo chsh -s $(which zsh) $USER
}

setup_dotfiles() {
    local url="$1"
    if [[ -z "$url" ]]; then
        echo "Usage: setup_dotfiles 'repo_url'"
        return 1
    fi

    if [[ -d ".files" ]]; then
        echo "Dotfiles repo already cloned. Pulling latest master..."
        cd .files || { echo "Failed to enter .files directory"; return 1; }
        git pull origin master || { echo "Failed to pull latest master"; cd ..; return 1; }
        cd .. || return 1
    else
        echo "Cloning dotfiles repo..."
        git clone "$url" .files || { echo "Failed to clone repository"; return 1; }
    fi

    # Copy dotfiles with error handling
    echo "Setting up dotfiles..."
    cp ./.files/gitconfig ~/.gitconfig || { echo "Failed to copy gitconfig"; return 1; }
    cp ./.files/vimrc ~/.vimrc || { echo "Failed to copy vimrc"; return 1; }
    vim +PlugInstall +qall
    cp ./.files/zshrc ~/.zshrc || { echo "Failed to copy zshrc"; return 1; }
    
    echo "Dotfiles setup complete!"
}

install_ohmyzsh() {
    # Check if Oh My Zsh is already installed
    if [ -d ~/.oh-my-zsh ]; then
        echo "Oh My Zsh is already installed at ~/.oh-my-zsh"
        return 0
    fi
    
    # Create the install directory if it doesn't exist
    mkdir -p ~/install || { echo "Failed to create ~/install"; return 1; }
    
    # Download only if the script doesn't already exist
    if [ ! -f ~/install/ohmyzshinstall.sh ]; then
        echo "Downloading Oh My Zsh installer..."
        wget -O ~/install/ohmyzshinstall.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/ohmyzshinstall.sh || { echo "Download failed"; return 1; }
    else
        echo "Installer script already exists at ~/install/ohmyzshinstall.sh"
    fi
    
    # Run the installation
    echo "Running Oh My Zsh installer..."
    sh ~/install/ohmyzshinstall.sh || { echo "Installation failed"; return 1; }
    
    echo "Oh My Zsh installation complete!"
}

init
install_debs
setup_ssh "rupanshu.ganvir@gmail.com"
install_ohmyzsh
setup_dotfiles "https://github.com/theQmech/.files"