function gs --description 'opinionated git status'
    set -l no_color (set_color normal)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l current_branch (command git rev-parse --abbrev-ref HEAD)
    printf "On branch %s%s%s\n" $green $current_branch $no_color
    echo "Changes to be committed:"
    for f in (command git diff --cached --stat HEAD)
        printf "  %s%s%s\n" $green $f $no_color
    end
    echo "" # newline
    echo "Changes not staged for commit:"
    command git diff --stat HEAD
    echo "" # newline
    echo "Untracked files:"
    for f in (command git ls-files --others)
        printf "  %s%s%s\n" $red $f $no_color
    end
end
