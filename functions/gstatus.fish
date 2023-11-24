function gstatus --description 'opinionated git status'
    set -l reset (set_color normal)
    set -l green (set_color green)
    set -l red (set_color red)

    set -l options (fish_opt --short=h --long=help)
    if not argparse $options -- $argv
        return 2
    end

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow
        set -l bold (set_color --bold)
        # Overall description of the command
        printf "%sOpinionated $(printf (echo "git status" | fish_indent --ansi))%s\n" $bold $reset >&2
        printf "\n" >&2
        # Usage
        printf "%sUsage%s %s%s%s\n" $section_title_color $reset  (set_color $fish_color_command) (status current-command) $reset >&2
        printf "\n" >&2
        # Description
        printf "%sOptions:%s\n" $section_title_color $reset >&2
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset >&2
        printf "\n" >&2

        __git.fish::help_footer
        return 0
    end

    set -l current_branch (command git rev-parse --abbrev-ref HEAD)

    printf "On branch %s%s%s\n" $green $current_branch $reset
    echo "Changes to be committed:"
    # TODO: color the file name and parent directory
    for f in (command git diff --cached --stat HEAD)
        printf "  %s%s%s\n" $green $f $reset
    end
    printf "\n"

    echo "Changes not staged for commit:"
    command git diff --stat HEAD

    printf "\n"
    echo "Untracked files:"
    for f in (command git ls-files --others)
        printf "  %s%s%s\n" $red $f $reset
    end
end
