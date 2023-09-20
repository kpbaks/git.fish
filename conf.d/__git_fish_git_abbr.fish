# --------------------------------------------------------------------------------------------------
# ideas:
# - Add a way to list all the abbreviations specific to git.fish
# --------------------------------------------------------------------------------------------------
command --query git; or return
command --query fzf; and set --global GIT_FISH_FZF_EXISTS

set --global GIT_FISH_ABBREVIAITONS
set --global GIT_FISH_EXPANDED_ABBREVIAITONS

# TODO: <kpbaks 2023-09-20 19:31:28> change function name
function _git_abbr
    set --local abbr $argv[1]
    set --local expanded $argv[2..]
    abbr --add $argv
    set --append GIT_FISH_ABBREVIAITONS "$abbr"
    set --append GIT_FISH_EXPANDED_ABBREVIAITONS "$expanded"
end

# TODO: <kpbaks 2023-09-20 19:31:28> change function name
function git.fish.abbreviations
    # printf " - %s\n" $GIT_FISH_ABBREVIAITONS
    # echo $GIT_FISH_ABBREVIAITONS \
    #     | sort \
    #     | while read -l abbr
    #     # echo "abbr: $abbr"
    #     printf " - %s\n" $abbr
    #     # set --local words (string split ' ' $abbr)
    #     # set --local abbr $words[1]
    #     # # set --local expanded "$words[2..]"
    #     # printf " - %s\n" $abbr
    #     # printf "   - %s\n" $expanded
    #
    # end

    set --local length_of_longest_abbr 0
    for abbr in $GIT_FISH_ABBREVIAITONS
        set --local abbr_length (string length $abbr)
        if test $abbr_length -gt $length_of_longest_abbr
            set length_of_longest_abbr $abbr_length
        end
    end

    #TODO: <kpbaks 2023-05-24 22:40:11> handle --regex abbrs

    set --local abbreviation_heading abbreviation
    set --local expanded_heading expanded
    set --local padding_length (math $length_of_longest_abbr - (string length $abbreviation_heading))
    set --local padding (string repeat --count $padding_length ' ')

    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local reset (set_color normal)
    # printf "there are %s%d%s abbreviations\n" $git_color (count $GIT_FISH_ABBREVIAITONS) $reset
    __git.fish::echo (printf "there are %s%d%s abbreviations\n" $git_color (count $GIT_FISH_ABBREVIAITONS) $reset)

    set --local hr (string repeat --count $COLUMNS -)
    echo $hr
    printf "%s%s | %s\n" $abbreviation_heading $padding $expanded_heading
    echo $hr

    for i in (seq (count $GIT_FISH_ABBREVIAITONS))
        set --local abbr $GIT_FISH_ABBREVIAITONS[$i]
        set --local expanded $GIT_FISH_EXPANDED_ABBREVIAITONS[$i]
        set --local abbr_length (string length $abbr)
        set --local padding_length (math $length_of_longest_abbr - $abbr_length)
        set --local padding (string repeat --count $padding_length ' ')
        printf "%s%s | " $abbr $padding
        echo "$expanded" | fish_indent --ansi
        # set --local padding (string repeat ' ' (math (math $length_of_longest_abbr - (string length $abbr)) + 2))
        # echo "$abbr + $expanded"

    end
    echo $hr

    # for abbr in $GIT_FISH_ABBREVIAITONS
    #     echo $abbr | fish_indent --ansi
    # end
    #
end

# _git_abbr g "# You probably have an abbreviation for what you want to do ;)
# git"
#
# _git_abbr g git

# git add
function abbr_git_add
    set --local cmd "git add"
    # 1. find all modified, untracked, and deleted files
    set --local addable_files (git ls-files --modified --others --deleted)
    # 2. if there is exactly one file, append it to the command
    if test (count $addable_files) -eq 1
        set --append cmd $addable_files
    end

    echo -- "$cmd % && git status"
end
_git_abbr ga --set-cursor --function abbr_git_add
# _git_abbr ga --set-cursor 'git add % && git status'
_git_abbr gaa 'git add --all && git status'
_git_abbr gam 'git ls-files --modified | xargs git add && git status'
function abbr_git_add_modified_and_commit_previous
    # 1. find the previous commit
    set --local cmd "git ls-files --modified | xargs git add && git status"
    set --local previous_commit (history search --max 1 --prefix "git commit --message")
    # 2. if there is a previous commit, add it to the command
    if test -n "$previous_commit"
        set --append cmd "&& $previous_commit"
    end
    echo -- $cmd
