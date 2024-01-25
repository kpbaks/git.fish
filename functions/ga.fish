function ga
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

    # TODO: improve colors
    set -l fzf_opts \
        --ansi \
        --multi \
        --height=80% \
        --reverse \
        --preview="$fzf_preview"
    set -l reset (set_color normal)
    set -l blue (set_color blue)

    set -l selected_files (
        command git -c color.status=always status --short \
        | while read modification_status file_path
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
