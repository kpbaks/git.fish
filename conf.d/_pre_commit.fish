status is-interactive; or return

if not command --query pre-commit
    _git_fish_echo "pre-commit not installed. no hooks will be enabled."
    return
end

set -g _git_fish_git_directories_visisted

function _git_fish_check_for_pre_commit --on-variable PWD
    test -d .git; or return
    contains -- $PWD $_git_fish_git_directories_visisted; and return

    # used to highlight the .pre-commit-config.yaml file when it is printed
    set -l dot_pre_commit_config_yaml (set_color --bold)".pre-commit-config.yaml"(set_color normal)

    if test -f .pre-commit-config.yaml
        # check if hooks are installed
        if not test -f ./git/hooks/pre-commit
            _git_fish_echo "a $dot_pre_commit_config_yaml file was found."
            if command --query bat
                command bat --plain .pre-commit-config.yaml
            else
                command cat .pre-commit-config.yaml
            end
            _git_fish_echo "pre-commit hooks not installed. installing..."
            pre-commit install
            _git_fish_echo "pre-commit hooks installed."
        else
            _git_fish_echo "pre-commit hooks not installed."
            _git_fish_echo "run `pre-commit install` to install them."
        end
    else
        _git_fish_echo "no $dot_pre_commit_config_yaml file found. skipping..."
        _git_fish_echo "a sample $dot_pre_commit_config_yaml file can be generated with:" (echo "pre-commit sample-config" | fish_indent --ansi)
    end

    # check if we've already visited this directory
    # if not, add it to the list of visited directories
    # this is to prevent annoying the user by asking them again and again in 
    # the same shell session.
    if not contains -- $PWD $_git_fish_git_directories_visisted
        set --append _git_fish_git_directories_visisted $PWD
    end
end