end
# This one is nice to have, if your pre-commit hook did not pass, as you would
# have to add the, now, modified files again and then commit them with the same message.
_git_abbr gamcp --set-cursor --function abbr_git_add_modified_and_commit_previous
_git_abbr gau 'git ls-files --others | xargs git add && git status'
_git_abbr gad 'git ls-files --deleted | xargs git add && git status'
_git_abbr gap 'git add --patch && git status'

# git branch
set --local git_branch_format "%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]"

_git_abbr gb git branch
_git_abbr gbl git branch --format="'$git_branch_format'" --sort=-committerdate
_git_abbr gba git branch --all --format="'$git_branch_format'" --sort=-committerdate
_git_abbr gbd git branch --delete
_git_abbr gbD git branch --delete --force
_git_abbr gbm git branch --move

# check if a file is ignored by .gitignore
_git_abbr gci git check-ignore --verbose --non-matching

# git checkout
_git_abbr gco git checkout

# git cherry-pick
_git_abbr gcp git cherry-pick

# git commit
_git_abbr gcm git commit
_git_abbr gcma git commit --amend
# TODO: <kpbaks 2023-06-02 12:23:43> add a gmcm<> variant that adds all modified files and commits them
# conventional commits

# https://daily-dev-tips.com/posts/git-basics-conventional-commits/
# Poor mans dictionary :(
set --local conventional_commit_types_to_abbreviations \
    "build b" \
    "chore c" \
    "ci i" \
    "docs d" \
    "feat f" \
    "fix x" \
    "merge m" \
    "perf p" \
    "refactor r" \
    "revert v" \
    "style s" \
    "test t"

printf "%s\n" $conventional_commit_types_to_abbreviations | while read -l type key
    set --local key_uppercased (string upper $key)
    _git_abbr gcm$key_uppercased --set-cursor git commit --message "'$type: %'"
    _git_abbr gcm$key_uppercased"!" --set-cursor git commit --message "'$type!: %' # Only use this for BREAKING CHANGES like breaking backwards compatibility!"

    # NOTE:use lowercase for the type with scope, to encourage using commit scopes more often
    # to create a more structured commit history
    _git_abbr gcm$key --set-cursor git commit --message "'$type(%): '"
    _git_abbr gcm$key"!" --set-cursor git commit --message "'$type(%)!: ' # Only use this for BREAKING CHANGES like breaking backwards compatibility!"
end


# https://www.conventionalcommits.org/en/v1.0.0/#commit-message-with--to-draw-attention-to-breaking-change

# git config
_git_abbr gcfg git config
_git_abbr gcfgl git config --list
_git_abbr gcfgg git config --global
_git_abbr gcfgl git config --local

# git diff
_git_abbr gd git diff
_git_abbr gds git diff --stat

function parse_git_difftool_tool_help_output
    command git difftool --tool-help | sed --regexp-extended -e '/Use/! d' -e 's/\s*(\w+)\s+(Use.+)$/\1\t\2/'
end

function abbr_git_difftool
    # if set -q GIT_FISH_FZF_EXISTS
    #     set --local tool (parse_git_difftool_tool_help_output | fzf --header "Select a tool" --with-nth 2 | cut -f 1)
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

# git fetch
_git_abbr gf --set-cursor "git fetch % && git status"
_git_abbr gfa --set-cursor "git fetch --all% # Fetch the latest changes from all remote upstream repositories"
_git_abbr gft --set-cursor "git fetch --tags% # Also fetch tags from the remote upstream repository"
_git_abbr gfp --set-cursor "git fetch --prune% # Delete local references to remote branches that have been deleted upstream"

# git grep
_git_abbr gg git grep

# git log
_git_abbr gl git log --graph
_git_abbr glo git log --oneline --decorate --graph --all

# git ls-files
_git_abbr gls git ls-files
_git_abbr glsm git ls-files --modified
_git_abbr glsu git ls-files --others --exclude-standard
_git_abbr glsum git ls-files --unmerged

# git merge
function abbr_git_merge
    # TODO: <kpbaks 2023-06-27 21:29:04> search for the 2. most recent call to `git switch` and use that as the branch to merge
    set --local cmd git merge
    # if there is 2 local branches, the suggest the other branch as the branch to merge
    set --local branches (command git branch)
    if test (count $branches) -eq 2
        set --local other_branch (command git branch | string match --invert --regex '^\*' | string trim)
        set --append cmd $other_branch
    end

    echo -- $cmd
