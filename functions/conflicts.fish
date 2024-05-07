function conflicts -d ''
    set -l options h/help c/count
    if not argparse $options -- $argv
        printf '\n'
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        set -l reset (set_color normal)
        set -l bold (set_color --bold)
        set -l section_header_color (set_color yellow)

        printf '%sdescription%s\n' $bold $reset
        printf '\n'
        printf '%sUSAGE:%s %s%s%s [OPTIONS]\n' $section_header_color $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS:%s\n' $section_header_color $reset
        printf '%s\t%s-h%s, %s--help%s Show this help message and return\n'
        # printf '%sEXAMPLES:%s\n' $section_header_color $reset
        # printf '\t%s%s\n' (printf (echo "$(status function)" | fish_indent --ansi)) $reset
        return 0
    end >&2

    if not command git rev-parse --is-inside-work-tree 2>/dev/null >&2
        printf "%serror:%s not inside a git repository\n" $red $reset >&2
        return 2
    end


    # for every 4 lines in `git diff --check`

    set -l n_conflicts 0

    # <<<<<<< HEAD
    # fOo
    # ||||||| aff621f
    # foo
    # =======
    # fAo
    # >>>>>>> other

    # FIXME: handle power set of combinations

    command git diff --check | while read --line current bar equal incoming
        string match --regex --groups-only '^([^:]+):(\d+):' $current | read --line file_start line_start
        string match --regex --groups-only '^([^:]+):(\d+):' $bar | read --line file_start line_bar
        string match --regex --groups-only '^([^:]+):(\d+):' $equal | read --line file_start line_equal
        string match --regex --groups-only '^([^:]+):(\d+):' $incoming | read --line file_end line_end

        # FIXME: this does not work if there are multiple conflict markers in the same file
        if test $file_start != $file_end
            printf 'sorry, i do not know how to parse this ordering of conflict markers\n'
            return 1
        end

        set n_conflicts (math $n_conflicts + 1)
        set --query _flag_count; and continue

        command bat $file_start \
            --paging never \
            --line-range $line_start:$line_end \
            --highlight-line (math $line_start + 1):(math $line_bar - 1) \
            --highlight-line (math $line_equal + 1):(math $line_end - 1)

        # --highlight-line $line_equal:$line_end
    end

    if set --query _flag_count
        echo "$n_conflicts"
        return 0
    end

    if test $n_conflicts -eq 0
        printf 'no conflicts found 😎\n'
    end

    return 0
end
