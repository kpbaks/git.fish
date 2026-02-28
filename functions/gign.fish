function gign --description 'Get .gitignore file from https://www.toptal.com/developers/gitignore/api'
    # https://docs.gitignore.io/
    set -l options h/help l/list m/merge s/simplify
    # TODO: <kpbaks 2023-09-26 09:55:39> give files/directories as input and add them to .gitignore
    # TODO: implement
    set --append options (fish_opt --short=a --long=add --required-val --multiple-vals)
    # TODO: implement --simplify

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set --local argc (count $argv)

    set --local reset (set_color normal)
    set --local red (set_color red)
    set --local green (set_color green)
    set --local yellow (set_color yellow)
    set --local cyan (set_color cyan)
    set --local bold (set_color --bold)

    if set --query _flag_list
        # The gitignore.io API treats the language "list" as a special case, where it returns a list of all supported languages/frameworks
        # This way, we can reuse the same code for when we query the gitignore.io API for a specific language/framework
        # It returns a comma separated list of languages/frameworks
        gign list | string replace --regex --all "[ ,]" "\n"
        return 0
    end

    if set --query _flag_help; or test $argc -eq 0
        set -l option_color $green
        set -l section_title_color $yellow
        # Overall description of the command
        printf "%sDownload common .gitignore rules for various programming languages and frameworks from %shttps://docs.gitignore.io/%s%s and merge them with your .gitignore%s\n" $bold (set_color --underline cyan) $reset $bold $reset >&2
        printf "\n" >&2
        # Usage
        printf "%sUSAGE:%s %s%s%s [options] LANG [LANG...]\n" $section_title_color $reset (set_color $fish_color_command) (status current-command) $reset >&2
        printf "\n" >&2
        # Arguments
        printf "%sARGUMENTS:%s\n" $section_title_color $reset >&2
        printf "\t%sLANG%s    Programming language or framework to download .gitignore rules for.\n" $option_color $reset >&2
        printf "\n" >&2
        # Options
        printf "%sOPTIONS:%s\n" $section_title_color $reset >&2
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset >&2
        # printf "\t%s-a%s, %s--add%s       Add the rules to your .gitignore file\n" $green $reset $green $reset >&2
        printf "\t%s-l%s, %s--list%s      List all supported languages/frameworks\n" $green $reset $green $reset >&2
        if test -f .gitignore
            printf "\t%s-m%s, %s--merge%s     Merge with existing .gitignore file, avoiding duplicates\n" $green $reset $green $reset >&2
            # printf "\t%s-s%s, %s--simplify%s  Simplify your .gitigore by removing redundant rules\n" $green $reset $green $reset >&2
        end
        printf "\n" >&2
        # Examples
        printf "%sEXAMPLES:%s\n" $section_title_color $reset >&2
        printf "\t" >&2
        printf "%s python > .gitignore" (status current-command) | fish_indent --ansi >&2
        printf "\t" >&2
        printf "%s python flask > .gitignore" (status current-command) | fish_indent --ansi >&2
        printf "\n" >&2
        __git::help_footer

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

    # The items in the query needs to be separated by commas
    set --local query (string trim $argv | string replace --regex --all " +" ,)
    set --local gitignore ($http_get_command $http_get_command_args https://www.toptal.com/developers/gitignore/api/$query)
    if string match --quiet --regex "ERROR:" $gitignore
        set --local n (math min "100,$COLUMNS")
        set --local d ━
        set --local hr (string repeat --count $n $d)
        printf "%serror:%s response from gitignore.io was\n" $red $reset >&2
        echo $hr >&2
        printf "%s\n" $gitignore >&2
        echo $hr >&2
        # TODO: <kpbaks 2023-09-08 19:41:14> Use a hamming distance algorithm, suggest the closest match
        # So if you type "python" it will suggest "python"
        printf "%shint%s: You probably misspelled a language/framework name\n" $cyan $reset >&2
        printf "      or the language/framework is not supported.\n" >&2
        printf "      Try running %s%s to see a list of supported languages/frameworks\n" (printf (echo "gi --list" | fish_indent --ansi)) $reset >&2

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
