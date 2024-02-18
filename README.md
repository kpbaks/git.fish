# git.fish

Collection of abbreviations and interactive fish-shell integrations I use to make `git` easier!

## Requirements

- [fish ^3.6.0](https://github.com/fish-shell/fish-shell/releases/tag/3.6.0) enhanced the capabilities of `abbr` which this plugin makes use of.
- [git](https://git-scm.com/) I don't hope that comes as a surprise ;-)
- [sqlite3](https://www.sqlite.org/index.html) is used to store visited git directories with the `repos` command.

### Optional Requirements

- [pre-commit](https://pre-commit.com/) ...

## Installation

Using [fisher](https://github.com/jorgebucaran/fisher)

```sh
fisher install kpbaks/git.fish
```

## Usage

### Abbreviations

---

### Commands

#### `gbo`

`gbo` short for "git branch overview" list information about local branches, use `--all` for local and remote, in a pretty-printed table with four columns:
1. `branch`: The current branch is highlighted.
2. `commit`: If the commit is a a conventional-commit then the `type(scope):` part is highlighted.
3. `author`: Each author is assigned a unique color.
4. `committerdate`: Time since most recent commit. A color gradient from red to white is used to indicate how recent the latest commit was.

Here is an example of the output when run against the [helix](https://github.com/helix-editor/helix) repository.

![image](https://github.com/kpbaks/git.fish/assets/57013304/93631887-04ee-42dc-9893-cfb3c6e180d0)




#### `gcl`

`gcl` short for `git config --list` lists all git config settings in a colored and formatted table. Without setting any options the user's global config will be shown. If you only want the settings for the current git repository you can use `gcl [-l|--local]`

![gcl-output](https://github.com/kpbaks/git.fish/assets/57013304/7d466f54-b6a7-4ddd-9fa1-8d19ed91d1f8)

#### `gign`

`gign` can be used to download common `.gitignore` rules from [gitignore.io](https://www.toptal.com/developers/gitignore/)
See `gign --help` for more information.

#### `goverview`

#### `gsl`

<!-- #### `gss` -->

#### `gstatus`

#### `repos`

`repos` is a command to list and search through git repositories you have visited. It uses a `sqlite3` database to store the paths of visited git directories. The database is stored at `git_fish_repos_sqlite3_db` and is automatically updated when you `cd` around in your shell.

##### Usage

```fish
repos init [DIR] # Initialize the database by recursively searching for git repositories in DIR
repos list # List all repositories in the database
repos clear # Clear the database
repos check # Update the database by removing non-existing directories
repos cd # Change directory to a repository using fzf
```
<!-- TODO: insert picture of `repos list` -->

##### Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `git_fish_repos_sqlite3_db` | The path to the sqlite3 database file. | `$`__fish_user_data_dir/git.fish/repos.sqlite3` |
| `git_fish_repos_cd_show_preview` | Use `git_fish_repos_cd_preview_command` to show a preview of the repo in `fzf` | `1` |
| `git_fish_repos_cd_preview_command` | The command to use to show the fzf preview. | `git -c color.status=always -C {} status` |

---

### Reminders


## Settings

GIT_FISH_PRE_COMMIT_LIST_HOOKS
GIT_FISH_PRE_COMMIT_ENABLE
GIT_FISH_PRE_COMMIT_AUTO_INSTALL
GIT_FISH_GH_ABBR_ENABLE
GIT_FISH_GIT_ALIAS_REMINDER_ENABLE
GIT_FISH_AUTO_FETCH
GIT_FISH_REMIND_ME_TO_CREATE_REMOTE

GIT_FISH_REMIND_ME_ABOUT_MY_GIT_ALIASES


## Ideas
