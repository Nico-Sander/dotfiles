# Dotfiles

This repo contains the configuration files for my programs used in Linux distrobutions.

## Usage 

- Clone this repo to your local machine
- Intall gnu-stow: `sudo apt install stow` for Debian / Ubuntu
- make the populate script executable: `sudo chmod +x populate.sh`
- run the populate.sh script: `./populate.sh`

This will create symlinks to the configuration files in the correct directories. Usually ~/.config

## File structure example
- Lets say you want to install the tmux configuration folder called tmux/ with the tmux.conf file in it to ~/.config/
- The filestructure in the dotfiles from where you stow needs to follow the wanted target filestructure.
- So .../dotfiles/.config/tmux/ will be symlinked to in ~/.config/tmux/ 

## The populate script
- The script runs the stow command and makes sure the target directory is correcty set to the home folder, in case the dotfiles repo was cloned to another location.
- It also ignores itself, so that there will be no symlink to the populate.sh script in the home folder.
