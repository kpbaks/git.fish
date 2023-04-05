function gfold
    if not command --query find
        set_color red --bold
        echo "find not found"
        set_color normal
        return 1
    end

    set -l options (fish_opt --short=l --long=no-log --long-only)
    set --append options (fish_opt --short=t --long=no-stash --long-only)
    set --append options (fish_opt --short=s --long=no-status --long-only)
    set --append options (fish_opt --short=b --long=no-branch --long-only)
    set --append options (fish_opt --short=h --long=help)

    if not argparse $options -- $argv
        return 1
    end

    set -l git_color (set_color "#f44d27") # taken from git's logo

    if set --query _flag_help
        set_color green --bold
        echo "gfold - find git repos in the subtree of the current directory"
        set_color normal
        echo "usage: gfold [options] [path]"
        echo "options:"
        echo "  -l, --no-log     do not show the last commit"
        echo "  -t, --no-stash   do not show the stash"
        echo "  -s, --no-status  do not show the status"
        echo "  -b, --no-branch  do not show the branch"
        echo "  -h, --help       show this help"
        return 0
    end

    set -l normal (set_color normal)
    set -l bold (set_color --bold)
    set -l dir_fmt (set_color green)
    set -l repo_fmt (set_color yellow)

    set -l maxdepth 3
    set -l border_count (math "min($COLUMNS, 100)")

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
        set_color red --bold
        echo "not a directory: $root_dir"
        set_color normal
        return 1
    end


    set -l found_count 0
    for git_dir in (find $root_dir -maxdepth $maxdepth -type d -name ".git")
        set found_count (math "$found_count + 1")
        set repo_dir (path dirname $git_dir)
        set -l git git -C $repo_dir
        set -l remote_url ($git config --local --get remote.origin.url)

        printf "%sdir%s:  %s%s%s\n" \
            $bold $normal \
            $dir_fmt (string replace "$HOME" "~" $repo_dir) $normal
        printf "%srepo%s: %s%s%s\n" \
            $bold $normal \
            $repo_fmt $remote_url $normal
        if not set --query _flag_no_branch
            set -l active_branch ($git rev-parse --abbrev-ref HEAD)
            set -l inactive_branches ($git branch | string match --regex --invert "\* (\S+)" | string trim --chars=" " --)

            set -l active_branch_fmt $git_color
            if test -z $inactive_branches
                printf "%sbranch%s: { %s%s%s }\n" \
                    $bold $normal \
                    $active_branch_fmt $active_branch $normal
            else
                set -l grey "#888888"
                set -l inactive_branch_fmt (set_color $grey)
                printf "%sbranches%s: { %s%s%s" \
                    $bold $normal \
                    $active_branch_fmt $active_branch $normal
                for inactive_branch in $inactive_branches
                    printf ", %s%s%s" $inactive_branch_fmt $inactive_branch $normal
                end
                printf " }\n"
            end
        end

        if not set --query _flag_no_status
            printf "%sstatus%s:\n" $bold $normal
            $git status --short
        end

        if not set --query _flag_no_stash
            set -l stashes ($git stash list)
            if test -n $stashes
                printf "%s%s%s:\n" \
                    (set_color --bold) \
                    (test (count $stashes) -eq 1; and echo "stash"; or echo "stashes") \
                    $normal
                printf " - %s\n" ($git stash list)
            end

        end

        if not set --query _flag_no_log
            printf "%slog%s:\n" $bold $normal
            $git log --oneline -1
        end

        # add a border
        string repeat --count $border_count -
    end

    if test $found_count -eq 0
        set_color red --bold
        echo "no git repos found"
        set_color normal
    else
        set -l green (set_color green --bold)
        printf "found %s%d%s git %s in the subtree of %s%s%s\n" \
            $green $found_count $normal \
            (test $found_count -eq 1; and echo "repo"; or echo "repos") \
            $green $PWD $normal
    end
end
