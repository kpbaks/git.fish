status is-interactive; or return 0

set --query GIT_FISH_GIT_ALIAS_REMINDER_ENABLE; or set --universal GIT_FISH_GIT_ALIAS_REMINDER_ENABLE 0
test $GIT_FISH_GIT_ALIAS_REMINDER_ENABLE -eq 1; or return 0

function __git.fish::remind_me_about_my_git_aliases --on-event fish_postexec
    # if the user typed a git command, remind them about their aliases
    # but only if they used a subcommand that they have an alias for.
    set --local cmd $argv[1]
    test $cmd = git; or return 0

    set --local subcmd $argv[2]
    test -n $subcmd; or return 0 # no subcommand

    command git config --list \
        | string match --regex "^alias.*" \
        | string replace "alias." "" \
        | while read --delimiter = --local alias expansion

        test "$expansion" = "$argv[2..]"; or continue
        # if the user typed the expansion of an alias remind the person
        # that the alias exists
        __git.fish::echo "STOP WHAT YOU'RE DOING! You have a git alias for this command:"
        printf "%s%s%s -> " (set_color $fish_color_param) $alias (set_color normal)

        echo $expansion | fish_indent --ansi
    end
end
