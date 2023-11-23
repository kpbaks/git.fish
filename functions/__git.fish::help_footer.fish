function __git.fish::help_footer --description "Print a help footer. This way all help messages are consistent in git.fish"
    set -l github_url https://github.com/kpbaks/git.fish
    set -l star_symbol "⭐"
    set -l reset (set_color normal)
    set -l blue (set_color blue)
    set -l git_color (set_color "#f44d27") # taken from git's logo
    printf "Part of the %sgit.fish%s. A plugin for the %s><>%s shell.\n" $git_color $reset $blue $reset
    printf "See %s%s%s for more information, and if you like it, please give it a %s\n" (set_color --underline cyan) $github_url $reset $star_symbol
end
