function _git_fish_echo
    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l normal (set_color normal)
    set -l prefix (printf "%s[git.fish]%s" $git_color $normal)
    echo "$prefix $argv"
end
