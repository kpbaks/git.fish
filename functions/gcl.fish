function gcl --description "Print the output of `git config --list` in a pretty format!"
    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l yellow (set_color yellow)
    set -l bold (set_color --bold)

    set -l options h/help l/local
    if not argparse $options -- $argv
        printf "%serror%s: unknown flag given\n" $red $reset >&2
        eval (status function) --help
        return 2
    end

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow
        # Overall description of the command
        printf "%sShow the output of $(printf (echo "git config --list" | fish_indent --ansi))%s%s in a pretty format!%s\n" $bold $reset $bold $reset >&2
        printf "\n" >&2
        # Usage
        printf "%sUsage:%s %s%s%s [options]\n" $section_title_color $reset (set_color $fish_color_command) (status current-command) $reset >&2
        printf "\n" >&2
        # Description of the options and flags
        printf "%sOptions:%s\n" $section_title_color $reset >&2
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset >&2
        printf "\t%s-l%s, %s--local%s     Show the local git config instead of the global\n" $green $reset $green $reset >&2
        printf "\n" >&2

        __git.fish::help_footer
        return 0
    end


    set -l default_param_color $blue
    set -l important_param_color $yellow
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
        set character_length_of_longest_param (math "max $character_length_of_longest_param,$length")
    end
    set -l character_length_of_longest_value 0
    for value in $values
        set -l length (string length $value)
        set character_length_of_longest_value (math "max $character_length_of_longest_value,$length")
    end

    for i in (seq (count $params))
        set -l param (string trim $params[$i])
        set -l value (string trim $values[$i])
        # Skip params that are empty or comments
        string match --quiet --regex "^\s*\$" -- $value; and continue

        set -l length_of_param (string length $param)
        set -l length_of_value (string length $value)
        set -l padding_length_of_param (math "$character_length_of_longest_param - $length_of_param")
        set -l padding_length_of_value (math "$character_length_of_longest_value - $length_of_value")
        set -l padding_of_param (string repeat --count $padding_length_of_param " ")
        set -l padding_of_value (string repeat --count $padding_length_of_value " ")

        # Print out each config option
        set -l value_color $reset
        if test $value = true
            set value_color (set_color --bold green)
        else if test $value = false
            set value_color (set_color --bold red)
        else if string match --quiet --regex "^\d+\$" -- $value
            # value is a digit e.g. "5"
            set value_color (set_color --bold purple)
        else if string match --quiet --regex "^!" -- $value
            # value is command invocation e.g. "!~/.local/bin/gh-2.29.0 auth git-credential"
            set value_color $reset
            # Wrap in `printf` to remove trailing newline
            set value (printf (string sub --start=2 -- $value | fish_indent --ansi))
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
            if string match --quiet --regex "^!" -- $value
                # values starting with ! are shell commands
                set value (printf (string sub --start=2 -- $value | fish_indent --ansi))
            else
                # otherwise they are abbreviated git commands e.g. "co" -> "'git' checkout"
                # Wrap in `printf` to remove trailing newline
                set value (printf (echo "git $value" | fish_indent --ansi))
            end
        end

        set -l param_cell (printf "%s%s%s%s" $param_color $param $reset $padding_of_param)
        set -l separator_cell (printf "%s" $output_separator)
        set -l row_length (math "$(string length $param_cell) + $(string length $separator_cell) + $(string length $value)")

        set -l value_cell (printf "%s%s%s" $value_color $value $reset)

        printf "%s%s%s\n" $param_cell $separator_cell $value_cell
    end
end
