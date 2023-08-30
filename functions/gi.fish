function gi --description 'Get .gitignore file from https://www.toptal.com/developers/gitignore/api'
    # https://docs.gitignore.io/
    set --local options (fish_opt --short=h --long=help)
    set --append options (fish_opt --short=m --long=merge)
    if not argparse $options -- $argv
        return 1
    end

    set --local argc (count $argv)

    set --local reset (set_color normal)
    set --local red (set_color red)
    set --local green (set_color green)
    set --local yellow (set_color yellow)

    if set --query _flag_help; or test $argc -eq 0
        set --local usage "$(set_color --bold)Download common .gitignore rules for various programming languages and frameworks from https://docs.gitignore.io/$(set_color normal)

$(set_color yellow --underline)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options] LANG [LANG...]

$(set_color yellow --underline)Arguments:$(set_color normal)
$(set_color green)LANG$(set_color normal)    Programming language or framework to download .gitignore rules for. Multiple languages can be specified.

$(set_color yellow --underline)Options:$(set_color normal)
$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
$(set_color green)-m$(set_color normal), $(set_color green)--merge$(set_color normal)     Merge with existing .gitignore file, avoiding duplicates

$(set_color yellow --underline)Examples:$(set_color normal)
$(set_color blue)$(status current-command)$(set_color normal) python > .gitignore
$(set_color blue)$(status current-command)$(set_color normal) python flask > .gitignore

Part of $(set_color cyan)git.fish$(set_color normal) at https://github.com/kpbaks/git.fish"

        echo $usage
        return 0
    end

    set --local http_get_command
    set --local http_get_command_args
    if command --query curl
        set http_get_command curl
        set http_get_command_args -sSL
    else if command --query wget
        set http_get_command wget
        set http_get_command_args -qO-
    else
        printf "%sPlease install curl or wget to run this command%s" $red $reset >&2
        return 1
    end

    set --local query (string join , "$argv")
    set --local gitignore ($http_get_command $http_get_command_args https://www.toptal.com/developers/gitignore/api/$query)
    if string match --quiet "ERROR:" $gitignore
        printf "%serror:%s\n" $red $reset >&2
        echo $gitignore >&2
        return 1
    end

    if set --query _flag_merge
        if test -f .gitignore
            set --local lines_added_count 0
            set --local existing_gitignore (cat .gitignore)
            for line in $gitignore
                test (string trim $line) = ""; and continue
                # if string match --quiet --regex "^$(string escape $line)" <.gitignore
                set --local found 0
                for lnum in (seq (count $existing_gitignore))
                    set --local existing_line $existing_gitignore[$lnum]
                    test (string trim $existing_line) = ""; and continue
                    if test $line = $existing_line
                        printf "already exists in .gitignore, on line %d: %s%s%s\n" $lnum $yellow $line $reset >&2
                        set found 1
                        break
                    end
                end
                test $found -eq 1; and continue

                echo $line >>.gitignore
                set lines_added_count (math $lines_added_count + 1)
            end
            if test $lines_added_count -gt 0
                printf "%s%d lines added to .gitignore%s\n" $green $lines_added_count $reset >&2
                # Check if .gitignore is being tracked by git
                if contains -- .gitignore (command git ls-files)
                    command git diff .gitignore
                end
            end

            return 0
        else
            printf "%sNo .gitignore file found%s\n" $red $reset >&2
        end
    end

    for line in $gitignore
        echo $line
    end
end
