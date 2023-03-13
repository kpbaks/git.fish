# git
if command --query fzf
    set -g GIT_FISH_FZF_EXISTS 1
end

abbr -a g git

# git add
abbr -a ga --set-cursor 'git add % && git status'
abbr -a gaa 'git add --all && git status'
abbr -a gam 'git ls-files --modified | xargs git add && git status'
abbr -a gau 'git ls-files --others | xargs git add && git status'

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
abbr -a gcmf --set-cursor git commit --message "'feat(%):'"
abbr -a gcmx --set-cursor git commit --message "'fix(%):'"
abbr -a gcmr --set-cursor git commit --message "'refactor(%):'"
abbr -a gcmc --set-cursor git commit --message "'chore(%):'"
abbr -a gcmd --set-cursor git commit --message "'docs(%):'"

# git diff
abbr -a gd git diff HEAD

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

# git mv
abbr -a gmv git mv

# git pull
abbr -a gp git pull --progress
# git push
abbr -a gP git push --progress

# git rebase
abbr -a grb git rebase
abbr -a grbi git rebase --interactive

# git reflog
abbr -a grl git reflog


# git restore
abbr -a gr git restore show

# git rm
abbr -a grm git rm

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
abbr -a gsub git submodule

# git switch
abbr -a gsw git switch

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


set --erase GIT_FISH_FZF_EXISTS
