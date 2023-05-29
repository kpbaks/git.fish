# --------------------------------------------------------------------------------------------------
# ideas:
# - Add a way to list all the abbreviations specific to git.fish
# --------------------------------------------------------------------------------------------------
command --query git; or return
command --query fzf; and set -g GIT_FISH_FZF_EXISTS

set -g GIT_FISH_ABBREVIAITONS
set -g GIT_FISH_EXPANDED_ABBREVIAITONS

function _git_abbr
    set -l abbr $argv[1]
    # set -l expanded (string collect $argv[2..])
    set -l expanded $argv[2..]
    abbr -a $argv
    # set --append GIT_FISH_ABBREVIAITONS "$abbr :: $expanded"
    set --append GIT_FISH_ABBREVIAITONS "$abbr"
    set --append GIT_FISH_EXPANDED_ABBREVIAITONS "$expanded"
    # set --append GIT_FISH_ABBREVIAITONS "$argv"
end

function git.fish.abbreviations
    # printf " - %s\n" $GIT_FISH_ABBREVIAITONS
    # echo $GIT_FISH_ABBREVIAITONS \
    #     | sort \
    #     | while read -l abbr
    #     # echo "abbr: $abbr"
    #     printf " - %s\n" $abbr
    #     # set -l words (string split ' ' $abbr)
    #     # set -l abbr $words[1]
    #     # # set -l expanded "$words[2..]"
    #     # printf " - %s\n" $abbr
    #     # printf "   - %s\n" $expanded
    #
    # end

    set -l length_of_longest_abbr 0
    for abbr in $GIT_FISH_ABBREVIAITONS
        set -l abbr_length (string length $abbr)
        if test $abbr_length -gt $length_of_longest_abbr
            set length_of_longest_abbr $abbr_length
        end
    end

    #TODO: <kpbaks 2023-05-24 22:40:11> handle --regex abbrs

    set -l abbreviation_heading abbreviation
    set -l expanded_heading expanded
    set -l padding_length (math $length_of_longest_abbr - (string length $abbreviation_heading))
    set -l padding (string repeat --count $padding_length ' ')


    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l reset (set_color normal)
    # printf "there are %s%d%s abbreviations\n" $git_color (count $GIT_FISH_ABBREVIAITONS) $reset
    _git_fish_echo (printf "there are %s%d%s abbreviations\n" $git_color (count $GIT_FISH_ABBREVIAITONS) $reset)

    set -l hr (string repeat --count $COLUMNS -)
    echo $hr
    printf "%s%s | %s\n" $abbreviation_heading $padding $expanded_heading
    echo $hr


    for i in (seq (count $GIT_FISH_ABBREVIAITONS))
        set -l abbr $GIT_FISH_ABBREVIAITONS[$i]
        set -l expanded $GIT_FISH_EXPANDED_ABBREVIAITONS[$i]
        set -l abbr_length (string length $abbr)
        set -l padding_length (math $length_of_longest_abbr - $abbr_length)
        set -l padding (string repeat --count $padding_length ' ')
        printf "%s%s | " $abbr $padding
        echo "$expanded" | fish_indent --ansi
        # set -l padding (string repeat ' ' (math (math $length_of_longest_abbr - (string length $abbr)) + 2))
        # echo "$abbr + $expanded"

    end
    echo $hr

    # for abbr in $GIT_FISH_ABBREVIAITONS
    #     echo $abbr | fish_indent --ansi
    # end
    #
end

_git_abbr g "# You probably have an abbreviation for what you want to do ;)
git"

# git add
_git_abbr ga --set-cursor 'git add % && git status'
_git_abbr gaa 'git add --all && git status'
_git_abbr gam 'git ls-files --modified | xargs git add && git status'
_git_abbr gau 'git ls-files --others | xargs git add && git status'
_git_abbr gap 'git add --patch && git status'

# git branch
set -l git_branch_format "%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]"

