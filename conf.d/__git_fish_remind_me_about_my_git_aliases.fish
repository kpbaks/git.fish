status is-interactive; or return

set --query GIT_FISH_GIT_ALIAS_REMINDER_ENABLE; or set --universal GIT_FISH_GIT_ALIAS_REMINDER_ENABLE 0
test $GIT_FISH_GIT_ALIAS_REMINDER_ENABLE -eq 1; or return

function __git.fish::remind_me_about_my_git_aliases --on-event fish_postexec
    # if the user typed a git command, remind them about their aliases
    # but only if they used a subcommand that they have an alias for.
    set --local cmd $argv[1]
    test $cmd = git; or return

    set --local subcmd $argv[2]
    test -n $subcmd; or return # no subcommand

    command git config --list \
        | string match --regex "^alias.*" \
        | string replace "alias." "" \
        | while read --delimiter = --local alias expansion

        test "$expansion" = "$argv[2..]"; or continue
        # if the user typed the expansion of an alias remind the person
        # that the alias exists
        # TODO: <kpbaks 2023-10-13 18:22:30> change prompt
        set --local git_color (set_color "#f44d27") # taken from git's logo
        set --local reset (set_color normal)
        __git.fish::echo "STOP WHAT YOU'RE DOING! You have a git alias for this command:"
        printf "%s%s%s -> " \
            $git_color $alias $reset

        echo $expansion | fish_indent --ansi
        echo ""
    end
end
