#!/bin/bash
distrobox create --image archlinux:latest -n desktop --init --additional-packages "systemd" --additional-flags "--userns=keep-id --group-add keep-groups"
