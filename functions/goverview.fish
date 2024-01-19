function goverview -d "show an overview of the git repos in the subtree of the current directory"
    set -l options h/help
    set --append options (fish_opt --short=l --long=no-log --long-only)
    set --append options (fish_opt --short=n --long=no --long-only --required-val)
    set --append options (fish_opt --short=d --long=maxdepth --required-val)

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italic (set_color --italics)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l blue (set_color blue)
    # set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l git_color (set_color red)

    if set --query _flag_help
        # TODO: format in same style as the other commands
        set_color green --bold
        printf "gstat - find git repos in the subtree of the current directory\n"
        set_color normal
        printf "usage: gstat [options] [path]\n"
        printf "options:\n"
        printf "  -l, --no-log     do not show the last commit\n"
        printf "  -t, --no-stash   do not show the stash\n"
        printf "  -s, --no-status  do not show the status\n"
        printf "  -b, --no-branch  do not show the branch\n"
        printf "  -h, --help       show this help\n"

        printf "\n" >&2
        __git.fish::help_footer

        return 0
    end

    set -l find_cmd
    set -l find_cmd_opts
    if command --query fd
        set find_cmd fd
        set find_cmd_opts --hidden --type d --max-depth $maxdepth --no-ignore
    else if command --query find
        set find_cmd find
        set find_cmd_opts -L
    else
        printf "%serror:%s Neither `find` nor `fd` are available\n" $red $reset
        return 1
    end

    set -l dir_fmt $green
    set -l repo_fmt $yellow

    set -l maxdepth 3
    set -l border_count (math "min($COLUMNS, 100)")

    set -l sections_to_ignore
    if set --query _flag_no
        set sections_to_ignore (string replace --all "," " " $_flag_no | string split " ")
    end

    # echo $sections_to_ignore
    #    echo "count: $(count $sections_to_ignore)"
    set -l show_dir_section 1
    set -l show_repo_section 1
    set -l show_log_section 1
    set -l show_status_section 1
    set -l show_stash_section 1
    set -l show_branch_section 1
    set -l show_submodules_section 1
    set -l show_summary_section 1

    # TODO: <kpbaks 2023-09-08 21:03:15> notify as an error if the user specifies an unknown section

    contains -- dir $sections_to_ignore; and set show_dir_section 0
    contains -- repo $sections_to_ignore; and set show_repo_section 0
    contains -- log $sections_to_ignore; and set show_log_section 0
    contains -- status $sections_to_ignore; and set show_status_section 0
    contains -- stash $sections_to_ignore; and set show_stash_section 0
    contains -- branch $sections_to_ignore; and set show_branch_section 0
    contains -- submodules $sections_to_ignore; and set show_submodules_section 0
    contains -- summary $sections_to_ignore; and set show_summary_section 0

    # TODO: submodules
    # mimic display-modes of https://github.com/nickgerace/gfold
    # - json
    # - classic
    # - standard (It could be called --gfold)

    set -l root_dir $PWD
    if test (count $argv) -gt 0
        set root_dir $argv[1]
    end

    if not test -d $root_dir
        printf "%serror%s %s%s%s is not a directory\n" \
            $red $reset \
            $italic $root_dir $reset
        return 1
    end

    set -l hr (string repeat --count $border_count ━)
    set -l found_count 0
    set -l git_dirs (find $root_dir -maxdepth $maxdepth -type d -name ".git")
    for idx in (seq (count $git_dirs))
        set -l git_dir $git_dirs[$idx]
        set found_count (math "$found_count + 1")
        set -l repo_dir (path dirname $git_dir)
        set -l git git -C $repo_dir
        set -l remote_url ($git config --local --get remote.origin.url)

        if test $show_dir_section -eq 1
            printf "%sdir%s:  %s%s%s\n" \
                $bold $reset \
                $dir_fmt (string replace "$HOME" "~" $repo_dir) $reset
        end
        if test $show_repo_section -eq 1
            printf "%srepo%s: %s%s%s\n" \
                $bold $reset \
                $repo_fmt $remote_url $reset
        end
        if not set --query _flag_no_branch
            set -l active_branch ($git rev-parse --abbrev-ref HEAD)
            set -l inactive_branches ($git branch | string match --regex --invert "\* (\S+)" | string trim --chars=" " --)

            set -l active_branch_fmt $git_color
            if test (count $inactive_branches) -eq 0
                printf "%sbranch%s: { %s%s%s }\n" \
                    $bold $reset \
                    $active_branch_fmt $active_branch $reset
            else
                set -l grey "#888888"
                set -l inactive_branch_fmt (set_color $grey)
                printf "%sbranches%s: { %s%s%s" \
                    $bold $reset \
                    $active_branch_fmt $active_branch $reset
                for inactive_branch in $inactive_branches
                    printf ", %s%s%s" $inactive_branch_fmt $inactive_branch $reset
                end
                printf " }\n"
            end
        end

        if test $show_status_section -eq 1
            # TODO: <kpbaks 2023-09-08 21:16:27> compute additioons and deletions of each modified file
            # with `git diff --numstat`
            printf "%sstatus%s:\n" $bold $reset
            $git status --short
        end

        if test $show_stash_section -eq 1
            set -l stashes ($git stash list)
            if test (count $stashes) -gt 0
                printf "%s%s%s:\n" \
                    (set_color --bold) \
                    (test (count $stashes) -eq 1; and echo "stash"; or echo "stashes") \
                    $reset
                printf " - %s\n" $stashes
            end

        end

        if test $show_log_section -eq 1
            printf "%slog%s:\n  " $bold $reset
            $git -c color.status=always log --oneline -1
            # printf "%slog%s:\n" $bold $reset
            # printf " - %s\n" ($git -c color.status=always log --oneline -1)
        end

        # add a border
        if test $idx -lt (count $git_dirs)
            echo $hr
        end
    end

    if test $found_count -eq 0
        printf "%warn:%s No git repos found in the subtree of %s%s%s\n" \
            $yellow $green (string replace "$HOME" "~" $root_dir) $reset
    else
        if test $show_summary_section -eq 1
            echo $hr
            printf "found %s%d%s git %s in the subtree of %s%s%s\n" \
                $green $found_count $reset \
                (test $found_count -eq 1; and echo "repo"; or echo "repos") \
                $green (string replace "$HOME" "~" -- $PWD) $reset
        end
    end
end
