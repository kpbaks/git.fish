function __git.fish::echo
    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local reset (set_color normal)
    set --local prefix (printf "%s[git.fish]%s" $git_color $reset)
    echo "$prefix $argv" >&2
end
