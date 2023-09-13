# --------------------------------------------------------------------------------------------------
# ideas:
# - [] include changes to submodules
# --------------------------------------------------------------------------------------------------
function should_i_commit --description 'Check if you should commit, based on the number of lines changed in the repo since your last commit'
    set --local red (set_color red)
    set --local green (set_color green)
    set --local reset (set_color normal)
    set --local options (fish_opt --short=h --long=help)
    set --local min_args 1
    set --local max_args 1
    if not argparse --min-args $min_args --max-args $max_args $options -- $argv
        printf "%sUsage: %s <threshold>%s\n" $red (status current-filename) $reset >&2
        return 1
    end

    set --local threshold $argv[1]
    # precondition: inside a git repo
    # nothing to do, if there are no changes
    if not command git rev-parse --inside-work-tree >/dev/null 2>&1
        printf "%sNot inside a git repo\n%s" $red $reset >&2
        return 1
    end

    # example of output generated by `git diff --shortstat`:
    # "32 files changed, 835 insertions(+), 334 deletions(-)"
    command git diff --shortstat \
        | string match --regex --all --groups-only '(\d+)' \
        | read --line --local files_changed insertions deletions

    # If no changes, `git diff --shortstat` returns nothing
    # and `string match` returns nothing
    # so we need to check if the variable is empty
    if test -z $files_changed
        set files_changed 0
    end
    if test -z $insertions
        set insertions 0
    end
    if test -z $deletions
        set deletions 0
    end

    # nothing to do, if there are no changes
    test $files_changed -gt 0; or return

    set --local number_of_lines_changed_in_repo_since_last_commit (math "$insertions + $deletions")

    if test $number_of_lines_changed_in_repo_since_last_commit -le $threshold
        echo "$number_of_lines_changed_in_repo_since_last_commit <= $threshold"
        return
    end

    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local template "%s%s%s
in this repo %s%s%s at %s%s%s
%s%s%s lines have changed (insertions: %s%s%s, deletions: %s%s%s)
since your last commit (%s%s%s ago). You SHOULD commit,
as this is above your set threshold of %s%s%s!
%s\n"

    set --local owner_and_repo (git config --local --get remote.origin.url | string match --regex --groups-only '([^/]+/[^/]+)\.git$') # extract the repo owner / repo name from the remote url e.g. kpbs5/git.fish
    set --local angry_emojis_sample_set 🤬 😠 😡 💀
    set --local angry_emojis_count (math "floor($number_of_lines_changed_in_repo_since_last_commit / $threshold)")

    set --local angry_emojis
    for i in (seq $angry_emojis_count)
        set --local random_index (random 1 (count $angry_emojis_sample_set))
        set --local random_emoji $angry_emojis_sample_set[$random_index]
        set --append angry_emojis $random_emoji
    end

    set --local angry_emojis (string join '' $angry_emojis)

    # determine the time since last commit
    set --local last_commit_time (git log -1 --format=%ct)
    set --local now (date +%s)
    set --local seconds_since_last_commit (math "$now - $last_commit_time")
    set --local milliseconds_since_last_commit (math "$seconds_since_last_commit * 1000")

    # format the time since last commit in a human readable way
    set --local time_since_last_commit (peopletime $milliseconds_since_last_commit | string trim)

    printf $template \
        $git_color "GIT COMMIT ALERT!" $reset \
        $git_color $owner_and_repo $reset \
        $git_color $PWD $reset \
        $git_color $number_of_lines_changed_in_repo_since_last_commit $reset \
        $green $insertions $reset \
        $red $deletions $reset \
        $git_color $time_since_last_commit $reset \
        $git_color $threshold $reset \
        $angry_emojis
end