_git_abbr gb git branch
_git_abbr gbl git branch --format="'$git_branch_format'" --sort=-committerdate
_git_abbr gba git branch --all --format="'$git_branch_format'" --sort=-committerdate
_git_abbr gbd git branch --delete
_git_abbr gbD git branch --delete --force
_git_abbr gbm git branch --move

# git checkout
_git_abbr gco git checkout

# git commit
_git_abbr gcm git commit
_git_abbr gcma git commit --amend
# conventional commits
# https://daily-dev-tips.com/posts/git-basics-conventional-commits/
_git_abbr gcmb --set-cursor git commit --message "'build: %'"
_git_abbr gcmc --set-cursor git commit --message "'chore: %'"
_git_abbr gcmi --set-cursor git commit --message "'ci: %'"
_git_abbr gcmd --set-cursor git commit --message "'docs: %'"
_git_abbr gcmf --set-cursor git commit --message "'feat: %'"
_git_abbr gcmx --set-cursor git commit --message "'fix: %'"
_git_abbr gcmm --set-cursor git commit --message "'merge: %'"
_git_abbr gcmp --set-cursor git commit --message "'perf: %'"
_git_abbr gcmr --set-cursor git commit --message "'refactor: %'"
_git_abbr gcmv --set-cursor git commit --message "'revert: %'"
_git_abbr gcms --set-cursor git commit --message "'style: %'"
_git_abbr gcmt --set-cursor git commit --message "'test: %'"

_git_abbr gcmB --set-cursor git commit --message "'build(%): '"
_git_abbr gcmC --set-cursor git commit --message "'chore(%): '"
_git_abbr gcmI --set-cursor git commit --message "'ci(%): '"
_git_abbr gcmD --set-cursor git commit --message "'docs(%): '"
_git_abbr gcmF --set-cursor git commit --message "'feat(%): '"
_git_abbr gcmX --set-cursor git commit --message "'fix(%): '"
_git_abbr gcmM --set-cursor git commit --message "'merge(%): '"
_git_abbr gcmP --set-cursor git commit --message "'perf(%): '"
_git_abbr gcmR --set-cursor git commit --message "'refactor(%): '"
_git_abbr gcmV --set-cursor git commit --message "'revert(%): '"
_git_abbr gcmS --set-cursor git commit --message "'style(%): '"
_git_abbr gcmT --set-cursor git commit --message "'test(%): '"

# git config
_git_abbr gcfg git config
_git_abbr gcfgl git config --list
_git_abbr gcfgg git config --global
_git_abbr gcfgl git config --local


# git diff
_git_abbr gd git diff HEAD
_git_abbr gds git diff --stat HEAD

function parse_git_difftool_tool_help_output
    command git difftool --tool-help | sed --regexp-extended -e '/Use/! d' -e 's/\s*(\w+)\s+(Use.+)$/\1\t\2/'
end

function abbr_git_difftool
    # if set -q GIT_FISH_FZF_EXISTS
    #     set -l tool (parse_git_difftool_tool_help_output | fzf --header "Select a tool" --with-nth 2 | cut -f 1)
    #     echo "tool: $tool"
    #     if test $status -eq 0
    #         echo -- git difftool --tool=$tool
    #         return
    #     end
    # end

    echo -- git difftool --tool=%
end

# git difftool
_git_abbr gdt --set-cursor --function abbr_git_difftool

# git grep
_git_abbr gg git grep

# git log
_git_abbr gl git log --graph
_git_abbr glo git log --oneline --decorate --graph --all

# git merge
_git_abbr gm git merge
_git_abbr gma git merge --abort
_git_abbr gmc git merge --continue


# git mv
_git_abbr gmv git mv

# git pull
_git_abbr gp git pull --progress
_git_abbr pull git pull --progress
# git push

