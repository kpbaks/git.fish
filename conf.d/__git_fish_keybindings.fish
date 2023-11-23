status is-interactive; or return

# Make this feature opt-in
set --query GIT_FISH_GITUI_KEYBIND_ENABLE; or set --universal GIT_FISH_GITUI_KEYBIND_ENABLE 0
test $GIT_FISH_GITUI_KEYBIND_ENABLE = 1; or return
set --query GIT_FISH_GITUI_KEYBIND; or set --universal GIT_FISH_GITUI_KEYBIND \cg
set --query GIT_FISH_GITUI_KEYBIND_QUIET; or set --universal GIT_FISH_GITUI_KEYBIND_QUIET 0

set --local git_ui_command
if command --query gitui
    set git_ui_command gitui
else if command --query lazygit
    set git_ui_command lazygit
else if command --query tig
    set git_ui_command tig
else
    test $GIT_FISH_GITUI_KEYBIND_QUIET = 1
    and __git.fish::echo "no git ui { gitui, lazygit, tig } is installed, no keybinding set"
    return
end

# TODO: <kpbaks 2023-09-13 13:50:52> check if keybinding is already bound, and if so print a warning, and don't override it
# To hard to check. `bind` does not have a `--query` option like `command` does, so we would have to parse the output
# of `bind` which is not trivial.
test $GIT_FISH_GITUI_KEYBIND_QUIET = 0; and __git.fish::echo "$git_ui_command is installed, binding ctrl+g to open $git_ui_command"
bind $GIT_FISH_GITUI_KEYBIND "command $git_ui_command; commandline --function repaint"
