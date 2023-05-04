command --query git; or return
command --query fzf; and set -g GIT_FISH_FZF_EXISTS

abbr -a g "# You probably have an abbreviation for what you want to do ;)
git"

# git add
abbr -a ga --set-cursor 'git add % && git status'
abbr -a gaa 'git add --all && git status'
abbr -a gam 'git ls-files --modified | xargs git add && git status'
abbr -a gau 'git ls-files --others | xargs git add && git status'
abbr -a gap 'git add --patch && git status'

# git branch
set -l git_branch_format "%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]"

abbr -a gb git branch
abbr -a gbl git branch --format="'$git_branch_format'" --sort=-committerdate
abbr -a gba git branch --all --format="'$git_branch_format'" --sort=-committerdate
abbr -a gbd git branch --delete
abbr -a gbD git branch --delete --force
abbr -a gbm git branch --move

# git checkout
abbr -a gco git checkout

# git commit
abbr -a gcm git commit
abbr -a gcma git commit --amend
# conventional commits
abbr -a gcmb --set-cursor git commit --message "'build: '"
abbr -a gcmc --set-cursor git commit --message "'chore: '"
abbr -a gcmd --set-cursor git commit --message "'docs: '"
abbr -a gcmf --set-cursor git commit --message "'feat: '"
abbr -a gcmx --set-cursor git commit --message "'fix: '"
abbr -a gcmr --set-cursor git commit --message "'refactor: '"


abbr -a gcmF --set-cursor git commit --message "'feat(%):'"
abbr -a gcmX --set-cursor git commit --message "'fix(%):'"
abbr -a gcmR --set-cursor git commit --message "'refactor(%):'"
abbr -a gcmC --set-cursor git commit --message "'chore(%):'"
abbr -a gcmD --set-cursor git commit --message "'docs(%):'"

# git diff
abbr -a gd git diff HEAD
abbr -a gds git diff --stat HEAD

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
abbr -a gdt --set-cursor --function abbr_git_difftool

# git grep
abbr -a gg git grep

# git log
abbr -a gl git log --graph
abbr -a glo git log --oneline --decorate --graph --all

# git merge
abbr -a gm git merge
abbr -a gma git merge --abort
abbr -a gmc git merge --continue


# git mv
abbr -a gmv git mv

# git pull
abbr -a gp git pull --progress
abbr -a pull git pull --progress
# git push
abbr -a gP git push --progress
abbr -a push git push --progress

# git rebase
abbr -a grb git rebase
abbr -a grbi git rebase --interactive

# git reflog
abbr -a grl git reflog


# git restore
abbr -a gr git restore show

# git rm
abbr -a grm git rm


# git show
abbr -a gsh git show

# git status
abbr -a gs git status --untracked-files=all
abbr -a gss git status --short --branch --untracked-files=all

# git stash
abbr -a gst git stash
abbr -a gstp git stash pop
abbr -a gsta git stash apply
abbr -a gstd git stash drop
abbr -a gstl git stash list

# git submodule
abbr -a gsm git submodule
abbr -a gsms git submodule status
abbr -a gsml git submodule status


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

abbr -a gsw --function abbr_git_switch


# git worktree
abbr -a gwt git worktree
# it is best practive to create a worktree in a directory that is a sibling of the current directory
function abbr_git_worktree_add
    set -l dirname (path basename $PWD)
    set -l worktree_dirname "$dirname-wt"
    echo -- git worktree add "../$worktree_dirname/%" --detach
end
abbr -a gwta --set-cursor --function abbr_git_worktree_add
abbr -a gwtl git worktree list
abbr -a gwtm git worktree move
abbr -a gwtp git worktree prune
abbr -a gwtrm git worktree remove
abbr -a gwtrmf git worktree remove --force

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

abbr -a git_clone_at_depth --position command --regex "gc[0-9]*" --function abbr_git_clone

set -l sleep_duration 1.5

abbr -a gac --set-cursor "git add --update && git status && sleep $sleep_duration && git commit"
abbr -a gacp --set-cursor "git add --update % && git status && sleep $sleep_duration && git commit && git push"

set --erase GIT_FISH_FZF_EXISTS


# other git tools -------------------------------------------------------------

# lazygit
abbr -a lg lazygit

# gitui
abbr -a gui gitui
