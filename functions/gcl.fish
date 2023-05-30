function gcl --description "Print the git config in a nice format"
    set -l options (fish_opt --short h --long help)
    # specifying the short flag -l is necessary even though it is not valid. (why fish?)
    set -a options (fish_opt --short l --long local --long-only)
    if not argparse $options -- $argv
        return 1
    end

    if set --query _flag_help
        set -l usage "$(set_color --bold)Print the git config in a nice format$(set_color normal)

$(set_color yellow)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options]

$(set_color yellow)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
	$(set_color green)-l$(set_color normal), $(set_color green)--local$(set_color normal)     Show the local git config

Part of $(set_color cyan)git.fish$(set_color normal) at https://github.com/kpbs5/git.fish"

        echo $usage
        return 0
    end


    set -l default_param_color (set_color blue)
    set -l important_param_color (set_color yellow)
    set -l normal (set_color normal)
    set -l bar "│"
    set -l output_separator " $bar "
    set -l params
    set -l values
    # Read all the params and values into two arrays
    command git config $_flag_local --list \
        | sort \
        | while read --delimiter = param value
        set --append params $param
        set --append values $value
    end

    # Find the longest param and value
    set -l character_length_of_longest_param 0
    for param in $params
        set -l length (string length $param)
        if test $length -gt $character_length_of_longest_param
            set character_length_of_longest_param $length
        end
    end
    set -l character_length_of_longest_value 0
    for value in $values
        set -l length (string length $value)
        if test $length -gt $character_length_of_longest_value
            set character_length_of_longest_value $length
        end
    end

    if set --query _flag_local
        _git_fish_echo "local git config:"
    else
        _git_fish_echo "global git config:"
    end

    for i in (seq (count $params))
        set -l param (string trim $params[$i])
        set -l value (string trim $values[$i])
        # Skip params that are empty or comments
        if string match --quiet --regex "^\s*\$" -- $value
            continue
        end
        set -l length_of_param (string length $param)
        set -l length_of_value (string length $value)
        set -l padding_length_of_param (math "$character_length_of_longest_param - $length_of_param")
        set -l padding_length_of_value (math "$character_length_of_longest_value - $length_of_value")
        set -l padding_of_param (string repeat --count $padding_length_of_param " ")
        set -l padding_of_value (string repeat --count $padding_length_of_value " ")

        set -l value_color $normal
        if test $value = true
            set value_color (set_color --bold green)
        else if test $value = false
            set value_color (set_color --bold red)
        else if string match --quiet --regex "^\d+\$" -- $value
            set value_color (set_color --bold purple)
        end

        set -l param_color $default_param_color
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
            #     set value (echo $value | fish_indent --ansi)
            # end
        end

        set -l param_cell (printf "%s%s%s%s" $param_color $param $normal $padding_of_param)
        set -l separator_cell (printf "%s" $output_separator)
        set -l row_length (math "$(string length $param_cell) + $(string length $separator_cell) + $(string length $value)")
        set -l ellipsis " ... "
        set -l ellipsis_length (string length $ellipsis)
        set -l free_space (math "$COLUMNS - $ellipsis_length")

        if test $row_length -gt $free_space
            # Ellipsize the value cell
            # TODO: not entirely accurate, but good enough for now
            set -l cutoff (math "$free_space - $(string length $param_cell) - $(string length $separator_cell)")
            set value (string sub --start 1 --end $cutoff -- $value)
            set value (printf "%s%s%s%s" $value (set_color --bold red) $ellipsis $normal)
        end
        set -l value_cell (printf "%s%s%s" $value_color $value $normal)

        printf "%s%s%s\n" \
            $param_cell \
            $separator_cell \
            $value_cell
    end
end
