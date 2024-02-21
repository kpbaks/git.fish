function git.fish -a subcommand --description "Interact with `kpbaks/git.fish` plugin"

    set -l options h/help
    if not argparse $options -- $argv
        printf "\n"
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l git_color (set_color red)
    set -l reset (set_color normal)

    if set --query _flag_help
        # TODO: write

        return 0
    end

    if test (count $argv) -eq 0
        # TODO: improve
        echo "No subcommand provided"
        set -l scriptdir (path dirname (status filename))
        echo "Usage: $scriptfile <subcommand> $scriptdir"
        set -l scriptfile (path resolve (status filename))
        set -l scriptdir (path dirname $scriptfile)
        echo "scriptfile: $scriptfile"
        echo "scriptdir: $scriptdir"
        return 1
    end

    switch $subcommand
        case status
            set -l git_fish_env_vars
            set | string match --regex --groups-only --all -- '(^GIT_FISH_\S+)' | while read var
                set --append git_fish_env_vars $var
            end

            set -l longest_var_length 0
            for var in $git_fish_env_vars
                set longest_var_length (math "max $(string length $var),$longest_var_length")
            end

            for var in $git_fish_env_vars
                set -l padding_length (math "$longest_var_length - $(string length $var) + 1")
                set -l padding (string repeat --count $padding_length ' ')
                set -l val $$var
                set -l val_color $reset
                if string match --quiet "*ENABLE*" -- $var
                    if test "$val" = 0
                        set val_color $red
                    else if test "$val" = 1
                        set val_color $green
                    end
                end

                printf "%s%s = %s%s%s\n" $var $padding $val_color $val $reset
            end

        case enable # <module>
        case disable # <module>
        case abbr
            set -l longest_abbr_length 0
            for abbr in $__GIT_FISH_ABBREVIATIONS
                set longest_abbr_length (math "max $(string length $abbr),$longest_abbr_length")
            end

            set -l abbreviation_heading abbreviation
            set -l expanded_heading expanded
            set -l padding_length (math $longest_abbr_length - (string length $abbreviation_heading))
            set -l padding (string repeat --count $padding_length ' ')

            # set -l git_color (set_color "#f44d27") # taken from git's logo
            # printf "there are %s%d%s abbreviations\n" $git_color (count $__GIT_FISH_ABBREVIATIONS) $reset
            __git.fish::echo (printf "there are %s%d%s abbreviations\n" $git_color (count $__GIT_FISH_ABBREVIATIONS) $reset)

            set -l hr (string repeat --count $COLUMNS -)
            echo $hr
            printf "%s%s | %s\n" $abbreviation_heading $padding $expanded_heading
            echo $hr

            for i in (seq (count $__GIT_FISH_ABBREVIATIONS))
                set -l abbr $__GIT_FISH_ABBREVIATIONS[$i]
                set -l expanded $GIT_FISH_EXPANDED_ABBREVIATIONS[$i]
                set -l abbr_length (string length $abbr)
                set -l padding_length (math $longest_abbr_length - $abbr_length)
                set -l padding (string repeat --count $padding_length ' ')
                printf "%s%s | " $abbr $padding
                echo "$expanded" | fish_indent --ansi
                # set -l padding (string repeat ' ' (math (math $longest_abbr_length - (string length $abbr)) + 2))
                # echo "$abbr + $expanded"

            end
            echo $hr

            # for abbr in $__GIT_FISH_ABBREVIATIONS
            #     echo $abbr | fish_indent --ansi
            # end
            #
        case "*"
            printf "%serror%s: unknown subcommand: %s\n" $red $reset $subcommand
            eval (status function) --help
            return 2
    end
end
