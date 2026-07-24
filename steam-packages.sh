#!/bin/bash

# Run gamescope with Steam if --run flag is passed
if [ "$1" = "--run" ]; then
	exec > /tmp/gamescope.log 2>&1
	set -x

	export PROTON_LOG=1
	export VKD3D_DEBUG=warn
	unset VK_ICD_FILENAMES
	#export VK_INSTANCE_LAYERS=
	#export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
	#export PROTON_ENABLE_NVAPI=1
	#export PROTON_ENABLE_WAYLAND=1
	#export PROTON_ENABLE_HDR=1
	#export ENABLE_HDR_WSI=1
	export PROTON_DISABLE_VR=1
	export PROTON_DISABLE_OPENXR=1
	export VR_DISABLE=1
	export WINEDLLOVERRIDES="wineopenxr=d;openxr_loader=d;openvr_api=d;vrclient=d;vrclient_x64=d"
	export PROTON_USE_SECCOMP=0

	echo "=== gamescope launch $(date) ==="
	env | sort

	exec gamescope --backend drm -w 1920 -h 1080 -r 60 --xwayland-count 2 -e --force-grab-cursor --rt -- steam -gamepadui -steamos3 -steampal -steamdeck
fi

if grep -qi '^ID=arch' /etc/os-release; then
	# Enable multilib repository for 32-bit packages
	sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf

	# Note: nvidia-utils and lib32-nvidia-utils are provided by host via distrobox --nvidia
	# --ignore prevents install, --assume-installed satisfies dependencies
	sudo pacman -Syu --noconfirm \
		--ignore nvidia-utils \
		--ignore lib32-nvidia-utils \
		--ignore egl-wayland \
		--ignore egl-gbm \
		--ignore egl-x11 \
		--assume-installed nvidia-utils \
		--assume-installed lib32-nvidia-utils \
		--assume-installed egl-wayland \
		--assume-installed egl-gbm \
		--assume-installed egl-x11 \
		--assume-installed lib32-vulkan-driver \
		base \
		base-devel \
		git \
		xorg-xwayland \
		steam \
		vulkan-icd-loader \
		lib32-vulkan-icd-loader \
		lib32-mesa \
		lib32-libpulse \
		lib32-alsa-plugins \
		lib32-libxcomposite \
		lib32-libxinerama \
		lib32-fontconfig \
		lib32-libxrender \
		lib32-gnutls \
		lib32-libgpg-error \
		lib32-sqlite \
		lib32-libpng

	# Install yay AUR helper
	rm -rf /tmp/yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm
	cd -

	# Install gamescope and session packages from AUR
	yay -S --noconfirm gamescope-git gamescope-session-git gamescope-session-steam-git

	echo "Steam and gamescope packages installed"
fi
