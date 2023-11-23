# git.fish

Collection of abbreviations and interactive fish-shell integration's I use to make `git` easier!

## Requirements

- [fish ^3.6.0](https://github.com/fish-shell/fish-shell/releases/tag/3.6.0) enhanced the capabilities of `abbr` which this plugin makes use of.
- [git](https://git-scm.com/) I don't hope that comes as a surprise ;-)
- [sqlite3](https://www.sqlite.org/index.html) is used to store visited git directories with the `repos` command.

### Optionals

- [pre-commit](https://pre-commit.com/) ...
- [gitui](https://github.com/extrawurst/gitui)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [tig](https://github.com/jonas/tig)

## Installation

Using [fisher](https://github.com/jorgebucaran/fisher)

```sh
fisher install kpbaks/git.fish
```

## Usage

### Abbreviations

### Commands

#### `gcl`

`gcl` short for `git config --list` lists all git config settings in a colored and formatted table. Without setting any options the users global config will be shown. If you only want the settings for the current git repository you can use `gcl [-l|--local]`

![gcl-output](https://github.com/kpbaks/git.fish/assets/57013304/7d466f54-b6a7-4ddd-9fa1-8d19ed91d1f8)

#### `gi`

`gi` can be used to download common `.gitignore` rules from [gitignore.io](https://www.toptal.com/developers/gitignore/)
See `gi --help` for more information.

## Settings

GIT_FISH_PRE_COMMIT_LIST_HOOKS
GIT_FISH_PRE_COMMIT_ENABLE
GIT_FISH_PRE_COMMIT_AUTO_INSTALL
GIT_FISH_GH_ABBR_ENABLE
GIT_FISH_GIT_ALIAS_REMINDER_ENABLE
GIT_FISH_AUTO_FETCH
GIT_FISH_REMIND_ME_TO_CREATE_REMOTE

# set --query GIT_FISH_GITUI_KEYBIND_ENABLE; or set --universal GIT_FISH_GITUI_KEYBIND_ENABLE 0

# test "$GIT_FISH_GITUI_KEYBIND_ENABLE" = 1; or return

# set --query GIT_FISH_GITUI_KEYBIND; or set --universal GIT_FISH_GITUI_KEYBIND \cg

set --query GIT_FISH_GITUI_KEYBIND_QUIET; or set --universal GIT_FISH_GITUI_KEYBIND_QUIET 0

## Ideas
