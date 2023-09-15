status is-interactive; or return

# Make this feature opt-in
set --query GIT_FISH_GITUI_KEYBIND_ENABLE; or set --universal GIT_FISH_GITUI_KEYBIND_ENABLE 0
test $GIT_FISH_GITUI_KEYBIND_ENABLE = 1; or return
set --query GIT_FISH_GITUI_KEYBIND; or set --universal GIT_FISH_GITUI_KEYBIND \cg
set --query GIT_FISH_GITUI_KEYBIND_QUIET; or set --universal GIT_FISH_GITUI_KEYBIND_QUIET 0

# TODO: <kpbaks 2023-09-13 13:50:52> check if keybinding is already bound, and if so print a warning, and don't override it

if command --query gitui,
	bind $GIT_FISH_GITUI_KEYBIND 'command gitui; commandline --function repaint'
    test $GIT_FISH_GITUI_KEYBIND_QUIET = 1; and __git.fish::echo "gitui is installed, binding ctrl+g to open gitui"
else if command --query lazygit
    __git.fish::echo "lazygit is installed, binding ctrl+g to open lazygit"
    test $GIT_FISH_GITUI_KEYBIND_QUIET = 1; and __git.fish::echo "lazygit is installed, binding ctrl+g to open lazygit"
else if command --query tig
    __git.fish::echo "tig is installed, binding ctrl+g to open tig"
	test $GIT_FISH_GITUI_KEYBIND_QUIET = 1; and __git.fish::echo "tig is installed, binding ctrl+g to open tig"
else
    # __git.fish::echo "no git ui is installed, binding ctrl+g to open gitk"
    test $GIT_FISH_GITUI_KEYBIND_QUIET = 1
    and __git.fish::echo "no git ui is installed, no keybinding set"
end
