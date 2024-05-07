# (g)it (b)ranch (o)verview
function gbo -d "Print a tabular overview of the current status of each git branch"
    set -l options h/help a/all u/unchecked l/legend
    # TODO: ellipsize commitmessage column if overflowing width

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l yellow (set_color yellow)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l italics (set_color --italics)
    set -l normal (set_color $fish_color_normal)
    set -l color_border (set_color $fish_color_normal)
    set -l color_header $cyan

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        set -l section_title_color $yellow
        printf "%sPrint a tabular overview of the current status of each git branch%s\n" (set_color --bold) $reset
        printf "\n"
        printf "%sUSAGE%s: %s%s%s [OPTIONS]\n" $section_title_color $reset (set_color $fish_color_command) (status function) $reset
        printf "\n"
        printf "%sOPTIONS%s:\n" $section_title_color $reset
        printf "\t%s-a%s, %s--all%s       Show all branches, including remote branches.\n" $option_color $reset $option_color $reset
        printf "\t%s-u%s, %s--unchecked%s Do not check if we are inside a git worktree.\n" $option_color $reset $option_color $reset
        printf "\t%s-h%s, %s--help%s      Show this help message and exit.\n" $option_color $reset $option_color $reset
        printf "\t%s-l%s, %s--legend%s    Show a legend at the beginning of the output.\n" $option_color $reset $option_color $reset
        printf "\n"

        __git::help_footer

        return 0
    end >&2 # Redirect the help message to stderr

    if not set --query _flag_unchecked
        if not command git rev-parse --is-inside-work-tree >/dev/null
            printf "%serror%s: not inside a git worktree\n" $red $normal
            return 1
        end
    end

    set -l branches (command git branch --list --no-color)
    if test (count $branches) -eq 0
        # Handle the case where there are no branches
        # e.g. when you have just created a repo with `git init`
        printf "%sinfo:%s no branches has been created yet\n" $blue $reset
        return 0
    end
    set -l current_branch (command git rev-parse --abbrev-ref HEAD)

    set -l field_delimiter '@@' # Just have to unique string that is not in the output of the git command
    # set -l bar "┃"
    set -l bar "│"
    # use thinner underline
    set -l underline "─"
    # set -l upper_left_corner "┌"
    # set -l upper_right_corner "┐"
    # set -l lower_left_corner "└"
    # set -l lower_right_corner "┘"
    set -l upper_left_corner "╭"
    set -l upper_right_corner "╮"
    set -l lower_left_corner "╰"
    set -l lower_right_corner "╯"
    set -l downwards_tee "┬"
    set -l upwards_tee "┴"
    # ╯ ╰ ╭ ╮ ─ │ ┬ ┴ ┼
    # ┌ ┐ └ ┘ ─ │ ┬ ┴ ┼
    # ┏ ┓ ┗ ┛ ─ │ ┬ ┴ ┼
    # ┏ ┓ ┗ ┛ ━ ┃ ┳ ┻ ╋
    # ┌ ┐ └ ┘ ━ ┃ ┳ ┻ ╋


    set -l output_separator $bar

    set -l all
    if set --query _flag_all
        set all --all
    end

    set -l now (command date +%s)

    # Read data for each column into a separate array
    set -l branches
    set -l contents
    set -l authors
    set -l committerdates
    set -l committerdates_as_unix_timestamps
    command git branch $all --format="%(HEAD) %(refname:short) $field_delimiter %(contents:subject) $field_delimiter %(committerdate:relative) $field_delimiter %(committerdate:unix) $field_delimiter %(authorname)" --sort=-committerdate \
        | while read --delimiter $field_delimiter branch content committerdate committerdate_as_unix_timestamp author
        set -a branches (string trim -- $branch)
        set -a contents (string trim -- $content)
        set -a committerdates (string trim -- $committerdate)
        set -a committerdates_as_unix_timestamps (string trim -- $committerdate_as_unix_timestamp)
        set -a authors (string trim -- $author)
    end

    set -l author_colors cyan red blue green yellow magenta brcyan brred brblue brgreen bryellow brmagenta
    set -l unique_authors

    set -l branch_header branch
    set -l commit_header commit
    set -l committerdate_header committerdate
    set -l author_header author

    set -l longest_branch $branch_header
    set -l length_of_longest_branch (string length $branch_header)
    for branch in $branches
        if test (string length $branch) -gt (string length $longest_branch)
            set longest_branch $branch
            set length_of_longest_branch (string length $branch)
        end
    end
    set -l longest_content $commit_header
    set -l length_of_longest_content (string length $commit_header)
    for content in $contents
        if test (string length $content) -gt (string length $longest_content)
            set longest_content $content
            set length_of_longest_content (string length $content)
        end
    end
    set -l longest_committerdate $committerdate_header
    set -l length_of_longest_committerdate (string length $committerdate_header)
    for committerdate in $committerdates
        if test (string length $committerdate) -gt (string length $longest_committerdate)
            set longest_committerdate $committerdate
            set length_of_longest_committerdate (string length $committerdate)
        end
    end
    set -l longest_author $author_header
    set -l length_of_longest_author (string length $author_header)
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

    if set --query _flag_legend
        printf " - the %s*%s indicates the branch you are on\n" $yellow $reset
        if set --query _flag_all
            set -l remote_git_url (command git config --local --get remote.origin.url)
            printf " - branches starting with %sorigin%s are remote branches at %s%s%s\n" $red $reset $red $remote_git_url $reset
        end
    end

    # Print the top border like in nushell:
    # "╭────name────┬─type─┬──size──┬───modified────╮"

    # Only what to print the top border if there are multiple branches
    # if test (count $branches) -gt 1
    printf "%s%s%s" $color_border $upper_left_corner $reset
    if test $show_branch -eq 1
        set -l left_line $underline
        set -l right_line (string repeat --count (math "$length_of_longest_branch - $(string length $branch_header) + 1") $underline)
        printf "%s%s%s" $color_border $left_line $reset
        printf "%s%s%s" $color_header branch $reset

        printf "%s%s%s%s" $color_border $right_line $downwards_tee $reset
    end
    if test $show_content -eq 1
        set -l left_line $underline
        set -l right_line (string repeat --count (math "$length_of_longest_content - $(string length $commit_header) + 1") $underline)
        printf "%s%s%s" $color_border $left_line $reset
        printf "%s%s%s" $color_header commit $reset
        printf "%s%s%s%s" $color_border $right_line $downwards_tee $reset

    end
    if test $show_author -eq 1
        set -l left_line $underline
        set -l right_line (string repeat --count (math "$length_of_longest_author - $(string length $author_header) + 1") $underline)
        printf "%s%s%s" $color_border $left_line $reset
        printf "%s%s%s" $color_header author $reset
        printf "%s%s%s%s" $color_border $right_line $downwards_tee $reset

    end
    if test $show_committerdate -eq 1
        set -l left_line $underline
        set -l right_line (string repeat --count (math "$length_of_longest_committerdate - $(string length $committerdate_header) + 1") $underline)
        printf "%s%s%s" $color_border $left_line $reset
        printf "%s%s%s" $color_header committerdate $reset
        printf "%s%s%s" $color_border $right_line $reset
    end
    printf "%s\n" $upper_right_corner
    # end

    # Print the columns of the table
    for i in (seq (count $authors))
        set -l branch $branches[$i]
        set -l content $contents[$i]
        set -l committerdate $committerdates[$i]
        set -l committerdate_as_unix_timestamp $committerdates_as_unix_timestamps[$i]
        set -l author $authors[$i]

        set -l branch_padding (string repeat --count (math "$length_of_longest_branch - $(string length $branch)") " ")
        set -l content_padding (string repeat --count (math "$length_of_longest_content - $(string length $content)") " ")
        set -l committerdate_padding (string repeat --count (math "$length_of_longest_committerdate - $(string length $committerdate)") " ")
        set -l author_padding (string repeat --count (math "$length_of_longest_author - $(string length $author)") " ")

        set -l branch_color $reset
        set -l committerdate_color $blue

        begin
            # Determine the color to use for the author
            set -l new_author_not_seen_before 1
            for unique_author in $unique_authors
                if test $author = $unique_author
                    set new_author_not_seen_before 0
                    break
                end
            end

            if test $new_author_not_seen_before -eq 1
                set -a unique_authors $author
            end

            set -l author_color_index (contains --index -- $author $unique_authors)
            set -f author_color (set_color $author_colors[(math "$author_color_index % $(count $author_colors) + 1")])
        end

        if string match --regex --quiet "^\* $current_branch\$" $branch
            set branch_color (set_color bryellow --bold)
        end

        # FIX: do not merge the padding into the variables
        set -l branch "$branch$branch_padding"
        set -l content "$content$content_padding"
        set -l committerdate "$committerdate$committerdate_padding"
        set -l author "$author$author_padding"

        printf "%s" $output_separator
        if test $show_branch -eq 1
            if string match --quiet "origin*" $branch
                set rest (string sub --start=7 $branch)
                printf " %s%s%s%s%s%s %s" $red origin $reset $branch_color $rest $reset $output_separator
            else
                printf " %s%s%s %s" $branch_color $branch $reset $output_separator
            end

        end
        if test $show_content -eq 1
            printf " %s %s" (__git.fish::conventional-commits::pretty-print $content) $output_separator
        end
        if test $show_author -eq 1
            printf " %s%s%s %s" $author_color $author $reset $output_separator
        end
        if test $show_committerdate -eq 1
            # Assign a heatmap like color to each committerdate, similar to how GitHub does it
            # Intervals are chosen arbitrarily, as I don't know what interval GitHub uses.
            # IDEA: instead fadiing out to white, the go towards blue for a freezing effect
            set -l seconds_since_last_commit (math "$now - $committerdate_as_unix_timestamp")
            set -l committerdate_color
            if test $seconds_since_last_commit -lt 86400 # 1 day
                set committerdate_color (set_color "#e60505")
            else if test $seconds_since_last_commit -lt 172800 # 2 days
                set committerdate_color (set_color "#e93116")
            else if test $seconds_since_last_commit -lt 604800 # 1 week
                set committerdate_color (set_color "#ee5933")
            else if test $seconds_since_last_commit -lt 1209600 # 2 weeks
                set committerdate_color (set_color "#f27750")
            else if test $seconds_since_last_commit -lt 2592000 # 1 month
                set committerdate_color (set_color "#f59f7e")
            else
                set committerdate_color (set_color $fish_color_normal)
            end
            # set committerdate_color $red
            printf " %s%s%s %s" $committerdate_color $committerdate $reset $output_separator
        end

        printf "\n"
    end

    # Only want to print the bottom line if there is more than one branch
    # if test (count $branches) -gt 1
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
    # end
end
