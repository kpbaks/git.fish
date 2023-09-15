status is-interactive; or return

function __git.fish::is_conventional_commit --argument-names commit_msg
    return 1
end

# TODO: <kpbaks 2023-08-30 17:53:40> implement
# https://github.com/cocogitto/cocogitto
# https://gitmoji.dev/
# https://github.com/orhun/git-cliff
# https://github.com/compilerla/conventional-pre-commit
function __git.fish::parse_conventional_commit --description "https://www.conventionalcommits.org/en/v1.0.0/#specification"
    set --local argc (count $argv)
    if test $argc -ne 1
        return 2
    end
    set --local commit_msg $argv[1]

    set --local conventional_commit_type ""
    set --local conventional_commit_scope ""
    set --local conventional_commit_description ""
    set --local conventional_commit_has_exclamation_mark 0

    set --local s (string split --no-empty ":" $commit_msg)
    if test (count $s) -eq 1
        # No conventional commit message
        return 1
    end

    set --local

    return 0
end

set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED; or set --universal GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED 1

function __git.fish::remind_me_to_use_branches --on-event in_git_repo_root_directory
    # TODO: <kpbaks 2023-09-09 22:32:54> refactor and finish creating the `tabulate function`
    # A check is performed within the function such that the feature can be disabled/enabled
    # without having to restart the shell
    test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return
    # TODO: <kpbaks 2023-06-10 15:02:18> maybe highlight last commit message and last committer
    # in a grey color to differentiate them from the branch name, and deemphasize them
    set --local branches (git branch --list --no-color)
    if test (count $branches) -eq 0
        # Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        __git.fish::echo "no branches has been created yet"
        return
    end
    set --local current_branch (git rev-parse --abbrev-ref HEAD)

    # Use the bright colors for the branch you are on
    set --local reset (set_color normal)
    set --local yellow (set_color yellow)
    set --local bryellow (set_color bryellow)
    set --local green (set_color green)
    set --local brgreen (set_color brgreen)
    set --local blue (set_color blue)
    set --local brblue (set_color brblue)
    set --local red (set_color red)
    set --local brred (set_color brred)



    set --local field_delimiter '#'
    # set --local bar "┃"
    set --local bar "│"
    # use thinner underline
    set --local underline "─"
    set --local upper_left_corner "┌"
    set --local upper_right_corner "┐"
    set --local lower_left_corner "└"
    set --local lower_right_corner "┘"
    set --local downwards_tee "┬"
    set --local upwards_tee "┴"

    set --local output_separator $bar

    # Read data for each column into a separate array
    set --local branches
    set --local contents
    set --local authors
    set --local committerdates
    git branch --format="%(HEAD) %(refname:short) $field_delimiter %(contents:subject) $field_delimiter %(committerdate:relative) $field_delimiter %(authorname)" --sort=-committerdate \
        | while read --delimiter $field_delimiter branch content committerdate author
        set --append branches (string trim -- $branch)
        set --append contents (string trim -- $content)
        set --append committerdates (string trim -- $committerdate)
        set --append authors (string trim -- $author)
    end


    set --local longest_branch ""
    set --local length_of_longest_branch 0
    for branch in $branches
        if test (string length $branch) -gt (string length $longest_branch)
            set longest_branch $branch
            set length_of_longest_branch (string length $branch)
        end
    end
    set --local longest_content ""
    set --local length_of_longest_content 0
    for content in $contents
        if test (string length $content) -gt (string length $longest_content)
            set longest_content $content
            set length_of_longest_content (string length $content)
        end
    end
    set --local longest_committerdate ""
    set --local length_of_longest_committerdate 0
    for committerdate in $committerdates
        if test (string length $committerdate) -gt (string length $longest_committerdate)
            set longest_committerdate $committerdate
            set length_of_longest_committerdate (string length $committerdate)
        end
    end
    set --local longest_author ""
    set --local length_of_longest_author 0
    for author in $authors
        if test (string length $author) -gt (string length $longest_author)
            set longest_author $author
            set length_of_longest_author (string length $author)
        end
    end

    set --local show_branch 1
    set --local show_content 1
    set --local show_committerdate 1
    set --local show_author 1

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
    __git.fish::echo "The following $(set_color --italics)local$(set_color normal) branches exist ($(set_color --italics)the $(set_color yellow)*$(set_color normal)$(set_color --italics) indicates the branch you are on$(set_color normal)):"
    # __git.fish::echo "format: $(set_color yellow)BRANCH$(set_color normal) | $(set_color green)LAST COMMIT MESSAGE$(set_color normal) | $(set_color blue)LAST COMMIT DATE$(set_color normal) | $(set_color red)LAST COMMITTER$(set_color normal)"

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
        set --local branch $branches[$i]
        set --local content $contents[$i]
        set --local committerdate $committerdates[$i]
        set --local author $authors[$i]

        set --local branch_length (string length $branch)
        set --local content_length (string length $content)
        set --local committerdate_length (string length $committerdate)
        set --local author_length (string length $author)
        set --local branch_padding (string repeat --count (math "$length_of_longest_branch - $branch_length") " ")
        set --local content_padding (string repeat --count (math "$length_of_longest_content - $content_length") " ")
        set --local committerdate_padding (string repeat --count (math "$length_of_longest_committerdate - $committerdate_length") " ")
        set --local author_padding (string repeat --count (math "$length_of_longest_author - $author_length") " ")

        set --local branch "$branch$branch_padding"
        set --local content "$content$content_padding"
        set --local committerdate "$committerdate$committerdate_padding"
        set --local author "$author$author_padding"

        # TODO: <kpbaks 2023-06-10 15:18:27> move the definition of the colors to the top of the file
        # so colors can be easily changed.
        set --local branch_color $yellow
        set --local content_color $green
        set --local committerdate_color $blue
        set --local author_color $red

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
