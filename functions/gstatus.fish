function gstatus --description 'opinionated `git status`'

    set -l options h/help H/hint b/no-branches s/no-staged u/no-unstaged U/no-untracked
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
        printf "\t%s-h%s, %s--help%s            Show this help message and exit\n" $green $reset $green $reset
        printf "\t%s-H%s, %s--hint%s            Show hints for how to interact with the {,un}/staged, untracked files\n" $green $reset $green $reset
        printf "\t%s-b%s, %s--no-branches%s     Do not show branches\n" $green $reset $green $reset
        printf "\t%s-s%s, %s--no-staged%s       Do not show staged files\n" $green $reset $green $reset
        printf "\t%s-u%s, %s--no-unstaged%s     Do not show unstaged files\n" $green $reset $green $reset
        printf "\t%s-U%s, %s--no-untracked%s    Do not show untracked files\n" $green $reset $green $reset

        printf "\n"

        __git.fish::help_footer
        return 0
    end >&2

    set -l indent (string repeat --count 4 " ")
    set -l bar "│"
    set -l hr (string repeat --count (math "min(100, $COLUMNS)") "─")

    set -l current_branch (command git rev-parse --abbrev-ref HEAD)

    if not set --query _flag_no_branches
        printf "%slocal branches%s:\n" $blue $reset
        command git branch | while read branch
            if test $branch = "* $current_branch"
                printf "%s%s%s%s\n" $indent $green $branch $reset
            else
                printf "%s%s\n" $indent $branch
            end
        end

        printf "\n"
        set -l remote_branches (command git branch --remotes | string trim)
        # Check if origin/$current_branch exists
        if not contains -- origin/$current_branch $remote_branches
            printf "current branch: %s%s%s has no remote counterpart\n" $green $current_branch $reset
            printf "%s(use %s%s to create a branch on the remote)\n" (printf "git push --set-upstream origin %s" $indent $current_branch | fish_indent --ansi) $reset
        else
            command git rev-list --left-right --count $current_branch...origin/$current_branch | read local remote
            if test $local -eq 0 -a $remote -eq 0
                printf "%scurrent branch: %s%s%s is up to date with its remote counterpart: %s%s%s\n" $indent $green $current_branch $reset $red origin/$current_branch $reset
            else if test $local -gt 0 -a $remote -gt 0
                printf "%scurrent branch: %s%s%s is %s%d%s commit%s ahead and %s%d%s commit%s behind its remote counterpart: %s%s%s\n" $indent \
                    $green $current_branch $reset \
                    $green $local $reset (test $local -eq 1; and echo ""; or echo "s") \
                    $red $remote $reset (test $remote -eq 1; and echo ""; or echo "s") \
                    $red origin/$current_branch $reset
            else if test $local -gt 0
                printf "%scurrent branch: %s%s%s is %s%d%s commit%s ahead of its remote counterpart: %s%s%s\n" $indent \
                    $green $current_branch $reset \
                    $green $local $reset (test $local -eq 1; and echo ""; or echo "s") \
                    $red origin/$current_branch $reset
            else
                printf "%scurrent branch: %s%s%s is %s%d%s commit%s behind its remote counterpart: %s%s%s\n" $indent \
                    $green $current_branch $reset \
                    $red $remote $reset (test $remote -eq 1; and echo ""; or echo "s") \
                    $red origin/$current_branch $reset
            end

            set -l commit_threshold 3
            if test $local -ge $commit_threshold
                printf "%syou may want to push your changes to the remote\n" $indent
            end
            if test $remote -ge $commit_threshold
                printf "%syou may want to pull changes from the remote\n" $indent
            end
        end
        echo $hr
    end

    if not set --query _flag_no_staged
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

        echo $hr
    end

    if not set --query _flag_no_unstaged
        # TODO: `git status` shows if a file is modified or deleted, how can we do that?
        #  maybe use `git ls-files -t`
        printf "%schanges not staged%s for commit:\n" $bold_yellow $reset
        if set --query _flag_hint
            printf "%s(use %s%s to update what will be committed)\n" $indent (printf (echo "git add ..." | fish_indent --ansi)) $reset
            printf "%s(use %s%s to discard changes in working directory)\n" $indent (printf (echo "git restore ..." | fish_indent --ansi)) $reset
            printf "%s(use the abbreviation %sgam%s to add ALL %smodified%s files)\n" $indent (set_color $fish_color_command) $reset $yellow $reset
        end

        # Q: why is histrogram not as spiky as when stdout is a tty?
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

        echo $hr
    end

    if not set --query _flag_no_untracked
        printf "%suntracked%s files:\n" $bold_red $reset
        if set --query _flag_hint
            printf "%s(use %s%s to include in what will be committed)\n" $indent (printf (echo "git add ..." | fish_indent --ansi)) $reset
            printf "%s(use the abbreviation %sgau%s to add ALL %suntracked%s files)\n" $indent (set_color $fish_color_command) $reset $red $reset
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
