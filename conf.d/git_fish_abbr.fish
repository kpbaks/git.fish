status --is-interactive; or return 0

# TODO: integrate some of the abbrs from
# https://github.com/jhillyerd/plugin-git

function _git_abbr_list
    string match --entire --regex '^abbr -a' <(status filename) | fish_indent --ansi
end

# -------------------------------------------------------------------------------------------------
set --query git_fish_abbr_enable_gh
or set --universal git_fish_abbr_enable_gh 1

# TODO: put into another file
test $git_fish_abbr_enable_gh = 1
and command --query gh
and begin
    abbr -a ghs gh status
    # open the current repo in the browser
    abbr -a ghb gh browse
    abbr -a ghp gh pr list
    abbr -a ghr gh repo view --web
    abbr -a ghg gh gist list
    abbr -a ghi gh issue
    abbr -a ghil --set-cursor "gh issue list --state=open% # state can be one of: open | closed | all"
    abbr -a ghilw gh issue list --web
    function __git::gh::list-workflows
        set -l dir $PWD
        while test $dir != /
            if test -d $dir/.github/workflows
                # for f in $dir/.github/workflows/*.{yml,yaml}
                #     # if string match
                # end
                # printf '%s\n' $dir/.github/workflows/*.{yml,yaml}

                path basename $dir/.github/workflows/*.{yml,yaml}
                return 0
            end
            set dir (path dirname $dir)
        end

        return 1
    end
    function __git::abbr::gh-workflow-run
        set -l workflows (__git::gh::list-workflows)
        set -l n_workflows (count $workflows)
        if test (count $n_workflows) -gt 1
            printf '# %s\n' $workflows
        end
        # for f in (__git::gh::list-workflows)
        #     echo "# $f"
        # end
        printf "gh workflow run"
        if test $n_workflows -eq 1
            printf " $workflows[1]"
        end
        printf '\n'
    end
    abbr -a ghwr -f __git::abbr::gh-workflow-run
    # abbr -a ghwr gh workflow run
    # jonwoo
    abbr -a pr 'gh pr create -t (git show -s --format=%s HEAD) -b (git show -s --format=%B HEAD | tail -n+3)'
    # TODO: create one called `mr` for gitlab
end
# -------------------------------------------------------------------------------------------------
# TODO: document options in README.md
set --query git_fish_abbr_append_git_status
or set --universal git_fish_abbr_append_git_status 1

set --query git_fish_git_status_command
or set --universal git_fish_git_status_command "git status --untracked-files=all --short --branch --show-stash"

# set --universal git_fish_git_status_command "git status"
# set --universal git_fish_git_status_command gstatus

set --global __and_git_status
if test $git_fish_abbr_append_git_status = 1
    set --global __and_git_status "; and $git_fish_git_status_command"
end

set --query git_fish_abbr_enable_git
or set --universal git_fish_abbr_enable_git 1
test $git_fish_abbr_enable_git = 1; or return 0

# git add
function _abbr_git_add
    # set -l cmd "git add"
    # TODO: use a global variable to store whether we are in a git repo or not
    # to avoid having all other git commands run the "relatively" expensive check, of whether we are in a git repo
    # 1. Find all modified, untracked, and deleted files
    set -l unstaged_and_untracked_files (command git ls-files --others --exclude-standard --modified)
    # 2. If there is exactly one file, append it to the command
    switch (count $unstaged_and_untracked_files)
        case 1
            printf 'git add %s%%' "'$unstaged_and_untracked_files[1]'"
        case 0
            printf '# There are no changes or untracked files to add'
            printf 'git add %%'
        case '*'
            printf 'git add --patch %%'
    end

    # if test (count $unstaged_files) -eq 1
    #     if string match --quiet --regex "\s" -- "$unstaged_files"
    #         # Filepath contains spaces, so we wrap them in single quotes such that the shell will treat the path as a single word
    #         set --append cmd "'$unstaged_files'"
    #     else
    #         set --append cmd $unstaged_files
    #     end
    # end

    # printf "%s %%\n" $cmd
    echo $__and_git_status
end

abbr -a ga --set-cursor -f _abbr_git_add
abbr -a gaa "git add --all"
abbr -a gad "git add (git ls-files --deleted)"
abbr -a gai "git add --interactive"
abbr -a gam "git add (git ls-files --modified)"
abbr -a gap "git add --patch"
abbr -a gau "git add (git ls-files --others --exclude-standard)"

function _abbr_git_add_modified_and_commit_previous
    # 1. find the previous commit
    set -l expansion "git add (git ls-files --modified)"
    set -l previous_commit (history search --max 1 --prefix "git commit --message")
    # 2. if there is a previous commit, add it to the command
    if test -n "$previous_commit"
        set --append expansion "&& $previous_commit"
    end
    echo $expansion
end

# This one is nice to have, if your pre-commit hook did not pass, as you would
# have to add the, now, modified files again and then commit them with the same message.
abbr -a gamcp --set-cursor -f _abbr_git_add_modified_and_commit_previous

# git blame
# abbr -a gb

# git branch
abbr -a gb git branch
abbr -a gbl "git branch --list --verbose"
abbr -a gblr "git branch --list --remotes --verbose"
abbr -a gbd git branch --delete
abbr -a gbD git branch --delete --force
abbr -a gbm git branch --move

# check if a file is ignored by .gitignore
abbr -a gci --set-cursor "git check-ignore --verbose --non-matching *%"

# git checkout
abbr -a gco git checkout

# git cherry-pick
abbr -a gcp git cherry-pick

# git commit
abbr -a gcm git commit
abbr -a gcma git commit --amend
abbr -a gcmp git commit --patch
abbr -a gcmi git commit --interactive

# function __git::abbr::git_commit_skip_selected_pre_commit_hook
#     if test -f .pre-commit-config.yaml; and command --query yq; and command --query fzf
#         set -l hooks (string match --regex --groups-only -- "-\s+id: (\S+)" < .pre-commit-config.yaml)

#         # https://pre-commit.com/#temporarily-disabling-hooks
#         set -l fzf_opts --multi --height=~30% --prompt="select which pre-commit hooks you want to SKIP for this commit: "
#         set -l selected_hooks (printf "%s\n" $hooks | command fzf $fzf_opts)
#         commandline --function repaint
#         if test (count $selected_hooks) -gt 0
#             printf "SKIP=%s " (string join "," -- $selected_hooks)
#         end
#     end

#     echo "git commit"
# end

# # TODO: use a better name
# abbr -a sgcm --set-cursor -f __git::abbr::git_commit_skip_selected_pre_commit_hook


function __git::abbr::gen_git_commit_conventional_commits -a type key
    # Use lowercase for the type with scope, to encourage using commit scopes more often
    # to create a more structured commit history
    # TODO: make gcm{m,M}{,!} special such that it prepopulates the commit message with something like "merge: merge {{branch-merging-from}} -> {{branch-merging-into}}"
    set -l breaking_changes_warning "# only use this for BREAKING CHANGES like breaking backwards compatibility!"
    abbr -a gcm$key --set-cursor "git commit --message '$type(%): '"
    abbr -a gcm$key"!" --set-cursor "git commit --message '$type(%)!: ' $breaking_changes_warning"
    set -l key_uppercased (string upper $key)
    abbr -a gcm$key_uppercased --set-cursor "git commit --message '$type: %'"
    abbr -a gcm$key_uppercased"!" --set-cursor "git commit --message '$type: %' $breaking_changes_warning"
end


function __git::abbr::gen_git_commit_conventional_commits_with_scope -a type key
    set -l abbr gcm$key
    set -l name_of_generated_function __git::abbr::generated::$abbr

    # TODO: add option for user to create custom rules maybe in a file

    # TODO: for the commit types that have a scope, populate the scope with the basename of the modified file, if only one file is modified
    # Generate the function that will be used as the abbreviation
    # handle more cases with single files staged
    # e.g.
    # - flake.nix
    # - .gitignore
    # - CMakeLists.txt
    # - Cargo.{toml,lock}
    eval "function $name_of_generated_function
        set -l staged_files (command git diff --name-only --cached)
        set -l scope
        if test (count \$staged_files) -eq 1
            switch \$staged_files[1]
                case README.md
                    set scope readme
                case CHANGELOG.md
                    set scope changelog
                case flake.nix
                    set scope flake
                case .gitignore
                    set scope gitignore
        	    case CMakelists.txt
                    set scope cmake
                case Cargo.toml
                    set scope cargo
                case journal/main.typ
                    set scope journal
            end

            if string match --regex --groups-only '^.github/workflows/([^.]+)\.(yml|yaml)' \$staged_files[1] | read --line workflow extension
                set scope gh-action:\$workflow
            end
        end

        if test -z \$scope
            echo 'git commit --message \'$type(%): \''
        else
            printf 'git commit --message \'$type(%s): %%\'\n' \$scope
        end
    end"

    abbr -a $abbr --set-cursor -f $name_of_generated_function
end

__git::abbr::gen_git_commit_conventional_commits build b
# __git::abbr::gen_git_commit_conventional_commits chore c
# __git::abbr::gen_git_commit_conventional_commits ci i
__git::abbr::gen_git_commit_conventional_commits docs d
# __git::abbr::gen_git_commit_conventional_commits feat f
# __git::abbr::gen_git_commit_conventional_commits fix x
__git::abbr::gen_git_commit_conventional_commits merge m
# __git::abbr::gen_git_commit_conventional_commits perf p
__git::abbr::gen_git_commit_conventional_commits refactor r
__git::abbr::gen_git_commit_conventional_commits revert v
__git::abbr::gen_git_commit_conventional_commits style s
__git::abbr::gen_git_commit_conventional_commits test t

__git::abbr::gen_git_commit_conventional_commits_with_scope feat f
__git::abbr::gen_git_commit_conventional_commits_with_scope fix x
__git::abbr::gen_git_commit_conventional_commits_with_scope chore c
__git::abbr::gen_git_commit_conventional_commits_with_scope ci i
__git::abbr::gen_git_commit_conventional_commits_with_scope perf p
__git::abbr::gen_git_commit_conventional_commits_with_scope docs d

# git config
abbr -a gcfg "git config"
abbr -a gcfge "git config --edit"

function _git_config_detect_scope
    # worktree -> local -> global -> system
    set -l scope

    if command git rev-parse --is-inside-work-tree 2>/dev/null >&2
        # Method to disambiguate between worktree and not taken from: https://stackoverflow.com/questions/56069224/whats-the-git-command-to-distinguish-a-worktree-folder
        set -l git_dir (command git rev-parse --git-dir)
        set -l git_common_dir (command git rev-parse --git-common-dir)
        if test $git_dir = $git_common_dir
            set scope --local
        else
            set scope --worktree
        end
    else if string match --quiet "$HOME*" -- $PWD
        set scope --global
    else if test -r /etc/gitconfig
        set scope --system
    end

    echo $scope
end

function _abbr_git_config_list
    set -l expansion git config --show-origin --show-scope --includes --list
    set -a expansion (_git_config_detect_scope)
    echo $expansion
end
abbr -a gcfgl --function _abbr_git_config_list

# git diff
function _abbr_git_diff
    command --query difft # if installed
    and not set --query --export GIT_EXTERNAL_DIFF # and not already set as an env var
    and not string match --quiet "*GIT_EXTERNAL_DIFF=*" (commandline --cut-at-cursor) # and not already set as a oneof env var override
    and printf "GIT_EXTERNAL_DIFF=difft " # then use as the diff tool
    # TODO: append --staged if all modified files are staged

    echo "git diff"
end
abbr -a gd --set-cursor -f _abbr_git_diff

# TODO: create a function for this similar to `gstatus`
abbr -a gds git diff --staged

function _abbr_git_fetch
    if not command -q gum
        echo "git fetch"
        return
    end

    # TODO: add to `gitui` aswell
    # fetch "Retrieves changes from the remote"
    # fetch --prune "Retrieves changes from the remote and removes deleted remote branches"
    # fetch --tags "Retrieves changes from the remote including all tags"
    # fetch --all "Retrieves changes from all remotes" # TODO: enumerate known remotes here
    # fetch --all --prune "Retrieves changes from all remotes and removes deleted remote branches"
    # fetch --all --tags "Retrieves changes from all remotes including all tags"

    # TODO: handle case where user presses esc gracefully
    gum choose
    commandline -f repaint
end

# git fetch
abbr -a gf --set-cursor "git fetch %"
abbr -a gfa --set-cursor "git fetch --all% # fetch the latest changes from all remote upstream repositories"
abbr -a gft --set-cursor "git fetch --tags% # also fetch tags from the remote upstream repository"
abbr -a gfp --set-cursor "git fetch --prune% # delete local references to remote branches that have been deleted upstream"

# git grep
function _abbr_git_grep
    set -l expansion git grep "'%'"
    if string match --regex --groups-only "gg([0-9]+)" -- $argv[1] | read n
        set -a expansion "HEAD~$n"
    end

    echo $expansion
end
abbr -a gg --regex "gg[0-9]*" --set-cursor --function _abbr_git_grep
abbr -a gga --set-cursor "git grep '%' -- (git rev-list --all) # This might take some time to execute!"

# git log
function _abbr_git_log
    set -l expansion git log
    if string match --regex --groups-only "gl([0-9]+)" -- $argv[1] | read n
        set -a expansion --max-count $n
    end

    echo $expansion
end
abbr -a gl --regex "gl[0-9]*" --function _abbr_git_log

function _abbr_git_log_oneline
    set -l expansion git log --oneline --graph
    if string match --regex --groups-only "gl([0-9]+)" -- $argv[1] | read n
        set -a expansion --max-count $n
    end

    echo $expansion
end
abbr -a glo --regex "glo[0-9]*" --function _abbr_git_log_oneline

# git ls-files
abbr -a gls git ls-files
abbr -a glsm git ls-files --modified
abbr -a glsu git ls-files --others --exclude-standard
abbr -a glsum git ls-files --unmerged

# git merge
function _abbr_git_merge
    set -l expansion git merge
    # if there is 2 local branches, the suggest the other branch as the branch to merge
    set -l branches (command git branch)
    if test (count $branches) -eq 2
        set -l other_branch (command git branch | string match --invert --regex '^\*' | string trim)
        set -a expansion $other_branch
    end

    echo $expansion
end

abbr -a gm --set-cursor --function _abbr_git_merge
abbr -a gma git merge --abort
abbr -a gmc git merge --continue

# git mv
# TODO: try to detect a relevant file to move
abbr -a gmv git mv

# git pull
set --query git_fish_abbr_git_pull_merge_strategy
or set --universal git_fish_abbr_git_pull_merge_strategy --ff-only

# TODO: create a user setting to choose between `--rebase` `--no-rebase` `--ff-only`
# TODO: maybe add `--no-rebase`
# TODO: show how many commits that can be pulled in a comment similar to `gP` abbreviation
function __git::abbr::git_pull
    # TODO: figure out how to do without it being annoying
    # printf "# %s\n" (command git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative master..origin/master)

    #echo git pull $git_fish_abbr_git_pull_merge_strategy

    #https://www.youtube.com/watch?v=xN1-2p06Urc
    set -l opts
    if test (command git config pull.rebase) = false
        set -a opts --rebase
    end

    echo git pull $opts
    if contains -- --rebase $opts
        # Only append if use --rebase
        echo or git rebase --abort
    end
end

# abbr -a gp -f __git::abbr::git_pull --set-cursor
abbr -a gpnrb git pull --no-rebase
abbr -a gprb git pull --rebase
abbr -a gpnff git pull --no-ff
abbr -a gpl git pull

# git push
function __git::abbr::git_push
    # TODO: print the remote pushing to
    # FIXME: what if the commit msg is longer than 1 line?
    # TODO: add time since commit
    set -l unpushed_commits (command git log --pretty=format:"%s" @{u}..)
    if test (count $unpushed_commits) -gt 0
        # List the commits that will be pushed
        # TODO: print the duration since the commit was made
        printf "# %d unpushed commit%s:\n" (count $unpushed_commits) (test (count $unpushed_commits) -eq 1; and echo ""; or echo "s")
        printf "# - %s\n" $unpushed_commits
    else
        # FIXME: thinks no commits are found when no upstream
        echo "# no commits to push ¯\\_(ツ)_/¯"
    end

    set -l git_push_opts
    set -l branch (command git rev-parse --abbrev-ref HEAD)
    set -l remote_branch (command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if test $status -ne 0
        # Local branch has no remote branch, so create one
        echo "git push $git_push_opts --set-upstream origin $branch% # no remote branch found, creating one"
    else
        set -l unpushed_tags (command git push --tags --dry-run &| string match --regex --groups-only '\* \[new tag\]\s+(\S+)')
        if test (count $unpushed_tags) -gt 0
            printf '# unpushed tags: %d\n' (count $unpushed_tags)
            printf '# - %s\n' $unpushed_tags

            set -a git_push_opts --tags
        end
        echo git push $git_push_opts
    end
end

function __git::find_root -a start_dir
    if test (count $argv) -eq 0
        set start_dir $PWD
    end

    set -l dir $start_dir
    while $dir != /
        if test -d $dir/.git
            echo $dir
            return 0
        end

        set dir (path dirname $dir)
    end

    return 1
end

function __git::abbr::git_push_or_pull
    # 1. Check if current branch has commits from the remote, that has not been merged in.
    # 2. If there are 1 or more commits that can be merged, then expand to `git pull` i.e. `__git::abbr::git_pull`
    # 3. Else expand to `git push` i.e. `__git::abbr::git_push`

    # set -l unmerged_commits (command git log --pretty=format:"%s" @{u}..)

    # command git rev-list --left-right --count $current_branch...origin/$current_branch | read local remote


    # set -l remote_branch (command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | read remote_branch
        # Strip "origin/" prefix
        set -l current_branch (string split --max=1 / $remote_branch)[-1]
        # FIXME: use a timeout cache for this instead
        set -l n 6
        if test (random 1 $n) -eq $n
            command git fetch --quiet
            echo "# called `git fetch --quiet` in the background against remote branch: $remote_branch"
        end

        command git rev-list --left-right --count $current_branch...origin/$current_branch | read n_local_commits n_remote_commits
        # echo "local_commits: $n_local_commits"
        # echo "remote_commits: $n_remote_commits"
        # FIXME: what if there is nothing to push or pull?
        if test $n_local_commits -eq 0 -a $n_remote_commits -eq 0
            # Check if local branch is dirty
            set -l stats (command git diff --stat --exit-code)
            if test $status -ne 0
                echo '# local branch is dirty. please commit or stash your changes'
                printf '# %s\n' $stats
                echo '%'
                return 0
            end
            # echo '# '
        end
        if test $n_remote_commits -gt 0
            # There are commits that can be pulled
            __git::abbr::git_pull
        else
            # There are no commits that can be pulled

            set -l squashes (squashes)
            if test (count $squashes) -gt 0
                printf '# you have some commits to squash, before you can push!\n'
                # printf '#squashes = %d\n' (count $squashes)
                for squash in $squashes
                    echo "# - $squash"
                end
                echo "git rebase --interactive --autosquash "
                # printf '# - %s\n' $squashes
            else
                __git::abbr::git_push
            end
        end
    else
        set -l branch (command git rev-parse --abbrev-ref HEAD)
        echo "git push --set-upstream origin $branch% # no remote branch found, creating one"
    end
end

# TODO: integrate `squashes`
# TODO(tir 17 sep 22:21:50 CEST 2024): print a comment to indicate that we are performing a fetch to see if we need to push or pull
abbr -a gp --set-cursor -f __git::abbr::git_push_or_pull

# git rebase
abbr -a grb "git rebase --committer-date-is-author-date"
abbr -a grba git rebase --abort
abbr -a grbc git rebase --continue
abbr -a grbi "git rebase --committer-date-is-author-date --interactive"

# git reflog
abbr -a grl git reflog

# git restore
function _abbr_git_restore
    set -l expansion git restore
    set modified (git ls-files --modified)
    if test (count $modified) -eq 1
        # if there is only one modified file, append it to the expand command
        set -a expansion $modified
    end

    echo $expansion
end

abbr -a gr --set-cursor --function _abbr_git_restore
abbr -a grm "git restore (git ls-files --modified)"
abbr -a gun --set-cursor "git restore --staged (git diff --staged --name-only) %"

# git show
function _abbr_git_show
    set -l expansion "git show"
    if string match --regex --groups-only "gsh([0-9]+)" -- $argv[1] | read n
        set -a expansion "HEAD~$n"
    else
        set -a expansion HEAD
    end

    if command --query difft; and not set --query --export GIT_EXTERNAL_DIFF
        set -p expansion "GIT_EXTERNAL_DIFF=difft"
        set -a expansion --ext-diff
    end
    echo $expansion
end
abbr -a gsh --regex "gsh[0-9]*" --function _abbr_git_show

# git show-branch
abbr -a gsb git show-branch

# git status
abbr -a gs $git_fish_git_status_command
# abbr -a gss git status --short --branch --untracked-files=all

# git stash
abbr -a gst --set-cursor git stash push --message "'%'"
abbr -a gstp git stash pop
abbr -a gsta git stash apply
# abbr -a gstd git stash drop
abbr -a gstl git stash list

function _abbr_git_stash_diff
    if command -q difft; and not set --query --export GIT_EXTERNAL_DIFF
        echo "GIT_EXTERNAL_DIFF=difft git stash show -p stash@{1%} --ext-diff"
    else
        echo "git stash show -p stash@{1%}"
    end
end

abbr -a gstd --set-cursor -f _abbr_git_stash_diff

# git submodule
abbr -a gsm git submodule
function _abbr_git_submodule_add
    set -l cmd git submodule add
    set -l clipboard (fish_clipboard_paste)
    # if the clipboard is a valid git url, append it to the command
    if string match -q --regex '^https?://.*\.git$' $clipboard
        set -l project_name (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
        set --append cmd $clipboard $project_name
    end
    echo $cmd
end
abbr -a gsma --set-cursor -f _abbr_git_submodule_add
abbr -a gsms git submodule status
abbr -a gsmf git submodule foreach git

# git switch
function _abbr_git_switch
    set -l cmd git switch
    # check that we are in a git repo
    if not command git rev-parse --is-inside-work-tree 2>/dev/null >&2
        echo $cmd
        return 0
    end
    # credit: https://stackoverflow.com/a/52222248/12323154
    if not command git symbolic-ref --quiet HEAD >/dev/null 2>/dev/null
        # We are in a detached HEAD state
        # so we can't switch to a branch, but we likely want to switch to the main branch
        # again. So we append '-' to the command.
        echo "# you are in a detached HEAD state"
        echo "$cmd -"
        return 0
    end
    # Check how many branches there are
    set -l num_branches (command git branch | count)
    switch $num_branches
        case 0 # unreachable
        case 1
            # If there is only one local branch, there is nothing to switch to.
            # So we just output the command. With a comment explaining that there is no other branch.
            echo "# There is no other local branch to switch to, but you can create one :D"
            echo "$cmd --create %"
        case 2
            # if there are 2, then append the other branch name to the command
            # else output the command.
            # This is a nice quality of life improvement when you have a repo with two branches
            # that you switch between often. E.g. master and develop.
            set -l other_branch (command git branch | string match --invert --regex '^\*' | string trim)
            echo "# you only have 1 other local branch"
            echo "$cmd $other_branch%"
        case '*'
            # If there are more than 2 branches, then append the most recently used branch to the command
            set -l branches (git branch --sort=-committerdate --format="%(refname:short) %(committerdate:relative)" | column -t -s " " --table-columns-limit 2 --table-right 2)
            echo "# you have $(count $branches) other local branches: (sorted by committerdate)"
            printf '# - %s\n' $branches

            set -l moves (git reflog show --format="%gs" --grep-reflog="checkout: moving from" --max-count=1)
            if string match --groups-only --regex '^checkout: moving from (\S+) to (\S+)$' -- $moves | read --line from to
                echo "$cmd $from%"
            else
                # Since a reflog can be pruned, it might not have a result to the query above
                # in which case it is better to look at the committerdate
                set -l current_branch (command git rev-parse --abbrev-ref HEAD)
                set -l branch_to_switch_to
                # If you just made a commit then the current branch is the most recent
                # In that case use the next-recent
                if test $current_branch -eq $branches[1]
                    set branch_to_switch_to $branches[2]
                else
                    set branch_to_switch_to $branches[1]
                end
                echo "$cmd $(string split --fields=1 ' ' -- $branch_to_switch_to)%"
            end
    end

    # TODO: maybe check if the user has configured a "change-branch" hook (if one exists?)
    # and if it exists, then do not append this
    echo "and git fetch"
end

abbr -a gsw --set-cursor -f _abbr_git_switch
abbr -a gswc git switch --create

# git worktree
abbr -a gwt git worktree
# it is best practive to create a worktree in a directory that is a sibling of the current directory
function _abbr_git_worktree_add
    set -l dirname (path basename $PWD)
    set -l worktree_dirname "$dirname-wt"
    echo git worktree add "../$worktree_dirname/%" --detach
end

abbr -a gwta --set-cursor -f _abbr_git_worktree_add
abbr -a gwtl git worktree list
abbr -a gwtm git worktree move
abbr -a gwtp git worktree prune
abbr -a gwtrm git worktree remove
abbr -a gwtrmf git worktree remove --force

function _abbr_git_clone
    set -l args --recurse-submodules
    set -l postfix_args
    # TODO: handle case where clipboard can not be read
    set -l clipboard (fish_clipboard_paste)

    # You ctrl+l && ctrl+c a git url
    if string match --quiet --regex "^(https?|git)://.*\.git\$" -- "$clipboard"
        set -a args $clipboard
        # Parse the directory name from the url
        set -a postfix_args '&& cd'
        set -a postfix_args (string replace --all --regex '^.*/(.*)\.git$' '$1' $clipboard)
    else if string match --quiet --regex "^git clone .*\.git\$" -- "$clipboard"
        # example: git clone https://github.com/nushell/nushell.git
        set -l url (string replace --all --regex '^git clone (.*)\.git$' '$1' $clipboard)
        set -l reponame (string split --max=1 --right / $url)[-1]
        set -a postfix_args $url
        set -a postfix_args "&& cd $reponame"
    else if string match --groups-only --regex "^\s*git clone https://git(hub|lab)\.com/([^/]+)/(.+)" $clipboard | read --line _hub owner repository
        # example: git clone https://github.com/bevyengine/bevy
        set -a postfix_args $clipboard
        set -a postfix_args "&& cd $repository"
    end

    # TODO: use (capture) instead
    set -l depth (string replace --all --regex '[^0-9]' '' $argv[1])
    if test -n $depth
        set -a args --depth=$depth
    end

    echo git clone $args $postfix_args
end

abbr -a git_clone_at_depth --regex "gc[0-9]*" --function _abbr_git_clone


# TODO: detect if the last commit had message `squash! WIP` and you were the author, and suggest to use amend instead
abbr -a gwip "git add (git ls-files --modified) && git commit --message 'squash! WIP' --no-verify"

# unstage a file


# jonwoo
# TODO: i think there is a --autostash flag to simplify this
# abbr -a gah 'git stash; and git pull --rebase; and git stash pop'

# TODO: implement a abbr or function that does this: https://stackoverflow.com/questions/19576742/how-to-clone-all-repos-at-once-from-github

# functions/gbo.fish
# abbr -a gboa gbo --all
