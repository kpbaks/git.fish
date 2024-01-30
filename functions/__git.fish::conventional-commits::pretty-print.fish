function __git.fish::conventional-commits::pretty-print -a commit
    argparse --min-args 1 --max-args 1 -- $argv; or return 2

    set -l matches (__git.fish::conventional-commits::parse $commit)
    if test $status -ne 0
        echo $commit # Print the commit as is
        return 1
    end

    set -l type $matches[1]
    set -l desc $matches[-1]

    set -l reset (set_color normal)
    set -l italics (set_color --italics)

    set -l breaking 0
    switch (count $matches)
        case 3
            # Can either be a scope or a breaking change '!'
            if test $matches[2] = "!"
                set breaking 1
            else
                set -f scope $matches[2]
            end
        case 4
            # Scope and breaking change
            set -f scope $matches[2]
            set breaking 1
        case '*'
    end

    set -l set_color_opts
    if test $breaking -eq 1
        # It is a breaking commit so we want it to stand out
        # set set_color_opts --background
        set set_color_opts --reverse
    end

    switch $type
        case feat
            set -f color_type (set_color $set_color_opts green)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case fix
            set -f color_type (set_color $set_color_opts red)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case build
            set -f color_type (set_color $set_color_opts yellow)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case chore
            set -f color_type (set_color $set_color_opts yellow)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case ci docs
            set -f color_type (set_color $set_color_opts yellow)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case style
            set -f color_type (set_color $set_color_opts yellow)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case refactor perf
            set -f color_type (set_color $set_color_opts magenta)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
        case test
            set -f color_type (set_color $set_color_opts cyan)
            set -f color_scope (set_color --bold)
            set -f color_desc $italics
    end

    # Print the different parts of the commit
    printf "%s%s%s" $color_type $type $reset
    if set --query scope
        printf "%s(%s)%s" $color_scope $scope $reset
    end
    if test $breaking -eq 1
        printf "%s%s%s" $color_desc "!" $reset
    end
    # TODO: format sections in `` like in markdown
    printf ": %s%s%s" $color_desc $desc $reset
    printf "\n"
end
