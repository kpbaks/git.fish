status is-interactive; or return 0

# The purpose of this function is to emit an event whenever
# the current working directory changes to a directory that
# is the root of a git repository.
# Other functions in this plugin can then subscribe to this
# event by specifying `function <name> --on-event in_git_repo_root_directory`
# in their definition.
# This way, the responsibility of checking whether the current
# working directory is the root of a git repository is delegated
# to this function only.
function __git.fish::emitters::in_git_repo_root_directory --on-variable PWD
    test -d .git; or return # If the current directory is not a git repo, do nothing

    set --query __git_fish_last_git_repo_root_directory
    or set --global __git_fish_last_git_repo_root_directory ""

    # Do not want to emit the event if the user has just changed to a subdirectory, and then back to the root directory
    set --local been_here_recently 0
    test $PWD = $__git_fish_last_git_repo_root_directory; or set been_here_recently 1
    set __git_fish_last_git_repo_root_directory $PWD # Update the last git repo root directory after the check above
    test $been_here_recently -eq 1; or return

    # The user is in a git repo root directory, that is different from the last git repo root directory visited
    # in this fish session. Emit the event.
    emit in_git_repo_root_directory $PWD
end

function __git.fish::remind_me_to_create_remote --on-event in_git_repo_root_directory
    set --query GIT_FISH_REMIND_ME_TO_CREATE_REMOTE; or set --universal GIT_FISH_REMIND_ME_TO_CREATE_REMOTE 1
    test GIT_FISH_REMIND_ME_TO_CREATE_REMOTE = 1; or return
    set --local remote_branch (command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if test $status -ne 0
        __git.fish::echo "no remote branch detected. connect to one with:"
        # TODO: <kpbaks 2023-09-09 17:19:23> improve aesthetics of this message
        set --local connect_to_remote_cmd "git push -u 'remote' 'branch'"
        echo -en "\t"
        echo $connect_to_remote_cmd | fish_indent --ansi
        return
    end
end

function __git.fish::auto_fetch --on-event in_git_repo_root_directory
    set --query GIT_FISH_AUTO_FETCH; or set --global GIT_FISH_AUTO_FETCH 0
    test $GIT_FISH_AUTO_FETCH -eq 1; or return 0

    command git rev-parse @{upstream} >/dev/null 2>/dev/null; or return 0 # No remote branch detected

    # Remote branch detected
    command git fetch --quiet

    set -l head_hash (command git rev-parse HEAD)
    set -l branch_name (command git rev-parse --abbrev-ref HEAD)
    set -l upstream_hash (command git ls-remote origin --tags refs/heads/$branch_name | string match --regex --groups-only "^(\S+)")

    if test $head_hash != $upstream_hash
        # TODO: <kpbaks 2023-09-19 21:33:09> figure out if ahead or behind
        __git.fish::echo "You are behind the remote branch. Run $(printf "git pull" | fish_indent --ansi) to update!"
        __git.fish::echo "or you are ahead of the remote branch. Run $(printf "git push" | fish_indent --ansi) to update!"
    end

    # TODO: implement this
    # Figure out what commits that are in the remote branch but not in the local branch
    # set --local commits (command git log --pretty=format:"%h" $head_hash..$upstream_hash)
    # set --local num_commits (count $commits)
    # if test $num_commits -eq 0
    #     return
    # end
    #
    # set --local yellow (set_color yellow)
    # set --local green (set_color green)
    # set --local reset (set_color normal)
    # __git.fish::echo (printf "You are %s%d%s commits behind the remote branch. Run %sgit pull%s to update!" \
    # $yellow $num_commits $reset $green $reset)



end

# when inside a git repo, check if the number of unstaged changes (i.e. lines)
# is greater than `$GIT_FISH_REMIND_ME_TO_COMMIT_THRESHOLD`
# if so, print a reminder to commit

function __git.fish::remind_me_to_commit --on-event in_git_repo_root_directory
    set --query GIT_FISH_REMIND_ME_TO_COMMIT_THRESHOLD; or set --universal GIT_FISH_REMIND_ME_TO_COMMIT_THRESHOLD 50
    set --query GIT_FISH_REMIND_ME_TO_COMMIT_ENABLED; or set --universal GIT_FISH_REMIND_ME_TO_COMMIT_ENABLED 1
    test GIT_FISH_REMIND_ME_TO_COMMIT_ENABLED = 1; or return
    # FIX: why does it actually trigger when fish is started?
    # do not want to run it every time a new fish shell is opened
    if test $PWD = $__fish_config_dir
        return
    end

    # defined in $__fish_config_dir/functions/should_i_commit.fish
    # part of git.fish
    should_i_commit $GIT_FISH_REMIND_ME_TO_COMMIT_THRESHOLD
end

function __git.fish::avoid_being_on_main_branch --on-event in_git_repo_root_directory
    set --query GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH; or set --universal GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH 1
    test GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH = 1; or return

    set --local branches (command git branch --list --no-color)
    if test (count $branches) -eq 0
        # Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        return
    end

    set --local current_branch (git rev-parse --abbrev-ref HEAD)

    if contains -- $current_branch main master # The 2 most common names for the main branch
        set --local yellow (set_color yellow)
        set --local green (set_color green)
        set --local reset (set_color normal)
        # TODO: <kpbaks 2023-09-09 22:32:23> Suggest some of the other local branches. If there are none, suggest creating one.
        __git.fish::echo (printf "You are on the %s%s%s branch. You should be on a %sfeature%s branch!" \
			$yellow $current_branch $reset $green $reset)
    end
end
