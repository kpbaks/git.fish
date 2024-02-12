status is-interactive; or return 0
set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED; or set --universal GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED 0
test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return 0

# TODO: <kpbaks 2023-08-30 17:53:40> implement
# https://github.com/cocogitto/cocogitto
# https://gitmoji.dev/
# https://github.com/orhun/git-cliff

# TODO: use https://github.com/compilerla/conventional-pre-commit

# TODO: move into shared reminders file

function __git.fish::reminders::use-branches --on-event in_git_repo_root_directory
    test $GIT_FISH_REMIND_ME_TO_USE_BRANCHES_ENABLED -eq 1; or return 0
    # functions/gbo.fish
    gbo --unchecked # We already know that we are in a git repo
end
