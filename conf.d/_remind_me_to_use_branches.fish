status is-interactive; or return

set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_DISABLED; and return

function __remind_me_to_use_branches --on-event in_git_repo_root_directory
    # A check is performed within the function such that the feature can be disabled/enabled
    # without having to restart the shell
    set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_DISABLED; and return
    # TODO: <kpbaks 2023-06-10 15:02:18> maybe highlight last commit message and last committer
    # in a grey color to differentiate them from the branch name, and deemphasize them
    set -l branches (git branch --list --no-color)
    if test (count $branches) -eq 0
        # Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        _git_fish_echo "no branches has been created yet"
        return
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


    if contains -- $current_branch main master
        if not set --query GIT_FISH_REMIND_ME_TO_BE_ON_A_FEATURE_BRANCH_DISABLED
            _git_fish_echo (printf "You are on the %s%s%s branch. You should be on a %sfeature%s branch!" \
			$yellow $current_branch $reset $green $reset)
        end
    end

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
        return
    end

    # TODO: <kpbaks 2023-06-10 15:39:48> print which columns have been omitted
    _git_fish_echo "The following $(set_color --italics)local$(set_color normal) branches exist ($(set_color --italics)the $(set_color yellow)*$(set_color normal)$(set_color --italics) indicates the branch you are on$(set_color normal)):"
    # _git_fish_echo "format: $(set_color yellow)BRANCH$(set_color normal) | $(set_color green)LAST COMMIT MESSAGE$(set_color normal) | $(set_color blue)LAST COMMIT DATE$(set_color normal) | $(set_color red)LAST COMMITTER$(set_color normal)"

    # Only what to print the top border if there are multiple branches
    if test (count $branches) -ne 1
        printf "%s" $upper_left_corner
        if test $show_branch -eq 1 -a $show_content -eq 1 -a $show_committerdate -eq 1 -a $show_author -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_author + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        else if test $show_branch -eq 1 -a $show_content -eq 1 -a $show_committerdate -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        else if test $show_branch -eq 1 -a $show_content -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $downwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
        else if test $show_branch -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
        end
        printf "%s" $upper_right_corner
        printf "\n"
    end

    for i in (seq (count $authors))
        set -l branch $branches[$i]
        set -l content $contents[$i]
        set -l committerdate $committerdates[$i]
        set -l author $authors[$i]

        set -l branch_length (string length $branch)
        set -l content_length (string length $content)
        set -l committerdate_length (string length $committerdate)
        set -l author_length (string length $author)
        set -l branch_padding (string repeat --count (math "$length_of_longest_branch - $branch_length") " ")
        set -l content_padding (string repeat --count (math "$length_of_longest_content - $content_length") " ")
        set -l committerdate_padding (string repeat --count (math "$length_of_longest_committerdate - $committerdate_length") " ")
        set -l author_padding (string repeat --count (math "$length_of_longest_author - $author_length") " ")

        set -l branch "$branch$branch_padding"
        set -l content "$content$content_padding"
        set -l committerdate "$committerdate$committerdate_padding"
        set -l author "$author$author_padding"

        # TODO: <kpbaks 2023-06-10 15:18:27> move the definition of the colors to the top of the file
        # so colors can be easily changed.
        set -l branch_color $yellow
        set -l content_color $green
        set -l committerdate_color $blue
        set -l author_color $red

        # Use the bright colors for the branch you are on
        # to make it stand out
        if test $branch = $current_branch
            set branch_color (set_color bryellow --bold)
            set content_color (set_color brgreen --bold)
            set committerdate_color (set_color brblue --bold)
            set author_color (set_color brred --bold)
        end

        printf "%s" $output_separator
        if test $show_branch -eq 1
            printf " %s%s%s %s" \
                $branch_color $branch $reset \
                $output_separator
        end
        if test $show_content -eq 1
            # TODO: <kpbaks 2023-06-10 15:31:32> attempt to parse the content, as a conventional commit message and highlight, the type of commit and the optional scope and the optional ! to denote a breaking commit
            printf " %s%s%s %s" \
                $content_color $content $reset \
                $output_separator
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


        if test $branch = $current_branch
            # print a horizontal line under the current branch

        end


        # TODO: <kpbaks 2023-06-10 14:54:59> ellipsize the content if it is too long i.e. it does not
        # fit the terminal width.
        # printf "%s %s%s%s %s %s%s%s %s %s%s%s %s %s%s%s %s\n" \
        #     $output_separator \
        #     $branch_color $branch $reset \
        #     $output_separator \
        #     $content_color $content $reset \
        #     $output_separator \
        #     $committerdate_color $committerdate $reset \
        #     $output_separator \
        #     $author_color $author $reset \
        #     $output_separator
    end

    # Only want to print the bottom line if there is more than one branch
    if test (count $branches) -ne 1
        printf "%s" $lower_left_corner
        if test $show_branch -eq 1 -a $show_content -eq 1 -a $show_committerdate -eq 1 -a $show_author -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_author + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        else if test $show_branch -eq 1 -a $show_content -eq 1 -a $show_committerdate -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_committerdate + 2") $underline)
        else if test $show_branch -eq 1 -a $show_content -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
            printf "%s" $upwards_tee
            printf "%s" (string repeat --count (math "$length_of_longest_content + 2") $underline)
        else if test $show_branch -eq 1
            printf "%s" (string repeat --count (math "$length_of_longest_branch + 2") $underline)
        end
        printf "%s" $lower_right_corner
        printf "\n"
    end
end
