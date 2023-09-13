status is-interactive; or return

# Make this feature opt-in
set --query GIT_FISH_GITUI_KEYBIND_ENABLE; or set --universal GIT_FISH_GITUI_KEYBIND_ENABLE 0
test "$GIT_FISH_GITUI_KEYBIND_ENABLE" = 1; or return

if command --query gitui,
    __git.fish::echo "gitui is installed, binding ctrl+g to open gitui"
    bind \cg 'gitui; commandline -f repaint'
else if command --query lazygit
    __git.fish::echo "lazygit is installed, binding ctrl+g to open lazygit"
    bind \cg 'lazygit; commandline -f repaint'
else if command --query tig
    __git.fish::echo "tig is installed, binding ctrl+g to open tig"
    bind \cg 'tig; commandline -f repaint'
else
    __git.fish::echo "no git ui is installed, binding ctrl+g to open gitk"
end
