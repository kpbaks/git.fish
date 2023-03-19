function bselect
    # https://github.com/hsaunders1904/git-branch-selector
    if not command --query fzf
        set_color red
        echo "`fzf` was not found in \$PATH"
        set_color normal
        return 1
    end

    # check if we are in a git repository
    if not command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set_color red
        echo "$PWD is not inside a git worktree"
        set_color normal
        return 1
    end

    set -l options (fish_opt --short a --long all)

    argparse $options -- $argv; or return 1

    if set --query _flag_all

    end

    set -l git_branches (
		command git branch
	)

    set -l git_branches_count (count $git_branches)
    set -l padding 5
    set -l height (math $git_branches_count + $padding)

    echo $git_branches \
        | fzf --multi \
        --height=$height
end
