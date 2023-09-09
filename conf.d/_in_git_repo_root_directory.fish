status is-interactive; or return

# The purpose of this function is to emit an event whenever
# the current working directory changes to a directory that
# is the root of a git repository.
# Other functions in this plugin can then subscribe to this
# event by specifying `function <name> --on-event in_git_repo_root_directory`
# in their definition.
# This way, the responsibility of checking whether the current
# working directory is the root of a git repository is delegated
# to this function only.

set --global __git_fish_last_git_repo_root_directory ""

function _in_git_repo_root_directory --on-variable PWD
    test -d .git; or return
    test $PWD = $__git_fish_last_git_repo_root_directory; or return
    set --global __git_fish_last_git_repo_root_directory $PWD

    emit in_git_repo_root_directory $PWD
    # TODO: <kpbaks 2023-09-09 17:21:13> what is the purpose of the lines below?
    # set --query __fish_user_data_dir; or set --universal __fish_user_data_dir ~/.local/share/fish
    # set --local plugin_dir $__fish_user_data_dir/plugins
    # test -d $plugin_dir; or mkdir -p $plugin_dir
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
    set --query GIT_FISH_AUTO_FETCH; or set --universal GIT_FISH_AUTO_FETCH 1
    test GIT_FISH_AUTO_FETCH = 1; or return
    command git fetch --quiet
end
