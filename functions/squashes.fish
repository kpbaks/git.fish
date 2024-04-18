function squashes -d 'list all unpushed commits containing r`squash( me)?`'

    set -l options h/help r/regex=
    if not argparse $options -- $argv
        printf '\n'
        eval (status function) --help
        return 2
    end

    set -l squash_regexp 'squash( me)?'

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

        printf '%slist all unpushed commits containing r`squash( me)?`%s\n' $bold $reset
        printf '\n'
        printf '%sUSAGE:%s %s%s%s [OPTIONS]\n' $section_header_color $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS:%s\n' $section_header_color $reset
        printf '\t%s-h%s, %s--help%s         Show this help message and return\n' $option_color $reset $option_color $reset
        printf '\t%s-r%s, %s--regex%s REGEX  Set regexp to use for detecting if a commitmsg contains a "squash me" [default: "%s"]\n' $option_color $reset $option_color $reset $squash_regexp
        printf '\n'
        printf '%sRETURNS:%s\n' $section_header_color $reset
        printf '\t%s0%s if 1 or more unpushed commits are "squash me" commits\n' $green $reset
        printf '\t%s1%s if 0 unpushed commits are "squash me" commits\n' $red $reset
        return 0

    end >&2

    if set --query $_flag_regex
        set squash_regexp $_flag_regex
    end

    set -l hashes
    set -l commitmsgs

    # https://stackoverflow.com/questions/2016901/how-to-list-unpushed-git-commits-local-but-not-on-origin
    command git cherry -v | while read line
        string match --regex --groups-only '^\+ (\S+) (.+)$' -- $line | read --line hash commitmsg

        # if string match --quiet --regex 'squash( me)?' -- $commitmsg
        if string match --quiet --regex "$squash_regexp" -- $commitmsg
            set -a hashes $hash
            set -a commitmsgs $commitmsg
        end
    end

    if test (count $hashes) -gt 0
        if isatty stdout
            for i in (seq (count $hashes))
                printf '+ %s%s%s %s%s%s\n' $magenta $hashes[$i] $reset $bold $commitmsgs[$i] $reset
            end
        else
            for i in (seq (count $hashes))
                printf '+ %s %s\n'$hashes[$i] $commitmsgs[$i]
            end
        end
        return 0
    else
        return 1
    end
end
