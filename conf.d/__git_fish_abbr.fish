status --is-interactive; or return

set --global __GIT_FISH_ABBREVIATIONS
set --global __GIT_FISH_EXPANDED_ABBREVIAITONS

function __git.fish::abbr
    set --local abbr $argv[1]
    set --local expanded $argv[2..]
    abbr --add $argv
    set --append __GIT_FISH_ABBREVIATIONS "$abbr"
    set --append __GIT_FISH_EXPANDED_ABBREVIAITONS "$expanded"
end

# -------------------------------------------------------------------------------------------------
set --query GIT_FISH_GH_ABBR_ENABLE; or set --universal GIT_FISH_GH_ABBR_ENABLE 1

test $GIT_FISH_GH_ABBR_ENABLE = 1
and command --query gh
and begin
    __git.fish::abbr ghs gh status
    # open the current repo in the browser
    __git.fish::abbr ghb gh browse
    __git.fish::abbr ghp gh pr list
    __git.fish::abbr ghr gh repo view --web
    __git.fish::abbr ghg gh gist list
    __git.fish::abbr ghi gh issue
    __git.fish::abbr ghil --set-curosr "gh issue list --state=open% # state can be [ open | close | all ]"
    __git.fish::abbr ghilw gh issue list --web
end
# -------------------------------------------------------------------------------------------------

set --query GIT_FISH_GIT_ABBR_ENABLE; or set --universal GIT_FISH_GIT_ABBR_ENABLE 1
test $GIT_FISH_GIT_ABBR_ENABLE = 1; or return

# git add
function abbr_git_add
    set --local cmd "git add"
    # 1. find all modified, untracked, and deleted files
    set --local addable_files (git ls-files --modified --others --deleted)
    # 2. if there is exactly one file, append it to the command
    if test (count $addable_files) -eq 1
        if string match --quiet --regex "\s" -- "$addable_files"
            # filepath contains spaces, so we wrap them in single qoutes such that the shell will treat the path as a single word
            set --append cmd "'$addable_files'"
        else
            set --append cmd $addable_files
        end
    end

    echo -- "$cmd % && git status"
end

__git.fish::abbr ga --set-cursor --function abbr_git_add
__git.fish::abbr gaa 'git add --all && git status'
__git.fish::abbr gam 'git ls-files --modified | xargs git add && git status'

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
__git.fish::abbr gamcp --set-cursor --function abbr_git_add_modified_and_commit_previous
__git.fish::abbr gau 'git ls-files --others | xargs git add && git status'
__git.fish::abbr gad 'git ls-files --deleted | xargs git add && git status'
__git.fish::abbr gap 'git add --patch && git status'

# git branch
set --local git_branch_format "%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]"

__git.fish::abbr gb git branch
__git.fish::abbr gbl git branch --format="'$git_branch_format'" --sort=-committerdate
__git.fish::abbr gba git branch --all --format="'$git_branch_format'" --sort=-committerdate
__git.fish::abbr gbd git branch --delete
__git.fish::abbr gbD git branch --delete --force
__git.fish::abbr gbm git branch --move

# check if a file is ignored by .gitignore
__git.fish::abbr gci git check-ignore --verbose --non-matching

# git checkout
__git.fish::abbr gco git checkout

# git cherry-pick
__git.fish::abbr gcp git cherry-pick

# git commit
__git.fish::abbr gcm git commit
__git.fish::abbr gcma git commit --amend
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


# TODO: create an emphemeral keybinding for tab that will remove the () and move the cursor to "feat: |"
# https://www.conventionalcommits.org/en/v1.0.0/#commit-message-with--to-draw-attention-to-breaking-change
printf "%s\n" $conventional_commit_types_to_abbreviations | while read -l type key
    set --local key_uppercased (string upper $key)
    __git.fish::abbr gcm$key_uppercased --set-cursor git commit --message "'$type: %'"
    __git.fish::abbr gcm$key_uppercased"!" --set-cursor git commit --message "'$type!: %' # Only use this for BREAKING CHANGES like breaking backwards compatibility!"

    # NOTE:use lowercase for the type with scope, to encourage using commit scopes more often
    # to create a more structured commit history
    __git.fish::abbr gcm$key --set-cursor git commit --message "'$type(%): '"
    __git.fish::abbr gcm$key"!" --set-cursor git commit --message "'$type(%)!: ' # Only use this for BREAKING CHANGES like breaking backwards compatibility!"
end

# TODO: make gcm{m,M}{,!} special such that it prepopulates the commit message with something like "merge: merge {{branch-merging-from}} -> {{branch-merging-into}}"

# git config
__git.fish::abbr gcfg git config
__git.fish::abbr gcfgl git config --list
__git.fish::abbr gcfgg git config --global
__git.fish::abbr gcfgl git config --local

# git diff
__git.fish::abbr gd git diff
__git.fish::abbr gds git diff --stat

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
__git.fish::abbr gdt --set-cursor --function abbr_git_difftool

# git fetch
__git.fish::abbr gf --set-cursor "git fetch % && git status"
__git.fish::abbr gfa --set-cursor "git fetch --all% # Fetch the latest changes from all remote upstream repositories"
__git.fish::abbr gft --set-cursor "git fetch --tags% # Also fetch tags from the remote upstream repository"
__git.fish::abbr gfp --set-cursor "git fetch --prune% # Delete local references to remote branches that have been deleted upstream"

