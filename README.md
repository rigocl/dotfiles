# Dotfiles

Bare git repo for managing dotfiles.

Reference: https://sameemul-haque.vercel.app/blog/dotfiles

## Initial Setup

```bash
# Create the bare repository
git init --bare $HOME/.dotfiles

# Establish a config alias
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Hide untracked files
config config --local status.showUntrackedFiles no

# Persist the alias (add to .bashrc or fish config)
# For fish, add function to ~/.config/fish/config.fish:
# function config
#     /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
# end
```

## Version Control

```bash
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
```

## Remote Repository

```bash
config remote add origin <remote_repository_url>
config remote -v
config push -u origin master
```

## Branch Management

```bash
config branch
config checkout mocha
config checkout dark
```
