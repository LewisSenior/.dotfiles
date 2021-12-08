#!/bin/bash

pushd ~/.dotfiles
for folder in $(ls ./*/ | sed "s/.\///;s/\/://g")
do
	stow -D $folder 2> /dev/null
	stow $folder
done
popd
