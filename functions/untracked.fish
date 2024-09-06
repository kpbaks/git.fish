function untracked -d "list files untracked by git"
    if isatty stdout
        set -l reset (set_color normal)
        set -l dim (set_color --dim)
        set -l dimyellow (set_color yellow --dim)

        command git ls-files --others --exclude-standard | while read f
            set -l dirname (path dirname $f)
            if test $dirname != .
                printf '%s%s%s/' $dim $dirname $reset
            end
            printf '%s%s%s\n' $dimyellow (path basename $f) $reset
        end

    else
        command git ls-files --others --exclude-standard
    end
end
