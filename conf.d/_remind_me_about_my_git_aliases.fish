status is-interactive; or return

function _remind_me_about_my_git_aliases --on-event fish_postexec
    # if the user typed a git command, remind them about their aliases
    # but only if they used a subcommand that they have an alias for.
    set -l cmd $argv[1]
    test $cmd = git; or return

    # set argv (string split " " $argv)
    set -l subcmd $argv[2]
    test -n $subcmd; or return


    set -l aliases
    set -l expansions

    git config --list \
        | string match --regex "^alias.*" \
        | string replace "alias." "" \
        | while read --delimiter = --local alias expansion
        set --append aliases $alias
        set --append expansions $expansion

        test "$expansion" = "$argv[2..]"; or continue
        # if the user typed the expansion of an alias remind the person
        # that the alias exists
        set -l git_color (set_color "#f44d27") # taken from git's logo
        set -l normal (set_color normal)
        printf "%STOP WHAT YOU'RE DOING!%s
you have a git alias for this command:
	%s%s%s -> " \
            $git_color $normal \
            $git_color $alias $normal

        echo $expansion | fish_indent --ansi
        echo ""
    end


    # for alias_and_expansion in $git_aliases
    #     echo $alias_and_expansion | read -l alias expansion --delimiter "="
    #     if test "$expansion" = "$argv[2..]"
    #         set_color cyan
    #         hr -
    #         set_color normal
    #
    #         echo -n "DID YOU KNOW you can use the alias "
    #         echo -n "git $alias" | fish_indent --ansi
    #         echo -n "instead of "
    #         echo "$argv" | fish_indent --ansi
    #
    #         echo ""
    #         echo "To see all your git aliases, run:"
    #         echo "git config --list | string match -r \"^alias.*\" | string replace \"alias.\" \"\" | column --table --separator = --table-columns-limit 2" | fish_indent --ansi
    #
    #         set_color cyan
    #         hr -
    #         set_color normal
    #         return
    #     end
    # end
end
