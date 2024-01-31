status is-interactive; or return 0

# --------------------------------------------------------------------------------------------------
# ideas:
# - Add a way to list all the abbreviations specific to git.fish
# - Print if the hooks are installed or not, or enabled or not (outcommented)
# - have an environment variable/file with the default hooks to install
# - Detect what kind of project it is e.g. python,c++, rust etc
#   and add some hooks specific for the language
#   - python: https://github.com/astral-sh/ruff-pre-commit

# https://github.com/compilerla/conventional-pre-commit
# --------------------------------------------------------------------------------------------------

if not command --query pre-commit
    __git.fish::echo (printf "%spre-commit%s not installed. no hooks will be enabled." (set_color $fish_color_param) (set_color normal))
    return 0
end

# Disable by default
set --query GIT_FISH_PRE_COMMIT_ENABLE; or set --universal GIT_FISH_PRE_COMMIT_ENABLE 0
set --query GIT_FISH_PRE_COMMIT_LIST_HOOKS; or set --universal GIT_FISH_PRE_COMMIT_LIST_HOOKS 0
set --query GIT_FISH_PRE_COMMIT_AUTO_INSTALL; or set --universal GIT_FISH_PRE_COMMIT_AUTO_INSTALL 0

function __git.fish::check_for_pre_commit --on-event in_git_repo_root_directory
    test $GIT_FISH_PRE_COMMIT_ENABLE -eq 1; or return 0
    # Do not want to spam the user with the same message over and over again in the same shell session
    contains -- $PWD (__git.fish::git_dirs_visited); and return 0

    # used to highlight the .pre-commit-config.yaml file when it is printed
    set -l dot_pre_commit_config_yaml (set_color --bold)".pre-commit-config.yaml"(set_color normal)
    # When running on A Fedora Silverblue system, the PWD is /var/home/username
    set -l cwd (string replace --regex "^/var$HOME" "~" -- $PWD | string replace --regex "^$HOME" "~")

    if test -f .pre-commit-config.yaml
        __git.fish::echo "A $dot_pre_commit_config_yaml file was found in $(set_color --bold)$cwd$(set_color normal)"
        if test $GIT_FISH_PRE_COMMIT_LIST_HOOKS -eq 1
            set -l hooks (string match --regex --all --groups-only "[^#]+-\s+id:\s(\S+)\$" < .pre-commit-config.yaml)
            __git.fish::echo "The following hooks are listed:"
            printf " - %s\n" $hooks
        end
        if not test -f ./.git/hooks/pre-commit
            __git.fish::echo "pre-commit hooks not installed. installing..."
            command pre-commit install --install-hooks 2>/dev/null
        else
            __git.fish::echo "pre-commit hooks are installed $(set_color green)✓$(set_color normal)"
        end
    else
        __git.fish::echo "No $dot_pre_commit_config_yaml file found in $(set_color --bold)$cwd$(set_color normal)."
        if test $GIT_FISH_PRE_COMMIT_AUTO_INSTALL -eq 1
            __git.fish::echo (printf "%s\$GIT_FISH_PRE_COMMIT_AUTO_INSTALL%s is set. generating a sample $dot_pre_commit_config_yaml file and installing it..." (set_color $fish_color_param) (set_color normal))
            command pre-commit sample-config | tee .pre-commit-config.yaml && command pre-commit install --install-hooks
            __git.fish::echo "pre-commit hooks installed."
        else
            if command --query bat
                set -f generate_sample_config_command "pre-commit sample-config | tee .pre-commit-config.yaml | bat --language=yaml && pre-commit install"
            else
                set -f generate_sample_config_command "pre-commit sample-config | tee .pre-commit-config.yaml && pre-commit install"
            end
            set -l abbreviation pcg # (p)re-(c)ommit (g)enerate
            __git.fish::echo (printf "A sample $dot_pre_commit_config_yaml file can be generated and installed with: (use the abbreviation %s$abbreviation%s to run it)" (set_color $fish_color_command) (set_color normal))
            printf "\t"
            echo $generate_sample_config_command | fish_indent --ansi
            if not abbr --query $abbreviation
                abbr --add $abbreviation "$generate_sample_config_command"
            end
        end
    end
end
