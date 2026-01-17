#!/bin/bash
if grep -qi '^ID=arch' /etc/os-release; then
	sudo pacman -Syu \
	base \
	base-devel \
	alacritty \
	autoconf \
	automake \
	bitwarden \
	ffmpeg \
	firefox \
	fzf \
	git \
	go \
	kanshi \
	man-pages \
  neovim \
  nvidia-utils \
  openssh \
  pavucontrol \
  playerctl \
  rsync \
  seatd \
  starship \
  stow \
  sway \
  tmux \
  tree \
  ttf-hack-nerd \
  waybar \
  wget \
  wlroots0.19 \
  wofi \
  xorg-setxkbmap \
  xorg-xauth \
  xorg-xprop \
  xorg-xwayland \
  zsh
	git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
	git clone https://aur.archlinux.org/1password.git
	cd 1password
	makepkg -si
echo "now then"
fi



pushd ~/.dotfiles
for folder in $(ls ./*/ | sed "s/.\///;s/\/://g")
do
	stow -D $folder 2> /dev/null
	stow $folder
done
popd
