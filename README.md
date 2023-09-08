# git.fish

Collection of abbreviations and interactive fish-shell integrations I use to make `git` easier!

## Requirements

- [fish ^3.6.0](https://github.com/fish-shell/fish-shell/releases/tag/3.6.0) enhanced the capabilities of `abbr` which this plugin makes use of.
- [git](https://git-scm.com/) I don't hope that comes as a suprise ;-)
- [sqlite3](https://www.sqlite.org/index.html) is used to store visited git directories with the `repos` command.

### Optionals

- [pre-commit](https://pre-commit.com/) ...

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

**TODO** add an image of the output

## Settings

GIT_FISH_PRE_COMMIT_LIST_HOOKS

## Ideas
