#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if grep -qi '^ID=arch' /etc/os-release; then
	sudo pacman -Syu --needed \
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
	github-cli \
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

	if ! command -v yay >/dev/null; then
		tmpdir="$(mktemp -d)"
		git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
		(cd "$tmpdir/yay" && makepkg -si)
	fi

	if ! command -v 1password >/dev/null; then
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
		tmpdir="${tmpdir:-$(mktemp -d)}"
		git clone https://aur.archlinux.org/1password.git "$tmpdir/1password"
		(cd "$tmpdir/1password" && makepkg -si)
	fi
fi

# uv is installed from upstream, not tracked in this repo
if ! command -v uv >/dev/null; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Local-only configs: copy each tracked *.example to its real (gitignored)
# name if it doesn't exist yet, then fill in real values by hand.
while IFS= read -r example; do
	target="${example%.example}"
	if [[ ! -e "$target" ]]; then
		cp "$example" "$target"
		chmod 600 "$target"
		echo "created $target from $(basename "$example") — edit it with real values"
	fi
done < <(find "$DOTFILES" -name '*.example' -not -path "$DOTFILES/.git/*")

# Symlink every package into $HOME. --restow prunes stale links on re-runs;
# the */ glob only matches directories, so root files are never stowed.
cd "$DOTFILES"
stow --restow --target="$HOME" */

# systemd user units placed by stow still need enabling once
if command -v systemctl >/dev/null; then
	systemctl --user daemon-reload || true
	systemctl --user enable kanshi.service 2>/dev/null || true
fi
