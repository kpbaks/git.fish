<!-- # `><> 💙 ` -->

# git.fish

Collection of abbreviations and interactive fish-shell integrations I use to make `git` easier!

TODO create toc

## Requirements

- [fish ^3.6.0](https://github.com/fish-shell/fish-shell/releases/tag/3.6.0) enhanced the capabilities of `abbr` which this plugin makes use of.
- [git](https://git-scm.com/) I don't hope that comes as a surprise ;-)
- [sqlite3](https://www.sqlite.org/index.html) is used to store visited git directories with the `repos` command.
- [gum](https://github.com/charmbracelet/gum) is used to provide interactive widgets to some of the commands, like `resolve-conflicts`.

### Optional Requirements

- [pre-commit](https://pre-commit.com/) if installed, then the `pre-commit` reminder will be enabled.

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

![gbo-output](https://github.com/kpbaks/git.fish/assets/57013304/93631887-04ee-42dc-9893-cfb3c6e180d0)

#### `gcl`

`gcl` short for `git config --list` lists all git config settings in a colored and formatted table. Without setting any options the user's global config will be shown. If you only want the settings for the current git repository you can use `gcl [-l|--local]`

![gcl-output](https://github.com/kpbaks/git.fish/assets/57013304/f90f77ef-6366-426d-90de-d354bb1500fa)

#### `gign`

`gign` can be used to download common `.gitignore` rules from [gitignore.io](https://www.toptal.com/developers/gitignore/)
See `gign --help` for more information.

#### `goverview`

TODO

#### `gsl`

TODO

<!-- #### `gss` -->

#### `gstatus`
![gstatus](https://github.com/kpbaks/git.fish/assets/57013304/0b424dae-e2df-4ad2-8f90-f896cd9c7e12)

TODO

#### `repos`

`repos` is a command to list and search through git repositories you have visited. It uses a `sqlite3` database to store the paths of visited git directories. The database is stored at `git_fish_repos_sqlite3_db` and is automatically updated when you `cd` around in your shell.

##### Usage

```fish
repos populate <DIR> # Populate the database by recursively searching for git repositories in DIR
repos list           # List all repositories in the database
repos clear          # Clear the database
repos check          # Update the database by removing non-existing directories
repos cd             # Change directory to a repository using fzf
```
<!-- TODO: insert picture of `repos list` -->

> [!TIP]\
> `repos` is really useful if you create a keybind to quickly `cd` around to your projects
> I like to use <kbd>alt-r</kbd> for this:


<!-- > ```fish -->
<!-- bind \er 'repos cd; commandline --function repaint' -->
<!-- > ``` -->

##### Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `git_fish_repos_sqlite3_db` | The path to the sqlite3 database file. | `$__fish_user_data_dir/git.fish/repos.sqlite3` |
| `git_fish_repos_cd_show_preview` | Use `git_fish_repos_cd_preview_command` to show a preview of the repo in `fzf` | `1` |
| `git_fish_repos_cd_preview_command` | The command to use to show the fzf preview. | `git -c color.status=always -C {} status` |

---

### Reminders

Reminders are actions that are run when you enter a git repository. They are meant to act as helpful reminders to encourage good practices. This feature is probably not everyone's cup of tea, as it can be distracting. Therefore, all reminders are disabled by default. So you have to enable them by setting the corresponding universal variable `git_fish_reminders_<reminder>_enable` to `1`.

#### `pre-commit`

If you have [pre-commit](https://pre-commit.com/) installed then a check will be made to see if the repository has a `.pre-commit-config.yaml` file.

- If it does, then the installed pre-commit hooks will be listed.
- If it does not, then a reminder will be printed to the terminal to encourage you to install - the default pre-commit hooks.

##### Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `git_fish_reminders_pre_commit_enable` | Enable the pre-commit reminder. | `0` |
| `git_fish_reminders_pre_commit_list_hooks` | List the installed pre-commit hooks. | `0` |
| `git_fish_reminders_pre_commit_auto_install_hooks` | Automatically install the default pre-commit hooks. | `0` |

#### `should-i-commit`

Check if there are uncommitted changes in the repository and if there are more than `git_fish_reminders_should_i_commit_threshold` then a reminder will be printed to the terminal.

Example reminder with `set git_fish_reminders_should_i_commit_threshold 50`:

<p align="center">
  <img src="https://github.com/kpbaks/git.fish/assets/57013304/1e5bbc9a-bfd1-4e80-9ca6-0208b88bd596" alt="should-i-commit-output" style="max-width: 100%; height: auto;">
</p>

##### Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `git_fish_reminders_should_i_commit_enable` | Enable the should-i-commit reminder. | `0` |
`git_fish_reminders_should_i_commit_threshold` | The number of uncommitted changes that will trigger the reminder. | `50` |