end
_git_abbr gm --set-cursor --function abbr_git_merge
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
    set --local branch (git rev-parse --abbrev-ref HEAD)
    set --local remote_branch (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if test $status -ne 0
        echo -- "git push --set-upstream origin $branch% # no remote branch found, creating one"
        return
    else
        echo -- git push
    end
end

for abbr in gP push
    _git_abbr $abbr --set-cursor --function abbr_git_push
end

# git rebase
_git_abbr grb git rebase
_git_abbr grbi git rebase --interactive

# git reflog
_git_abbr grl git reflog

# git restore
function abbr_git_restore
    # if there is only one modified file, append it to the expand command
    set --local cmd git restore
    set modified (git ls-files --modified)
    if test (count $modified) -eq 1
        set --append cmd $modified
    end
    echo -- $cmd
end

# _git_abbr gr git restore
_git_abbr gr --set-cursor --function abbr_git_restore

# git rm
_git_abbr grm git rm

# git show
_git_abbr gsh git show

# git show-branch
_git_abbr gsb git show-branch

# git status
_git_abbr gs git status --untracked-files=all
_git_abbr gss git status --short --branch --untracked-files=all

# git stash
_git_abbr gst --set-cursor git stash push --message "'%'"
_git_abbr gstp git stash pop
_git_abbr gsta git stash apply
_git_abbr gstd git stash drop
_git_abbr gstl git stash list

# git submodule
_git_abbr gsm git submodule
function abbr_git_submodule_add
    set --local cmd git submodule add
    set --local clipboard (fish_clipboard_paste)
    # if the clipboard is a valid git url, append it to the command
    if string match -q --regex '^https?://.*\.git$' $clipboard
        set --local project_name (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
        set --append cmd $clipboard $project_name
    end
    echo -- $cmd
end
_git_abbr gsma --set-cursor --function abbr_git_submodule_add
_git_abbr gsms git submodule status
_git_abbr gsml git submodule status
_git_abbr gsmf git submodule foreach git

# git switch
function abbr_git_switch
    set --local cmd git switch
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
        return
    end
    # Check how many branches there are
    set --local branches_count (command git branch | count)
    switch $branches_count
        case 1
            # If there is only one local branch, there is nothing to switch to.
            # So we just output the command. With a comment explaining that there is no other branch.
            echo -- "$cmd % # There is no other local branch to switch to."
        case 2
            # if there are 2, then append the other branch name to the command
            # else output the command.
            # This is a nice quality of life improvement when you have a repo with two branches
            # that you switch between often. E.g. master and develop.
            set --local other_branch (command git branch | string match --invert --regex '^\*' | string trim)
            set --append cmd $other_branch
            echo "# You are in a git repo with only 2 branches.
# My guess is that you want to switch to branch: $other_branch"
        case '*'
            # If there are more than 2 branches, then append the most recently used branch to the command
            command git branch --sort=-committerdate \
                | string match --invert --regex '^\*' \
                | read --line branches
            echo -- "$cmd $branches[1]%"
    end
end

_git_abbr gsw --set-cursor --function abbr_git_switch

# git worktree
_git_abbr gwt git worktree
# it is best practive to create a worktree in a directory that is a sibling of the current directory
function abbr_git_worktree_add
    set --local dirname (path basename $PWD)
    set --local worktree_dirname "$dirname-wt"
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
    set --local args --recursive
    set --local postfix_args
    set --local clipboard (fish_clipboard_paste)
    # if clipboard is a git url
    # TODO: also handle url of the form https://github.com/<user>/<repo>

    # You ctrl+l && ctrl+c a git url
    if string match --quiet --regex "^(https?|git)://.*\.git\$" -- "$clipboard"
        set --append args $clipboard
        # Parse the directory name from the url
        set --append postfix_args '&& cd'
        set --append postfix_args (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
    else if string match --quiet --regex "^git clone .*\.git\$" -- "$clipboard"
        # example: git clone https://github.com/nushell/nushell.git
        set --local url (string replace --all --regex '^git clone (.*)\.git$' '$1' $clipboard)
        set --local reponame (string split --max=1 --right / $url)[-1]
        set --append postfix_args $url
        set --append postfix_args "&& cd $reponame"
    end

    set --local depth (string replace --all --regex '[^0-9]' '' $argv[1])
    if test -n $depth
        set --append args --depth=$depth
    end
    echo -- git clone $args $postfix_args
end

_git_abbr git_clone_at_depth --position command --regex "gc[0-9]*" --function abbr_git_clone

set --local sleep_duration 1.5

_git_abbr gac --set-cursor "git add --update && git status && sleep $sleep_duration && git commit"
_git_abbr gacp --set-cursor "git add --update % && git status && sleep $sleep_duration && git commit && git push"

set --erase GIT_FISH_FZF_EXISTS

# other git tools -------------------------------------------------------------

# lazygit
_git_abbr lg lazygit

# gitui
_git_abbr gui gitui

# _git_abbr gam 'git ls-files --modified | xargs git add && git status'
_git_abbr wip "git ls-files --modified | xargs git add && git status && git commit --message 'wip, squash me'"

# unstage a file
_git_abbr gun --set-cursor git restore --staged %
