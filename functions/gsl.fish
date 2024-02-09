function gsl -d 'prettify the output of `git shortlog`'
    if not command git rev-parse --is-inside-work-tree >/dev/null
        printf "%serror%s: not inside a git worktree\n" (set_color red) (set_color normal)
        return 1
    end

    command git shortlog | while read line
        if string match --regex --quiet '^\s+' $line
            printf "\t"
            __git.fish::conventional-commits::pretty-print (string trim $line)
        else if not string length --quiet (string trim $line)
            echo
        else
            string pad --right --char=- --width (math min "min 100,$COLUMNS") $line
        end
    end
end
