function gcl --description "Print the git config in a nice format"
    set --local options (fish_opt --short h --long help)
    set --append options (fish_opt --short l --long local)
    if not argparse $options -- $argv
        return 1
    end

    if set --query _flag_help
        set --local usage "$(set_color --bold)Print the git config in a nice format$(set_color normal)

$(set_color yellow)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options]

$(set_color yellow)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
	$(set_color green)-l$(set_color normal), $(set_color green)--local$(set_color normal)     Show the local git config

Part of $(set_color cyan)git.fish$(set_color normal) at https://github.com/kpbs5/git.fish"

        echo $usage
        return 0
    end


    set --local default_param_color (set_color blue)
    set --local important_param_color (set_color yellow)
    set --local reset (set_color normal)
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
        # if test $length -gt $character_length_of_longest_param
        #     set character_length_of_longest_param $length
        # end
    end
    set --local character_length_of_longest_value 0
    for value in $values
        set --local length (string length $value)
        set character_length_of_longest_value (math "max $character_length_of_longest_value,$length")
        # if test $length -gt $character_length_of_longest_value
        #     set character_length_of_longest_value $length
        # end
    end

    if set --query _flag_local
        __git.fish::echo "local git config:"
    else
        __git.fish::echo "global git config:"
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
        set --local ellipsis " ... "
        set --local ellipsis_length (string length $ellipsis)
        set --local free_space (math "$COLUMNS - $ellipsis_length")

        if test $row_length -gt $free_space
            # Ellipsize the value cell
            # TODO: not entirely accurate, but good enough for now
            set --local cutoff (math "$free_space - $(string length $param_cell) - $(string length $separator_cell)")
            set value (string sub --start 1 --end $cutoff -- $value)
            set value (printf "%s%s%s%s" $value (set_color --bold red) $ellipsis $reset)
        end
        set --local value_cell (printf "%s%s%s" $value_color $value $reset)

        printf "%s%s%s\n" \
            $param_cell \
            $separator_cell \
            $value_cell
    end
end
