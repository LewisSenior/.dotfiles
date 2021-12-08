#!/bin/bash

pushd ~/.dotfiles
for folder in $(ls ./*/ | sed "s/.\///" | sed "s/\/://g")
do
	echo "$folder"
	stow -D $folder
	stow $folder
done
popd
