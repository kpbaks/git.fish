status is-interactive; or return
command --query fzf; or return

set --query GIT_REPOS_VISITED; or set --universal GIT_REPOS_VISITED

# Every time a directory with a .git directory is entered, store it in a universal variable
function _git_repos_visited --on-variable PWD
    test -d .git; or return

    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l normal (set_color normal)
    set -l prefix (printf "%s[git.fish]%s" $git_color $normal)
    if not contains -- $PWD $GIT_REPOS_VISITED
        set --append GIT_REPOS_VISITED $PWD
        set -l git_repos_visited_count (count $GIT_REPOS_VISITED)
        set -l repo_dir (string replace "$HOME" "~" $PWD)
        printf "$prefix added (%s%s%s) to list of visited repos, total: %s%d%s\n" \
            $git_color $repo_dir $normal \
            $git_color $git_repos_visited_count $normal
    end
end


function repos
    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l normal (set_color normal)
    set -l prefix (printf "%s[git.fish]%s" $git_color $normal)
    set -l argc (count $argv)
    if test $argc -eq 1
        set -l verb $argv[1]
        switch $verb
            case clear
                # The easiest way to clear the list of visited repos is to just delete the variable
                # and then recreate it as an empty array.
                set --erase GIT_REPOS_VISITED
                set --universal GIT_REPOS_VISITED
                echo "$prefix cleared list of visited repos"
                return 0
            case list
                if isatty stdout
                    set -l longest_path_length 0
                    for repo in $GIT_REPOS_VISITED
                        set -l repo_length (string length $repo)
                        if test $repo_length -gt $longest_path_length
                            set longest_path_length $repo_length
                        end
                    end

                    # TODO: improve this output
                    # somehow incorporate the local status of the repo
                    # show it like in the neovim statusline with + and - and ~
                    # if the user is in a repo, the highlight it with a different color/or bold it
                    # do not hightlight the https://git{hub,lab}.com/ part of the url
                    # only the user/repo part
                    printf "%s%s%s\n" $git_color "repos visited:" $normal
                    set -l git_repos_visited_count (count $GIT_REPOS_VISITED)
                    # 1 is added to the log10 of the count as the width will have to be
                    # at least 1 more than the log10 of the count e.g. 12 repos will have 2 digits
                    set -l index_width (math "floor(log10($git_repos_visited_count)) + 1")
                    set -l count 0
                    for repo in $GIT_REPOS_VISITED
                        set count (math $count + 1)
                        set -l remote_origin_url (git -C $repo config --get remote.origin.url)
                        set -l repo_length (string length $repo)
                        set -l padding (string repeat --count (math $longest_path_length - $repo_length) ' ')
                        set -l directory_styling --bold
                        if test $repo = $PWD
                            set directory_styling blue --italics
                        end
                        set directory_styling (set_color $directory_styling)

                        printf "%"$index_width"d) " $count
                        printf "%s%s%s%s -> %s%s%s\n" $directory_styling $repo $normal $padding $git_color $remote_origin_url $normal
                    end
                else
                    # for non-interactive shells, just print the list of repos
                    # so it is easier to pipe to other commands
                    for repo in $GIT_REPOS_VISITED
                        echo $repo
                    end
                end
                return 0
            case '*'
                echo "$prefix unknown command: $verb"
                return 1
        end
    end

    # Check to see if all the git directories are still valid
    # If not, remove them from the list
    set -l valid_repos
    for repo in $GIT_REPOS_VISITED
        if test -d $repo -a -d $repo/.git
            set --append valid_repos $repo
        else
            echo "$prefix removing invalid repo: $repo"
        end
    end

    # If there are no valid repos, just return
    # This will prevent the fzf prompt from showing up
    if test 0 -eq (count $valid_repos)
        echo "$prefix no valid repos"
        return 1
    end

    # If there are valid repos, show the fzf prompt
    # If the user selects a repo, cd into it
    # If the user doesn't select a repo, just return

    # fzf delimits items with newlines, so we need to convert the array i.e. transpose it.
    # to be delimited by newlines
    echo $valid_repos | string collect | string split ' ' \
        | command fzf \
        --prompt "git repos > " \
        --height 50% \
        --reverse \
        --ansi \
        --color="border:#f44d27" \
        --preview 'git -C {} status' \
        | read -l selected_repo

    if test -z $selected_repo
        echo "$prefix no repo selected"
        return 0
    end

    set GIT_REPOS_VISITED $valid_repos

    echo "$prefix selected repo: $selected_repo"
    cd $selected_repo
end
