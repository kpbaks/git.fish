status is-interactive; or return

if not command --query pre-commit
    _git_fish_echo "pre-commit not installed. no hooks will be enabled."
    return
end

set -g _git_fish_git_directories_visisted

function _git_fish_check_for_pre_commit --on-event in_git_repo_root_directory
    contains -- $PWD $_git_fish_git_directories_visisted; and return

    # used to highlight the .pre-commit-config.yaml file when it is printed
    set -l dot_pre_commit_config_yaml (set_color --bold)".pre-commit-config.yaml"(set_color normal)
    # When running on A Fedora Silverblue system, the PWD is /var/home/username
    set -l cwd (string replace --regex "^/var$HOME" "~" -- $PWD | string replace --regex "^$HOME" "~")

    if test -f .pre-commit-config.yaml
        _git_fish_echo "a $dot_pre_commit_config_yaml file was found in $(set_color --bold)$cwd$(set_color normal)"
        set -l hooks (string match --regex --all --groups-only "\s+-\s+id:\s(\S+)\$" < .pre-commit-config.yaml)
        _git_fish_echo "the following hooks are listed:"
        printf " - %s\n" $hooks
        # if command --query bat
        #     command bat --plain .pre-commit-config.yaml
        # else
        #     command cat .pre-commit-config.yaml
        # end
        # check if hooks are installed
        if not test -f ./.git/hooks/pre-commit
            _git_fish_echo "pre-commit hooks not installed. installing..."
            command pre-commit install --install-hooks 2>/dev/null
            # _git_fish_echo "pre-commit hooks installed."
        else
            _git_fish_echo "pre-commit hooks installed."
            # set -l auto_update_command (echo -n "pre-commit autoupdate" | fish_indent --ansi)
            # _git_fish_echo "to autoupdate them, run: $auto_update_command"
        end
    else
        _git_fish_echo "no $dot_pre_commit_config_yaml file found in $(set_color --bold)$cwd$(set_color normal)."
        if set --query GIT_FISH_PRE_COMMIT_AUTO_INSTALL
            _git_fish_echo "GIT_FISH_PRE_COMMIT_AUTO_INSTALL is set. generating a sample $dot_pre_commit_config_yaml file and installing it..."
            command pre-commit sample-config | tee .pre-commit-config.yaml && command pre-commit install --install-hooks
            _git_fish_echo "pre-commit hooks installed."
        else
            set -l generate_sample_config_command "pre-commit sample-config | tee .pre-commit-config.yaml && pre-commit install"
            set -l abbreviation pcg
            _git_fish_echo "a sample $dot_pre_commit_config_yaml file can be generated and installed with: (use the abbreviation `$abbreviation` to run it)"
            echo -en "\t"
            echo "$generate_sample_config_command" | fish_indent --ansi
            if not abbr --query $abbreviation
                # _git_fish_echo "adding abbreviation: $(set_color --reverse)$abbreviation$(set_color normal) for"
                # echo -en "\t"
                # echo "$generate_sample_config_command" | fish_indent --ansi
                abbr --add $abbreviation "$generate_sample_config_command"
            end
            # _git_fish_echo "the abbreviation $(set_color --reverse)$abbreviation$(set_color normal) can be used to generate a sample $dot_pre_commit_config_yaml file."
        end
    end

    # check if we've already visited this directory
    # if not, add it to the list of visited directories
    # this is to prevent annoying the user by asking them again and again in
    # the same shell session.
    if not contains -- $PWD $_git_fish_git_directories_visisted
        set --append _git_fish_git_directories_visisted $PWD
    end
end
