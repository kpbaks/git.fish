function git.fish --description "Interact with `kpbaks/git.fish` plugin"
    set --local reset (set_color normal)
    set --local red (set_color red)
    set --local green (set_color green)
    set --local yellow (set_color yellow)
    set -l git_color (set_color red)
    set --local reset (set_color normal)

    set --local argc (count $argv)
    if test $argc -eq 0
        echo "No verb provided"
        set --local scriptdir (path dirname (status filename))
        echo "Usage: $scriptfile <verb> $scriptdir"
        set --local scriptfile (path resolve (status filename))
        set --local scriptdir (path dirname $scriptfile)
        echo "scriptfile: $scriptfile"
        echo "scriptdir: $scriptdir"
        return 1
    end

    set --local verb $argv[1]

    switch $verb
        case status
            set --local git_fish_env_vars
            set | string match --regex --groups-only --all -- '(^GIT_FISH_\S+)' | while read var
                set --append git_fish_env_vars $var
            end

            set --local longest_var_length 0
            for var in $git_fish_env_vars
                set longest_var_length (math "max $(string length $var),$longest_var_length")
            end

            for var in $git_fish_env_vars
                set --local padding_length (math "$longest_var_length - $(string length $var) + 1")
                set --local padding (string repeat --count $padding_length ' ')
                set --local val $$var
                set --local val_color $reset
                if string match --quiet "*ENABLE*" -- $var
                    if test "$val" = 0
                        set val_color $red
                    else if test "$val" = 1
                        set val_color $green
                    end
                end

                printf "%s%s = %s%s%s\n" $var $padding $val_color $val $reset
            end

        case abbr abbrs abbreviations
            set --local longest_abbr_length 0
            for abbr in $__GIT_FISH_ABBREVIATIONS
                set longest_abbr_length (math "max $(string length $abbr),$longest_abbr_length")
            end

            set --local abbreviation_heading abbreviation
            set --local expanded_heading expanded
            set --local padding_length (math $longest_abbr_length - (string length $abbreviation_heading))
            set --local padding (string repeat --count $padding_length ' ')

            # set --local git_color (set_color "#f44d27") # taken from git's logo
            # printf "there are %s%d%s abbreviations\n" $git_color (count $__GIT_FISH_ABBREVIATIONS) $reset
            __git.fish::echo (printf "there are %s%d%s abbreviations\n" $git_color (count $__GIT_FISH_ABBREVIATIONS) $reset)

            set --local hr (string repeat --count $COLUMNS -)
            echo $hr
            printf "%s%s | %s\n" $abbreviation_heading $padding $expanded_heading
            echo $hr

            for i in (seq (count $__GIT_FISH_ABBREVIATIONS))
                set --local abbr $__GIT_FISH_ABBREVIATIONS[$i]
                set --local expanded $GIT_FISH_EXPANDED_ABBREVIATIONS[$i]
                set --local abbr_length (string length $abbr)
                set --local padding_length (math $longest_abbr_length - $abbr_length)
                set --local padding (string repeat --count $padding_length ' ')
                printf "%s%s | " $abbr $padding
                echo "$expanded" | fish_indent --ansi
                # set --local padding (string repeat ' ' (math (math $longest_abbr_length - (string length $abbr)) + 2))
                # echo "$abbr + $expanded"

            end
            echo $hr

            # for abbr in $__GIT_FISH_ABBREVIATIONS
            #     echo $abbr | fish_indent --ansi
            # end
            #
        case "*"
            echo "Unknown verb: $verb"
            return 2
    end
end
