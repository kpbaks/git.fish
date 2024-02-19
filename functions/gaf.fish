function gaf -d "fzf wrapper around `git add`"
    set -l options h/help e/expand
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    if set --query _flag_help
        printf '%sfzf wrapper around %s%s\n' $bold (printf (echo "git add" | fish_indent --ansi)) $reset
        printf '\n'
        printf '%sUSAGE%s: %s%s%s [OPTIONS]\n' $yellow $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS%s:\n' $yellow $reset
        printf '\t%s-h%s, %s--help%s    Show this help message and exit\n' $green $reset $green $reset
        printf '\t%s-e%s, %s--expand%s  Expand selection to %s%s in your commandline\n' $green $reset $green $reset (printf (echo "git add ..." | fish_indent --ansi)) $reset
        printf '\n'
        __git::help_footer
        return 0
    end >&2

    if not command git rev-parse --is-inside-work-tree 2>/dev/null >&2
        printf "%serror:%s not inside a git repository\n" $red $reset >&2
        return 2
    end

    # TODO: what if a file has contents that are both staged and modified?

    # use difft if installed
    # if command --query difft
    #     set -f fzf_preview 'GIT_EXTERNAL_DIFF=difft git diff --color=always --ext-diff {2}'
    # else
    # end
    set -f fzf_preview "git diff --color=always {2}"

    set -l fzf_opts \
        --ansi \
        --multi \
        # --height=~75% \
        --height=75% \
        --reverse \
        --cycle \
        --pointer='|>' \
        --marker='✓ ' \
        --no-mouse \
        --prompt=$prompt \
        --exit-0 \
        --header-first \
        --scroll-off=5 \
        # --color='marker:#00ff00' \
        --color='marker:green' \
        # --color="header:#$fish_color_command" \
        # --color="info:#$fish_color_keyword" \
        # --color="prompt:#$fish_color_autosuggestion" \
        --color="gutter:-1" \
        --color="prompt:yellow:italic" \
        --color="label:yellow:bold" \
        --color="header:green:bold" \
        --color="preview-border:yellow" \
        --color="info:blue:dim" \
        --color="hl:yellow" \
        # --color="hl:#FFB600" \
        # --color="hl+:#FFB600" \
        --color="hl+:yellow:bold" \
        --no-scrollbar \
        --bind=ctrl-a:select-all \
        --bind=ctrl-z:deselect-all \
        --bind=ctrl-d:preview-page-down \
        --bind=ctrl-u:preview-page-up \
        --bind=ctrl-f:page-down \
        --bind=ctrl-b:page-up \
        --border-label=" $(string upper "git.fish") " \
        --header="Select which modified files to stage. <ctrl-a> to select all. <ctrl-z> to deselect all" \
        --preview="$fzf_preview"

    set -l selected_files (
        command git -c color.status=always status --short \
        | while read modification_status file_path
            # TODO: align both columns properly
            set -l dirname (path dirname $file_path)
            if test $dirname = "."
                printf "%s\t%s\n" $modification_status $file_path
            else
                printf "%s\t%s%s%s/%s\n" $modification_status $blue $dirname $reset (path basename $file_path)
            end
        end \
        | command fzf $fzf_opts \
        | string replace --regex "^[AM\?]{1,2}\s+" ""
    )
    if test (count $selected_files) -eq 0
        return 0
    end

    if set --query _flag_expand
        commandline --insert "git add $selected_files"
        # Using --append will not move the cursor to the end of the commandline. The user is more likely
        # to remove one of the selected files, so by having the cursor right after the last of the selected files
        # the cursor is closer, and so it is easier to change.
        commandline --append $__and_git_status
    else
        command git add $selected_files
    end
end
