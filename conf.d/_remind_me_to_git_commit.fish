status is-interactive; or return
# when inside a git repo, check if the number of unstaged changes (i.e. lines)
# is greater than `$REMIND_ME_TO_COMMIT_THRESHOLD`
# if so, print a reminder to commit

set --query REMIND_ME_TO_COMMIT_THRESHOLD; or set REMIND_ME_TO_COMMIT_THRESHOLD 50

function _remind_me_to_commit --on-variable PWD
    # FIX: why does it actually trigger when fish is started?
    # do not want to run it every time a new fish shell is opened
    if test $PWD = $__fish_config_dir
        return
    end

    if test -d .git
        # defined in $__fish_config_dir/functions/should_i_commit.fish
        # part of git.fish
        should_i_commit $REMIND_ME_TO_COMMIT_THRESHOLD
    end
end
