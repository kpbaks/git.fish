function gss -d 'opinionated `git status --short`'
    set -l current_branch (command git rev-parse --abbrev-ref HEAD)
    set -l remote_branches (command git branch --remotes | string trim)
    # TODO: implement
    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    # set -l remote_branch (command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)

    # show 'branch...remote'
    # set --local --long | scope
    printf "## %s%s%s" $green $current_branch $reset
    if contains --index -- origin/$current_branch $remote_branches | read index
        set -l remote_branch_linked_to_current $remote_branches[$index]
        printf '...%s%s%s' $red $remote_branch_linked_to_current $reset

        # [ahead <n>, behind <m>]
        # [ahead <n>]
        # [behind <m>]
        command git rev-list --left-right --count $current_branch...origin/$current_branch | read local remote
        if test $local -gt 0 -a $remote -gt 0
            printf ' [ahead %s%s%s, behind %s%s%s]' $green $local $reset $red $remote $reset
        else if test $local -gt 0
            printf ' [ahead %s%s%s]' $green $local $reset
        else if test $remote -gt 0
            printf ' [behind %s%s%s]' $red $local $reset
        end
        printf '\n'
    end

    command git status --short --untracked-files=all
end
