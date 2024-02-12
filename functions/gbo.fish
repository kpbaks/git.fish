# (g)it (b)ranch (o)verview
function gbo -d "'(g)it (b)ranch (o)verview'"
    set -l options h/help a/all u/unchecked l/legend

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l yellow (set_color yellow)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l red (set_color red)
    set -l color_border (set_color $fish_color_normal)

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow

        echo todo
        return 0
    end

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

    set -l field_delimiter '#'
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

    # Read data for each column into a separate array
    set -l branches
    set -l contents
    set -l authors
    set -l committerdates
    command git branch $all --format="%(HEAD) %(refname:short) $field_delimiter %(contents:subject) $field_delimiter %(committerdate:relative) $field_delimiter %(authorname)" --sort=-committerdate \
        | while read --delimiter $field_delimiter branch content committerdate author
        set -a branches (string trim -- $branch)
        set -a contents (string trim -- $content)
        set -a committerdates (string trim -- $committerdate)
        set -a authors (string trim -- $author)
    end

    set -l author_colors cyan red blue green yellow magenta
    set -l unique_authors

    set -l longest_branch branch
    set -l length_of_longest_branch (string length branch)
    for branch in $branches
        if test (string length $branch) -gt (string length $longest_branch)
            set longest_branch $branch
            set length_of_longest_branch (string length $branch)
        end
    end
    set -l longest_content commit
    set -l length_of_longest_content (string length commit-msg)
    for content in $contents
        if test (string length $content) -gt (string length $longest_content)
            set longest_content $content
            set length_of_longest_content (string length $content)
        end
    end
    set -l longest_committerdate committerdate
    set -l length_of_longest_committerdate (string length committerdate)
    for committerdate in $committerdates
        if test (string length $committerdate) -gt (string length $longest_committerdate)
            set longest_committerdate $committerdate
            set length_of_longest_committerdate (string length $committerdate)
        end
    end
    set -l longest_author author
    set -l length_of_longest_author (string length author)
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
        # TODO: print this less cluttered
        __git.fish::echo "The following $(set_color --italics)local$(set_color normal) branches exist ($(set_color --italics)the $(set_color yellow)*$(set_color normal)$(set_color --italics) indicates the branch you are on$(set_color normal)):"
    end

    # Only what to print the top border if there are multiple branches
    # TODO: print the top border like in nushell:
    # "╭────name────┬─type─┬──size──┬───modified────╮"

    # if test (count $branches) -gt 1
    printf "%s%s%s" $color_border $upper_left_corner $reset
    if test $show_branch -eq 1
        printf "%s%s%s%s" $color_border (string repeat --count (math "$length_of_longest_branch + 2") $underline) $downwards_tee $reset
        # printf "%s" $downwards_tee
    end
    if test $show_content -eq 1
        printf "%s%s%s%s" $color_border (string repeat --count (math "$length_of_longest_content + 2") $underline) $downwards_tee $reset
    end
    if test $show_author -eq 1
        printf "%s%s%s%s" $color_border (string repeat --count (math "$length_of_longest_author + 2") $underline) $downwards_tee $reset
    end
    if test $show_committerdate -eq 1
        printf "%s%s%s" $color_border (string repeat --count (math "$length_of_longest_committerdate + 2") $underline) $reset
    end
    printf "%s\n" $upper_right_corner
    # end


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
            # TODO: color the `origin/`
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
