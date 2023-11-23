function gcl --description "Print the output of `git config --list` in a pretty format!"
    set --local reset (set_color normal)
    set --local red (set_color red)
    set --local green (set_color green)
    set --local blue (set_color blue)
    set --local yellow (set_color yellow)
    set --local bold (set_color --bold)

    set --local options (fish_opt --short h --long help)
    set --append options (fish_opt --short l --long local)
    if not argparse $options -- $argv
        printf "%serror:%s unknown flag given\n" $red $reset >&2
        eval (status function) --help
        return 2
    end

    if set --query _flag_help
        printf "%sPrint the output of $(printf (echo "git config --list" | fish_indent --ansi))%s%s in a pretty format!\n" $bold $reset $bold $reset >&2
        printf "\n" >&2
        printf "%sUsage:%s %s%s%s [options]\n" $bold $reset (set_color $fish_color_command) (status current-command) $reset >&2
        printf "\n" >&2
        printf "%sOptions:%s\n" $bold $reset >&2
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset >&2
        printf "\t%s-l%s, %s--local%s     Show the local git config instead of the global\n" $green $reset $green $reset >&2
        return 0
    end


    set --local default_param_color $blue
    set --local important_param_color $yellow
    set --local bar "│"
    set --local output_separator " $bar "
    set --local params
    set --local values
    # Read all the params and values into two arrays
    command git config $_flag_local --list \
        | sort \
        | while read --delimiter = param value
        set --append params $param
        set --append values $value
    end

    # Find the longest param and value
    set --local character_length_of_longest_param 0
    for param in $params
        set --local length (string length $param)
        set character_length_of_longest_param (math "max $character_length_of_longest_param,$length")
    end
    set --local character_length_of_longest_value 0
    for value in $values
        set --local length (string length $value)
        set character_length_of_longest_value (math "max $character_length_of_longest_value,$length")
    end

    for i in (seq (count $params))
        set --local param (string trim $params[$i])
        set --local value (string trim $values[$i])
        # Skip params that are empty or comments
        string match --quiet --regex "^\s*\$" -- $value; and continue

        set --local length_of_param (string length $param)
        set --local length_of_value (string length $value)
        set --local padding_length_of_param (math "$character_length_of_longest_param - $length_of_param")
        set --local padding_length_of_value (math "$character_length_of_longest_value - $length_of_value")
        set --local padding_of_param (string repeat --count $padding_length_of_param " ")
        set --local padding_of_value (string repeat --count $padding_length_of_value " ")

        set --local value_color $reset
        if test $value = true
            set value_color (set_color --bold green)
        else if test $value = false
            set value_color (set_color --bold red)
        else if string match --quiet --regex "^\d+\$" -- $value
            set value_color (set_color --bold purple)
        else if string match --quiet --regex "^!" -- $value
            set value_color $reset
            # Wrap in `printf` to remove trailing newline
            set value (printf (string sub --start 2 -- $value | fish_indent --ansi))
        end

        set --local param_color $default_param_color
        if test $param = "user.name"
            set param_color $important_param_color
            set value_color $important_param_color
        else if test $param = "user.email"
            set param_color $important_param_color
            set value_color $important_param_color
        else if test $param = "remote.origin.url"
            set param_color $important_param_color
            set value_color $important_param_color
        else if string match --quiet --regex "^alias" -- $param
            set param_color (set_color green)
            # TODO: get this to work
            # values starting with ! are shell commands
            # if string match --quiet --regex "^!" -- $value
            #     set value huh
            # set value (printf (echo $value | fish_indent --ansi))
        end

        set --local param_cell (printf "%s%s%s%s" $param_color $param $reset $padding_of_param)
        set --local separator_cell (printf "%s" $output_separator)
        set --local row_length (math "$(string length $param_cell) + $(string length $separator_cell) + $(string length $value)")

        set --local value_cell (printf "%s%s%s" $value_color $value $reset)

        printf "%s%s%s\n" \
            $param_cell \
            $separator_cell \
            $value_cell
    end
end
