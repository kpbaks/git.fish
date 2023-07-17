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

set -g __git_fish_last_git_repo_root_directory ""

function _in_git_repo_root_directory --on-variable PWD
    test -d .git; or return
    if test $PWD = $__git_fish_last_git_repo_root_directory
        return
    end
    set -g __git_fish_last_git_repo_root_directory $PWD
    emit in_git_repo_root_directory $PWD
    if not set --query __fish_user_data_dir
        set -g __fish_user_data_dir ~/.local/share/fish
    end
    set -l plugin_dir $__fish_user_data_dir/plugins
    test -d $plugin_dir; or mkdir -p $plugin_dir
end

function _remind_me_to_create_remote --on-event in_git_repo_root_directory
    set -l remote_branch (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)
    if test $status -ne 0
		_git_fish_echo "You have not set up a remote branch for this branch yet. You can do so by running:"
        set -l connect_to_remote_cmd "git push -u <remote> <branch>"
		echo $connect_to_remote_cmd | fish_indent --ansi
        return
    end
end
