#! /bin/bash

mkdir -p ~/code
cd $_
git clone git@github.com:lewagon/dotfiles
cd ~/code/dotfiles && zsh install.sh