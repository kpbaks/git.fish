status is-interactive; or return 0

set -g __git_fish_git_dirs_visited
function __git.fish::git_dirs_visited
    printf "%s\n" $__git_fish_git_dirs_visited
end
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
    # If the current directory is not a git repo, do nothing
    # NOTE: This does not account for when you are in a subdirectory of a git repo
    test -d .git; or return 0

    set --query __git_fish_last_git_repo_root_directory
    or set --global __git_fish_last_git_repo_root_directory ""

    # Do not want to emit the event if the user has just changed to a subdirectory, and then back to the root directory
    set -l been_here_recently 0
    test $PWD = $__git_fish_last_git_repo_root_directory; or set been_here_recently 1
    set __git_fish_last_git_repo_root_directory $PWD # Update the last git repo root directory after the check above
    test $been_here_recently -eq 1; or return 0

    # check if we've already visited this directory
    # if not, add it to the list of visited directories
    # this is to prevent annoying the user by asking them again and again in
    # the same shell session.
    if not contains -- $PWD $__git_fish_git_dirs_visisted
        set --append __git_fish_git_dirs_visisted $PWD
    end
    # The user is in a git repo root directory, that is different from the last git repo root directory visited
    # in this fish session. Emit the event.
    emit in_git_repo_root_directory $PWD
end

function __git.fish::reminders::connect-to-remote --on-event in_git_repo_root_directory
    # TODO: create these variables once
    set --query GIT_FISH_REMIND_ME_TO_CREATE_REMOTE; or set --global GIT_FISH_REMIND_ME_TO_CREATE_REMOTE 0
    test $GIT_FISH_REMIND_ME_TO_CREATE_REMOTE -eq 1; or return 0

    command git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>/dev/null; and return 0
    # No remote branch detected
    # if not command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null
    __git.fish::echo "No remote branch detected. Connect to one with:"
    printf "\t"
    # TODO: <kpbaks 2023-09-09 17:19:23> improve aesthetics of this message
    # TODO: predict the name of the upstream from the name of the user (use git config) to get it
    # TODO: what if user.name has not been set?
    set -q __git_fish_username; or set -g __git_fish_username (command git config --global --get user.name)
    set -l connect_to_remote_cmd "git push -u 'remote' 'branch'"
    echo $connect_to_remote_cmd | fish_indent --ansi
    # end
end

function __git.fish::auto_fetch --on-event in_git_repo_root_directory
    set --query GIT_FISH_AUTO_FETCH; or set --global GIT_FISH_AUTO_FETCH 0
    test $GIT_FISH_AUTO_FETCH -eq 1; or return 0

    # TODO: maybe print a warning if this is the case
    command git rev-parse @{upstream} >/dev/null 2>/dev/null; or return 0 # No remote branch detected

    # Remote branch detected
    # TODO: maybe but in background with `&` to not block for a second or 2, which is annoying
    command git fetch --quiet

    set -l head_hash (command git rev-parse HEAD)
    set -l branch_name (command git rev-parse --abbrev-ref HEAD)
    set -l upstream_hash (command git ls-remote origin --tags refs/heads/$branch_name | string match --regex --groups-only "^(\S+)")

    if test $head_hash != $upstream_hash
        # TODO: <kpbaks 2023-09-19 21:33:09> figure out if ahead or behind
        # See how I do it in `gstatus`
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

function __git::reminders::should-i-commit --on-event in_git_repo_root_directory
    # when inside a git repo, check if the number of unstaged changes (i.e. lines)
    # is greater than `$git_fish_reminders_should_i_commit_threshold`
    # if so, print a reminder to commit

    set --query git_fish_reminders_should_i_commit_threshold
    or set --universal git_fish_reminders_should_i_commit_threshold 50

    set --query git_fish_reminders_should_i_commit_enable
    or set --universal git_fish_reminders_should_i_commit_enable 0

    test $git_fish_reminders_should_i_commit_enable -eq 1; or return 0

    # FIX: why does it actually trigger when fish is started?
    # do not want to run it every time a new fish shell is opened
    test $__fish_config_dir = "$PWD"; or return 0
    # defined in $__fish_config_dir/functions/should_i_commit.fish
    # part of git.fish
    should_i_commit $git_fish_reminders_should_i_commit_threshold
end

function __git.fish::reminders::avoid_being_on_main_branch --on-event in_git_repo_root_directory
    set --query GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH; or set --universal GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH 0
    test $GIT_FISH_AVOID_BEING_ON_MAIN_BRANCH -eq 1; or return 0

    set -l branches (command git branch --list --no-color)
    if test (count $branches) -eq 0
        # TODO: Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        return 0
    end

    set -l current_branch (command git rev-parse --abbrev-ref HEAD)

    if contains -- $current_branch main master # The 2 most common names for the main branch
        set -l reset (set_color normal)
        set -l yellow (set_color yellow)
        set -l green (set_color green)
        # TODO: <kpbaks 2023-09-09 22:32:23> Suggest some of the other local branches. If there are none, suggest creating one.
        __git.fish::echo (printf "You are on the %s%s%s branch. You should be on a %sfeature%s branch!" \
			$yellow $current_branch $reset $green $reset)
    end
end

# function __git.fish::reminders::select-merge-strategy --on-event in_git_repo_root_directory
#     # '--rebase'
#     # '--no-rebase'
#     # '--ff-only'

# end

# TODO: <kpbaks 2023-08-30 17:53:40> implement
# https://github.com/cocogitto/cocogitto
# https://gitmoji.dev/
# https://github.com/orhun/git-cliff

# TODO: use https://github.com/compilerla/conventional-pre-commit

function __git.fish::reminders::use-branches --on-event in_git_repo_root_directory
    set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED; or set --universal GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED 0
    test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return 0
    # functions/gbo.fish
    gbo --unchecked # We already know that we are in a git repo
end
