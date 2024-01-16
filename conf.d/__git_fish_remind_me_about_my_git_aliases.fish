status is-interactive; or return 0

set --query GIT_FISH_REMIND_ME_ABOUT_MY_GIT_ALIASES; or set --global GIT_FISH_REMIND_ME_ABOUT_MY_GIT_ALIASES 0
test $GIT_FISH_REMIND_ME_ABOUT_MY_GIT_ALIASES -eq 1; or return 0

function __git.fish::remind_me_about_my_git_aliases --on-event fish_postexec
    # if the user typed a git command, remind them about their aliases
    # but only if they used a subcommand that they have an alias for.
    set argv (string split " " -- $argv)
    test $argv[1] = git; or return 0
    test (count $argv) -gt 1; or return 0 # no subcommand

    command git config --list \
        | string match --regex "^alias.*" \
        | string replace "alias." "" \
        | while read --delimiter = --local alias expansion

        test "$expansion" = "$argv[2..]"; or continue
        # if the user typed the expansion of an alias remind the person
        # that the alias exists
        set -l reset (set_color normal)
        __git.fish::echo "STOP WHAT YOU'RE DOING! You have a $(set_color red)git alias$(set_color normal) for this subcommand:"
        printf "\t"
        printf "%s%s" (echo "git $alias" | fish_indent --ansi) $reset
        printf " -> "
        printf "%s%s" (echo "git $expansion" | fish_indent --ansi) $reset
        printf "\n"
    end
end
