#!/bin/bash

pushd ~/.dotfiles
for folder in $(ls ./*/ | sed "s/.\///;s/\/://g")
do
	stow -D $folder
	stow $folder
done
popd
