function __git.fish::echo
    printf "%s[git.fish]%s %s\n" (set_color red) (set_color normal) "$argv" >&2
end
