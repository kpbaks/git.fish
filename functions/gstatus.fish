function gstatus --description 'opinionated `git status`'

    set -l options h/help H/hint
    if not argparse $options -- $argv
        printf "\n" >&2
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l bold (set_color --bold)
    set -l bold_yellow (set_color --bold yellow)
    set -l bold_red (set_color --bold red)
    set -l bold_green (set_color --bold green)

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow
        # Overall description of the command
        printf "%sOpinionated $(printf (echo "git status" | fish_indent --ansi))%s\n" $bold $reset
        printf "\n"
        # Usage
        printf "%sUSAGE:%s %s%s%s\n" $section_title_color $reset (set_color $fish_color_command) (status current-command) $reset
        printf "\n"
        # Description
        printf "%sOPTIONS:%s\n" $section_title_color $reset
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset
        printf "\n"

        __git.fish::help_footer
        return 0
    end >&2

    set -l indent (string repeat --count 4 " ")
    set -l bar "│"
    set -l hr (string repeat --count (math "min(100, $COLUMNS)") "─")

    set -l current_branch (command git rev-parse --abbrev-ref HEAD)

    begin
        printf "%sbranches%s:\n" $blue $reset
        # TODO: indent
        command git branch
    end
    begin
        printf "\n"
        # TODO: are we up to date with the remote?
        # TODO: is there a plummer command for this?
        set -l remote_branches (command git branch --remotes | string trim)
        # Check if origin/$current_branch exists
        if not contains -- origin/$current_branch $remote_branches
            printf "current branch: %s%s%s has no remote counterpart\n" $green $current_branch $reset
            printf "%s(use %s%s to create a branch on the remote)\n" (printf "git push --set-upstream origin %s" $indent $current_branch | fish_indent --ansi) $reset
        else
            command git rev-list --left-right --count $current_branch...origin/$current_branch | read local remote
            if test $local -eq 0 -a $remote -eq 0
                printf "%scurrent branch: %s%s%s is up to date with its remote counterpart: %s%s%s\n" $indent $green $current_branch $reset $red origin/$current_branch $reset
            else
                if test $local -gt 0
                    printf "local %d\n" $local
                end
                if test $remote -gt 0
                    printf "remote %d\n" $remote
                end
            end
        end
    end
    echo $hr
    begin
        printf "%schanges to be committed%s:\n" $bold_green $reset
        set -l changes_to_be_committed (command git diff --color=always --staged --stat HEAD | string trim --chars=" ")
        for change in $changes_to_be_committed[..-2]
            echo $change | read --delimiter "|" file histogram_line
            set -l dirname (path dirname $file)
            if test $dirname = "."
                printf "%s%s%s%s %s %s\n" $indent $bold_green (path basename $file) $reset $bar $histogram_line
            else
                printf "%s%s%s%s/%s%s%s %s %s\n" $indent $blue (path dirname $file) $reset $bold_green (path basename $file) $reset $bar $histogram_line
            end
        end
        if test (count $changes_to_be_committed) -gt 0
            printf "\n"
        end
        echo $changes_to_be_committed[-1] \
            | string match --regex --all --groups-only '(\d+)' \
            | read --line --local files_changed insertions deletions
        if test -z $files_changed
            set files_changed 0
        end
        if test -z $insertions
            set insertions 0
        end
        if test -z $deletions
            set deletions 0
        end
        set -l number_of_lines_changed_in_repo_since_last_commit (math "$insertions + $deletions")

        printf "%s" $indent
        printf "%s%d%s file%s changed" $blue $files_changed $reset (test $files_changed -eq 1; and echo ""; or echo "s")
        if test $insertions -gt 0
            printf ", %s%d%s insertion%s(%s+%s)" $green $insertions $reset (test $insertions -eq 1; and echo ""; or echo "s") $green $reset
        end
        if test $deletions -gt 0
            printf ", %s%d%s deletion%s(%s-%s)" $red $deletions $reset (test $deletions -eq 1; and echo ""; or echo "s") $red $reset
        end
        switch $number_of_lines_changed_in_repo_since_last_commit
            case 0
            case 1
                printf ", in total %s%d%s line has changed" $yellow $number_of_lines_changed_in_repo_since_last_commit $reset
            case '*'
                printf ", in total %s%d%s lines have changed" $yellow $number_of_lines_changed_in_repo_since_last_commit $reset
        end
        printf "\n"
    end

    echo $hr
    begin
        # TODO: `git status` shows if a file is modified or deleted, how can we do that?
        #  maybe use `git ls-files -t`
        printf "%schanges not staged%s for commit:\n" $bold_yellow $reset
        if set --query _flag_hint
            printf "  (use %s%s to update what will be committed)\n" (printf (echo "git add ..." | fish_indent --ansi)) $reset
            printf "  (use %s%s to discard changes in working directory)\n" (printf (echo "git restore ..." | fish_indent --ansi)) $reset
            printf "  (use the abbreviation %sgam%s to add ALL %smodified%s files)\n" (set_color $fish_color_command) $reset $yellow $reset
        end

        # TODO: why is histrogram not as spiky as when stdout is a tty?
        set -l diffs (command git diff --stat --color=always | string trim --chars=" ")
        for diff in $diffs[..-2]
            echo $diff | read --delimiter "|" file histogram_line
            set -l dirname (path dirname $file)
            if test $dirname = "."
                printf "%s%s%s%s %s %s\n" $indent $bold_yellow (path basename $file) $reset $bar $histogram_line
            else
                printf "%s%s%s%s/%s%s%s %s %s\n" $indent $blue (path dirname $file) $reset $bold_yellow (path basename $file) $reset $bar $histogram_line
            end
        end
        if test (count $diffs) -gt 0
            printf "\n"
        end

        echo $diffs[-1] \
            | string match --regex --all --groups-only '(\d+)' \
            | read --line --local files_changed insertions deletions
        if test -z $files_changed
            set files_changed 0
        end
        if test -z $insertions
            set insertions 0
        end
        if test -z $deletions
            set deletions 0
        end
        set -l number_of_lines_changed_in_repo_since_last_commit (math "$insertions + $deletions")

        printf "%s" $indent
        printf "%s%d%s file%s changed" $blue $files_changed $reset (test $files_changed -eq 1; and echo ""; or echo "s")
        if test $insertions -gt 0
            printf ", %s%d%s insertion%s(%s+%s)" $green $insertions $reset (test $insertions -eq 1; and echo ""; or echo "s") $green $reset
        end
        if test $deletions -gt 0
            printf ", %s%d%s deletion%s(%s-%s)" $red $deletions $reset (test $deletions -eq 1; and echo ""; or echo "s") $red $reset
        end
        switch $number_of_lines_changed_in_repo_since_last_commit
            case 0
            case 1
                printf ", in total %s%d%s line has changed" $yellow $number_of_lines_changed_in_repo_since_last_commit $reset
            case '*'
                printf ", in total %s%d%s lines have changed" $yellow $number_of_lines_changed_in_repo_since_last_commit $reset
        end
        printf "\n"
    end

    echo $hr
    begin
        printf "%suntracked%s files:\n" $bold_red $reset
        if set --query _flag_hint
            printf "  (use %s%s to include in what will be committed)\n" (printf (echo "git add ..." | fish_indent --ansi)) $reset
            printf "  (use the abbreviation %sgau%s to add ALL %suntracked%s files)\n" (set_color $fish_color_command) $reset $red $reset
        end

        for f in (command git ls-files --others --exclude-standard)
            set -l dirname (path dirname $f)
            if test $dirname = "."
                printf "%s%s%s%s\n" $indent $bold_red $f $reset
            else
                printf "%s%s%s%s/%s%s%s\n" $indent $blue (path dirname $f) $reset $bold_red (path basename $f) $reset
            end
        end
    end
end
