function ga -d "Wrapper around `git add`. Part of git.fish"
    set -l options h/help
    if not argparse $options -- $argv
        return 2
    end
    if not command git rev-parse --is-inside-work-tree >/dev/null
        return 2
    end
    if test (count $argv) -ne 0
        command git add $argv
        eval $git_fish_git_status_command
        return 0
    end
    # Interactive fzf
    # Get unstaged files
    # set -l unstaged (command git ls-files --modified)
    # Get staged files
    # set -l staged (command git diff --name-only --cached --diff-filter=AM)
    # Present

    # TODO: what if a file has contents that are both staged and modified?

    set -l fzf_preview "git diff --color=always {2}"
    # set -l git_color (set_color "#f44d27") # taken from git's logo

    # TODO: improve colors
    # TODO: change color of header
    set -l fzf_opts \
        --ansi \
        --multi \
        --border=none \
        --height=85% \
        --reverse \
        --cycle \
        --pointer='|>' \
        --marker='✓ ' \
        --no-mouse \
        --prompt=$prompt \
        --exit-0 \
        --header-first \
        --scroll-off=5 \
        --color='marker:#00ff00' \
        # --color="header:#$fish_color_command" \
        # --color="info:#$fish_color_keyword" \
        # --color="prompt:#$fish_color_autosuggestion" \
        --color='border:#f44d27' \
        --color="gutter:-1" \
        --color="hl:#FFB600" \
        --color="hl+:#FFB600" \
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
    # --header-lines=3 \

    set -l reset (set_color normal)
    set -l blue (set_color blue)

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

    commandline --insert "git add $selected_files"
    # Using --append will not move the cursor to the end of the commandline. The user is more likely
    # to remove one of the selected files, so by having the cursor right after the last of the selected files
    # the cursor is closer, and so it is easier to change.
    commandline --append " && $git_fish_git_status_command"
end
