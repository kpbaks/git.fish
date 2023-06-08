status is-interactive; or return

if command --query lazygit
    _git_fish_echo "lazygit is installed, binding ctrl+g to open lazygit"
    bind \cg lazygit
else if command --query gitui,
    _git_fish_echo "gitui is installed, binding ctrl+g to open gitui"
    bind \cg gitui
else if command --query tig
    _git_fish_echo "tig is installed, binding ctrl+g to open tig"
    bind \cg tig
else
    # _git_fish_echo "no git ui is installed, binding ctrl+g to open gitk"
end
