#!/bin/bash

# https://nodejs.org/en/download
# https://wezterm.org/install/linux.html
# https://github.com/ohmybash/oh-my-bash
# https://github.com/junaire/coomer
# https://github.com/ChrisTitusTech/linutil

set -xe

coomerDependencies="build-essential libgl1-mesa-dev libx11-dev libxext-dev libxrandr-dev libglu1-mesa-dev freeglut3-dev"
nvimDependencies="make gcc ripgrep unzip git xclip curl"
utilities="xinput brightnessctl acpi btop network-manager unrar-free ffmpeg vlc"
virt="qemu-system"

# base-level

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
	    "arch")
		    nvimDependencies= gcc make git ripgrep fd tree-sitter-cli unzip neovim
		    sudo pacman -S $nvimDependencies
		    ;;
	    "debian")
		    sudo apt install $coomerDependencies $nvimDependencies $utilities
		    ;;
	    *)
		    ;;
    esac
fi

read -p "qemu-system: " qemu
case "$qemu" in
	"y") sudo apt install qemu-system -y ;;
	"n") echo "==========" ;;
	*) echo "Invalid selection" ;;
esac

cat bash.txt >> ~/.bashrc

# nvim install
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz && rm nvim-linux-x86_64.tar.gz
printf '\nexport PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> ~/.bashrc && source ~/.bashrc

# Fonts
sudo mkdir -p /usr/local/share/fonts/ && sudo mv IosevkaNerdFontMono-Regular.ttf /usr/local/share/fonts/ && sudo fc-cache -fv

# config
git clone https://github.com/rrffrl/nvim.git --depth=1
sudo mv nvim ~/.config
cp -r .vimrc .wezterm.lua sway ~/
mkdir -p ~/Documents/virt && cp vm-options.sh ~/Documents/virt
cp -r awesome ~/.config && sudo chown -R $(whoami) ~/.config/awesome

# magnify
g++ coomer.cpp -lGL -lGLU -lX11 -lXrandr -lXext -o coomer && mv coomer scripts/

# scripts
cp scripts/* /usr/local/bin
