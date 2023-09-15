status is-interactive; or return

# --------------------------------------------------------------------------------------------------
# ideas:
# - Add a way to list all the abbreviations specific to git.fish
# - Print if the hooks are installed or not, or enabled or not (outcommented)
# - have an environment variable/file with the default hooks to install

# https://github.com/compilerla/conventional-pre-commit
# --------------------------------------------------------------------------------------------------


if not command --query pre-commit
    __git.fish::echo "pre-commit not installed. no hooks will be enabled."
    return
end

set --global _git_fish_git_directories_visisted

function _git_fish_check_for_pre_commit --on-event in_git_repo_root_directory
    # Do not want to spam the user with the same message over and over again in the same shell session
    contains -- $PWD $_git_fish_git_directories_visisted; and return

    # used to highlight the .pre-commit-config.yaml file when it is printed
    set --local dot_pre_commit_config_yaml (set_color --bold)".pre-commit-config.yaml"(set_color normal)
    # When running on A Fedora Silverblue system, the PWD is /var/home/username
    set --local cwd (string replace --regex "^/var$HOME" "~" -- $PWD | string replace --regex "^$HOME" "~")

    if test -f .pre-commit-config.yaml
        __git.fish::echo "A $dot_pre_commit_config_yaml file was found in $(set_color --bold)$cwd$(set_color normal)"
        if set --query GIT_FISH_PRE_COMMIT_LIST_HOOKS
            set --local hooks (string match --regex --all --groups-only "[^#]+-\s+id:\s(\S+)\$" < .pre-commit-config.yaml)
            __git.fish::echo "the following hooks are listed:"
            printf " - %s\n" $hooks
        end
        if not test -f ./.git/hooks/pre-commit
            __git.fish::echo "pre-commit hooks not installed. installing..."
            command pre-commit install --install-hooks 2>/dev/null
            # __git.fish::echo "pre-commit hooks installed."
        else
            __git.fish::echo "pre-commit hooks are installed $(set_color green)✓$(set_color normal)"
            # set --local auto_update_command (echo -n "pre-commit autoupdate" | fish_indent --ansi)
            # __git.fish::echo "to autoupdate them, run: $auto_update_command"
        end
    else
        __git.fish::echo "no $dot_pre_commit_config_yaml file found in $(set_color --bold)$cwd$(set_color normal)."
        if set --query GIT_FISH_PRE_COMMIT_AUTO_INSTALL
            __git.fish::echo "GIT_FISH_PRE_COMMIT_AUTO_INSTALL is set. generating a sample $dot_pre_commit_config_yaml file and installing it..."
            command pre-commit sample-config | tee .pre-commit-config.yaml && command pre-commit install --install-hooks
            __git.fish::echo "pre-commit hooks installed."
        else
            set --local generate_sample_config_command "pre-commit sample-config | tee .pre-commit-config.yaml && pre-commit install"
            set --local abbreviation pcg
            __git.fish::echo (printf "a sample $dot_pre_commit_config_yaml file can be generated and installed with: (use the abbreviation %s$abbreviation%s to run it)" (set_color $fish_color_command) (set_color normal))
            echo -en "\t"
            echo "$generate_sample_config_command" | fish_indent --ansi
            if not abbr --query $abbreviation
                # __git.fish::echo "adding abbreviation: $(set_color --reverse)$abbreviation$(set_color normal) for"
                # echo -en "\t"
                # echo "$generate_sample_config_command" | fish_indent --ansi
                abbr --add $abbreviation "$generate_sample_config_command"
            end
            # __git.fish::echo "the abbreviation $(set_color --reverse)$abbreviation$(set_color normal) can be used to generate a sample $dot_pre_commit_config_yaml file."
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
