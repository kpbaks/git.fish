function cached
    if isatty stdout
        set -l reset (set_color normal)
        set -l dim (set_color --dim)
        set -l bcyan (set_color cyan --bold)

        command git ls-files --cached | while read f
            set -l dirname (path dirname $f)
            if test $dirname = .
                echo $f
            else
                printf '%s%s%s/%s%s%s\n' $dim $dirname $reset $bcyan (path basename $f) $reset
            end
        end
    else
        command git ls-files --cached
    end
end