function abbr_git_push
    # check if the local branch has a remote branch of the same name
    # if not, run `git push --set-upstream origin <branch-name>`
    # if yes, run `git push`
    set -l branch (git rev-parse --abbrev-ref HEAD)
    set -l remote_branch (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if test $status -ne 0
        echo -- "git push --set-upstream origin $branch% # no remote branch found, creating one"
        return
    else
        echo -- git push
    end
end

_git_abbr gP --set-cursor --function abbr_git_push
_git_abbr push git push --progress

# git rebase
_git_abbr grb git rebase
_git_abbr grbi git rebase --interactive

# git reflog
_git_abbr grl git reflog


# git restore
_git_abbr gr git restore

# git rm
_git_abbr grm git rm


# git show
_git_abbr gsh git show

# git status
_git_abbr gs git status --untracked-files=all
_git_abbr gss git status --short --branch --untracked-files=all

# git stash
_git_abbr gst git stash
_git_abbr gstp git stash pop
_git_abbr gsta git stash apply
_git_abbr gstd git stash drop
_git_abbr gstl git stash list

# git submodule
_git_abbr gsm git submodule
_git_abbr gsms git submodule status
_git_abbr gsml git submodule status


# git switch
function abbr_git_switch
    set -l cmd git switch
    # check that we are in a git repo
    if not command git rev-parse --is-inside-work-tree >/dev/null
        echo -- $cmd
        return
    end
    # credit: https://stackoverflow.com/a/52222248/12323154
    if not command git symbolic-ref --quiet HEAD >/dev/null 2>/dev/null
        # We are in a detached HEAD state
        # so we can't switch to a branch, but we likely want to switch to the main branch
        # again. So we append '-' to the command.
        echo -- "$cmd -"
    end
    # Check how many branches there are
    # if there are 2, then append the other branch name to the command
    # else output the command.
    # This is a nice quality of life improvement when you have a repo with two branches
    # that you switch between often. E.g. master and develop.
    # set -l branches (command git branch)
    set -l branches_count (command git branch | count)
    if test $branches_count -eq 2
        set -l other_branch (command git branch | string match --invert --regex '^\*' | string trim)
        set --append cmd $other_branch
        echo "# You are in a git repo with only 2 branches.
# My guess is that you want to switch to branch: $other_branch."
    end

    echo -- "$cmd"
end

_git_abbr gsw --function abbr_git_switch


# git worktree
_git_abbr gwt git worktree
# it is best practive to create a worktree in a directory that is a sibling of the current directory
function abbr_git_worktree_add
    set -l dirname (path basename $PWD)
    set -l worktree_dirname "$dirname-wt"
    echo -- git worktree add "../$worktree_dirname/%" --detach
end
_git_abbr gwta --set-cursor --function abbr_git_worktree_add
_git_abbr gwtl git worktree list
_git_abbr gwtm git worktree move
_git_abbr gwtp git worktree prune
_git_abbr gwtrm git worktree remove
_git_abbr gwtrmf git worktree remove --force

#

function abbr_git_clone
    set -l args --recursive
    set -l postfix_args
    set -l clipboard (fish_clipboard_paste)
    # if clipboard is a git url
    # TODO: also handle url of the form https://github.com/<user>/<repo>

    if string match --quiet --regex "^(https?|git)://.*\.git\$" -- "$clipboard"
        set --append args $clipboard
        # Parse the directory name from the url
        set --append postfix_args '; cd'
        set --append postfix_args (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
    end

    set -l depth (string replace --all --regex '[^0-9]' '' $argv[1])
    if test -n $depth
        set --append args --depth=$depth
    end
    echo -- git clone $args $postfix_args
end

_git_abbr git_clone_at_depth --position command --regex "gc[0-9]*" --function abbr_git_clone

set -l sleep_duration 1.5

_git_abbr gac --set-cursor "git add --update && git status && sleep $sleep_duration && git commit"
_git_abbr gacp --set-cursor "git add --update % && git status && sleep $sleep_duration && git commit && git push"

set --erase GIT_FISH_FZF_EXISTS


# other git tools -------------------------------------------------------------

# lazygit
_git_abbr lg lazygit

# gitui
_git_abbr gui gitui


# _git_abbr gam 'git ls-files --modified | xargs git add && git status'
_git_abbr wip "git ls-files --modified | xargs git add && git status && git commit -m 'wip, squash me'"
