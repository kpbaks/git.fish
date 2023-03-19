status is-interactive; or return

command --query pre-commit; or return

set -g _git_fish_git_directories_visisted

function _git_fish_check_for_pre_commit --on-variable PWD
    test -d .git; or return
    contains -- $PWD $_git_fish_git_directories_visisted; and return

    set -l prefix "[git.fish]"
    set -l git_color "#f44d27" # taken from git's logo

    if test -f .pre-commit-config.yaml
        # check if hooks are installed
        if not test -f ./git/hooks/pre-commit
            printf "%s%s%s %s\n" \
                (set_color $git_color) $prefix (set_color normal) \
                "pre-commit hooks not installed. installing..."
            pre-commit install
            printf "%s%s%s %s\n" \
                (set_color $git_color) $prefix (set_color normal) \
                "pre-commit hooks installed."
        end
    else
        printf "%s%s%s %s\n" \
            (set_color $git_color) $prefix (set_color normal) \
            "pre-commit hooks not installed. skipping..."
    end

    # check if we've already visited this directory
    # if not, add it to the list of visited directories
    # this is to prevent annoying the user by asking them again and again in 
    # the same shell session.
    if not contains -- $PWD $_git_fish_git_directories_visisted
        set --append _git_fish_git_directories_visisted $PWD
    end
end
