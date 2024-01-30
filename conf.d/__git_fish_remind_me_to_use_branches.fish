status is-interactive; or return 0
set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED; or set --universal GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED 0
test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return 0

# TODO: use the same format as the `duf` command for the table

# TODO: <kpbaks 2023-08-30 17:53:40> implement
# https://github.com/cocogitto/cocogitto
# https://gitmoji.dev/
# https://github.com/orhun/git-cliff
# https://github.com/compilerla/conventional-pre-commit


function __git.fish::reminders::use-branches --on-event in_git_repo_root_directory
    # TODO: for the time column, use a heat intensity color scale, that is more intense for more recent commits
    # similar to how GitHub does it
    # TODO: for the author column, use a unique color for each author
    # TODO: <kpbaks 2023-09-09 22:32:54> refactor and finish creating the `tabulate function`
    # A check is performed within the function such that the feature can be disabled/enabled
    # without having to restart the shell
    test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return 0
    # TODO: <kpbaks 2023-06-10 15:02:18> maybe highlight last commit message and last committer
    # in a grey color to differentiate them from the branch name, and deemphasize them
    set -l branches (command git branch --list --no-color)
    if test (count $branches) -eq 0
        # Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        __git.fish::echo "No branches has been created yet"
        return 0
    end
    set -l current_branch (git rev-parse --abbrev-ref HEAD)

    # Use the bright colors for the branch you are on
    set -l reset (set_color normal)
    set -l yellow (set_color yellow)
    set -l bryellow (set_color bryellow)
    set -l green (set_color green)
    set -l brgreen (set_color brgreen)
    set -l blue (set_color blue)
    set -l brblue (set_color brblue)
    set -l red (set_color red)
    set -l brred (set_color brred)

    set -l field_delimiter '#'
    # set -l bar "┃"
    set -l bar "│"
    # use thinner underline
    set -l underline "─"
    set -l upper_left_corner "┌"
    set -l upper_right_corner "┐"
    set -l lower_left_corner "└"
    set -l lower_right_corner "┘"
    set -l downwards_tee "┬"
    set -l upwards_tee "┴"

    set -l output_separator $bar

    # Read data for each column into a separate array
    set -l branches
    set -l contents
    set -l authors
    set -l committerdates
    git branch --format="%(HEAD) %(refname:short) $field_delimiter %(contents:subject) $field_delimiter %(committerdate:relative) $field_delimiter %(authorname)" --sort=-committerdate \
        | while read --delimiter $field_delimiter branch content committerdate author
        set --append branches (string trim -- $branch)
        set --append contents (string trim -- $content)
        set --append committerdates (string trim -- $committerdate)
        set --append authors (string trim -- $author)
    end


    set -l longest_branch ""
    set -l length_of_longest_branch 0
    for branch in $branches
        if test (string length $branch) -gt (string length $longest_branch)
            set longest_branch $branch
            set length_of_longest_branch (string length $branch)
        end
    end
    set -l longest_content ""
    set -l length_of_longest_content 0
    for content in $contents
        if test (string length $content) -gt (string length $longest_content)
            set longest_content $content
            set length_of_longest_content (string length $content)
        end
    end
    set -l longest_committerdate ""
    set -l length_of_longest_committerdate 0
    for committerdate in $committerdates
        if test (string length $committerdate) -gt (string length $longest_committerdate)
            set longest_committerdate $committerdate
            set length_of_longest_committerdate (string length $committerdate)
        end
    end
    set -l longest_author ""
    set -l length_of_longest_author 0
    for author in $authors
        if test (string length $author) -gt (string length $longest_author)
            set longest_author $author
            set length_of_longest_author (string length $author)
        end
    end

    set -l show_branch 1
    set -l show_content 1
    set -l show_committerdate 1
    set -l show_author 1

    # TODO: maybe ellipsize the content if it is too long i.e. it does not
    if test (math "($length_of_longest_branch + 2) + ($length_of_longest_content + 3) + ($length_of_longest_committerdate + 3) + ($length_of_longest_author + 2)") -gt $COLUMNS
        # All 4 columns shown together with a separator between them, will overflow the terminal.
        # Test if we can show (branch, content, author) columns together with a separator between them, without overflowing the terminal.
        set show_committerdate 0
        if test (math "($length_of_longest_branch + 2) + ($length_of_longest_content + 3) + ($length_of_longest_author + 2)") -gt $COLUMNS
            # Test if we can show (branch, content) columns together with a separator between them, without overflowing the terminal.
            set show_author 0
            if test (math "($length_of_longest_branch + 2) + ($length_of_longest_content + 3)") -gt $COLUMNS
                # Test if we can show (branch) column without overflowing the terminal.
                set show_content 0
                if test (math "($length_of_longest_branch + 2)") -gt $COLUMNS
                    # We can't show anything without overflowing the terminal.
                    set show_branch 0
                end
            end
        end
    end

    if test $show_branch -eq 0 -a $show_content -eq 0 -a $show_committerdate -eq 0 -a $show_author -eq 0
        # We can't show anything without overflowing the terminal.
        return 0
    end

    __git.fish::echo "The following $(set_color --italics)local$(set_color normal) branches exist ($(set_color --italics)the $(set_color yellow)*$(set_color normal)$(set_color --italics) indicates the branch you are on$(set_color normal)):"

    # Only what to print the top border if there are multiple branches
    if test (count $branches) -ne 1
        printf "%s" $upper_left_corner
        if test $show_branch -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $downwards_tee
        end
        if test $show_content -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $downwards_tee
        end
        if test $show_author -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_author + 2") $underline)
            printf "%s" $downwards_tee
        end
        if test $show_committerdate -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        end
        printf "%s" $upper_right_corner
        printf "\n"
    end


    # Print the columns of the table
    for i in (seq (count $authors))
        set -l branch $branches[$i]
        set -l content $contents[$i]
        set -l committerdate $committerdates[$i]
        set -l author $authors[$i]

        set -l branch_padding (string repeat --count (math "$length_of_longest_branch - $(string length $branch)") " ")
        set -l content_padding (string repeat --count (math "$length_of_longest_content - $(string length $content)") " ")
        set -l committerdate_padding (string repeat --count (math "$length_of_longest_committerdate - $(string length $committerdate)") " ")
        set -l author_padding (string repeat --count (math "$length_of_longest_author - $(string length $author)") " ")

        set -l branch_color $reset
        set -l committerdate_color $blue
        set -l author_color $red

        if string match --regex --quiet "^\* $current_branch\$" $branch
            set branch_color (set_color bryellow --bold)
            # set committerdate_color (set_color brblue --bold)
            # set author_color (set_color brred --bold)
        end

        set -l branch "$branch$branch_padding"
        set -l content "$content$content_padding"
        set -l committerdate "$committerdate$committerdate_padding"
        set -l author "$author$author_padding"

        printf "%s" $output_separator
        if test $show_branch -eq 1
            printf " %s%s%s %s" \
                $branch_color $branch $reset \
                $output_separator
        end
        if test $show_content -eq 1
            printf " %s %s" (__git.fish::conventional-commits::pretty-print $content) $output_separator
        end
        if test $show_author -eq 1
            printf " %s%s%s %s" \
                $author_color $author $reset \
                $output_separator
        end
        if test $show_committerdate -eq 1
            printf " %s%s%s %s" \
                $committerdate_color $committerdate $reset \
                $output_separator
        end

        printf "\n"
    end

    # Only want to print the bottom line if there is more than one branch
    if test (count $branches) -ne 1
        printf "%s" $lower_left_corner
        if test $show_branch -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $upwards_tee
        end
        if test $show_content -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $upwards_tee
        end
        if test $show_author -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_author + 2") $underline)
            printf "%s" $upwards_tee
        end
        if test $show_committerdate -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        end
        printf "%s" $lower_right_corner
        printf "\n"
    end
end