# git grep
__git.fish::abbr gg git grep

# git log
__git.fish::abbr gl git log --graph
__git.fish::abbr glo git log --oneline --decorate --graph --all

# git ls-files
__git.fish::abbr gls git ls-files
__git.fish::abbr glsm git ls-files --modified
__git.fish::abbr glsu git ls-files --others --exclude-standard
__git.fish::abbr glsum git ls-files --unmerged

# git merge
function abbr_git_merge
    set --local cmd git merge
    # if there is 2 local branches, the suggest the other branch as the branch to merge
    set --local branches (command git branch)
    if test (count $branches) -eq 2
        set --local other_branch (command git branch | string match --invert --regex '^\*' | string trim)
        set --append cmd $other_branch
    end

    echo -- $cmd
end
__git.fish::abbr gm --set-cursor --function abbr_git_merge
__git.fish::abbr gma git merge --abort
__git.fish::abbr gmc git merge --continue

# git mv
__git.fish::abbr gmv git mv

# git pull
__git.fish::abbr gp git pull --progress
__git.fish::abbr pull git pull --progress
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
    __git.fish::abbr $abbr --set-cursor --function abbr_git_push
end

# git rebase
__git.fish::abbr grb git rebase
__git.fish::abbr grbi git rebase --interactive

# git reflog
__git.fish::abbr grl git reflog

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

# __git.fish::abbr gr git restore
__git.fish::abbr gr --set-cursor --function abbr_git_restore

# git rm
__git.fish::abbr grm git rm

# git show
__git.fish::abbr gsh git show

# git show-branch
__git.fish::abbr gsb git show-branch

# git status
__git.fish::abbr gs git status --untracked-files=all
__git.fish::abbr gss git status --short --branch --untracked-files=all

# git stash
__git.fish::abbr gst --set-cursor git stash push --message "'%'"
__git.fish::abbr gstp git stash pop
__git.fish::abbr gsta git stash apply
__git.fish::abbr gstd git stash drop
__git.fish::abbr gstl git stash list

# git submodule
__git.fish::abbr gsm git submodule
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
__git.fish::abbr gsma --set-cursor --function abbr_git_submodule_add
__git.fish::abbr gsms git submodule status
__git.fish::abbr gsml git submodule status
__git.fish::abbr gsmf git submodule foreach git

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
    set --local num_branches (command git branch | count)
    switch $num_branches
        case 1
            # If there is only one local branch, there is nothing to switch to.
            # So we just output the command. With a comment explaining that there is no other branch.
            echo -- "$cmd --create % # There is no other local branch to switch to, but you can create one :D"
        case 2
            # if there are 2, then append the other branch name to the command
            # else output the command.
            # This is a nice quality of life improvement when you have a repo with two branches
            # that you switch between often. E.g. master and develop.
            set --local other_branch (command git branch | string match --invert --regex '^\*' | string trim)
            set --append cmd $other_branch
            echo -- "$cmd $other_branch% # you only have 1 other local branch"
        case '*'
            # If there are more than 2 branches, then append the most recently used branch to the command
            set -l branches (command git branch --sort=-committerdate \
                | string match --invert --regex '^\*' \
                | string trim
            )
            echo -- "$cmd $branches[1]% # you have $(count $branches) other local branches: [ $(string join ', ' $branches) ]"
    end
end

__git.fish::abbr gsw --set-cursor --function abbr_git_switch

# git worktree
__git.fish::abbr gwt git worktree
# it is best practive to create a worktree in a directory that is a sibling of the current directory
function abbr_git_worktree_add
    set --local dirname (path basename $PWD)
    set --local worktree_dirname "$dirname-wt"
    echo -- git worktree add "../$worktree_dirname/%" --detach
end
__git.fish::abbr gwta --set-cursor --function abbr_git_worktree_add
__git.fish::abbr gwtl git worktree list
__git.fish::abbr gwtm git worktree move
__git.fish::abbr gwtp git worktree prune
__git.fish::abbr gwtrm git worktree remove
__git.fish::abbr gwtrmf git worktree remove --force

function abbr_git_clone
    set --local args --recurse-submodules
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

__git.fish::abbr git_clone_at_depth --position command --regex "gc[0-9]*" --function abbr_git_clone

set --local sleep_duration 1.5

__git.fish::abbr gac --set-cursor "git add --update && git status && sleep $sleep_duration && git commit"
__git.fish::abbr gacp --set-cursor "git add --update % && git status && sleep $sleep_duration && git commit && git push"

# command --query fzf; and set --global GIT_FISH_FZF_EXISTS
# set --erase GIT_FISH_FZF_EXISTS

# __git.fish::abbr gam 'git ls-files --modified | xargs git add && git status'
__git.fish::abbr wip "git ls-files --modified | xargs git add && git status && git commit --message 'wip, squash me'"

# unstage a file
__git.fish::abbr gun --set-cursor git restore --staged %

__git.fish::abbr gt git tag

# other git tools ---------------------------------------------------------------------------------

# lazygit
__git.fish::abbr lg lazygit

# gitui
# __git.fish::abbr gui gitui
