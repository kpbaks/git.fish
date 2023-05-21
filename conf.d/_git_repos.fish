# --------------------------------------------------------------------------------------------------
# description:
# external dependencies:
# - fzf
# - git
# - sqlite3
# ideas:
# - Sort the list of repos by the last time they were visited 2023-05-11 12:57:58
# --------------------------------------------------------------------------------------------------
status is-interactive; or return

for cmd in fzf sqlite3
    if not command --query $cmd
        _git_fish_echo "$cmd not found, $(set_color --bold)repos$(set_color normal) function will not be available"
        return
    end
end

# Create the database if it doesn't exist
# This database will be used to store the last time a repo was visited
set --query GIT_FISH_REPOS_DB; or set --universal GIT_FISH_REPOS_DB $__fish_user_data_dir/git.fish/repos.sqlite3

mkdir -p (dirname $GIT_FISH_REPOS_DB)
if not test -f $GIT_FISH_REPOS_DB
    set -l schema "
		CREATE TABLE repos (
			path TEXT PRIMARY KEY,
			timestamp INTEGER,
			number_of_times_visited INTEGER DEFAULT 1
		);
	"
    sqlite3 $GIT_FISH_REPOS_DB $schema
end



# Every time a directory with a .git directory is entered, store it in a universal variable
function _git_repos_visited --on-event in_git_repo_root_directory
    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l reset (set_color normal)
    # query the database to see if the repo has been visited before
    # if it has, then update the timestamp, and increment the number of times visited
    # if it hasn't, then add it to the database
    set -l unix_timestamp (date +%s)
    set -l query "
		INSERT INTO repos (path, timestamp) VALUES ('$PWD', $unix_timestamp)
		ON CONFLICT(path) DO UPDATE SET timestamp=$unix_timestamp, number_of_times_visited=number_of_times_visited+1;
	"
    sqlite3 $GIT_FISH_REPOS_DB $query

    # if the repo has not been visited before, then print a message
    begin
        set -l query "SELECT number_of_times_visited FROM repos WHERE path='$PWD';"
        set -l number_of_times_visited (sqlite3 $GIT_FISH_REPOS_DB $query)
        if test $number_of_times_visited -eq 1
            set -l total_number_of_repos_visited (sqlite3 $GIT_FISH_REPOS_DB "SELECT COUNT(*) FROM repos;")
            set -l repo_dir (string replace "$HOME" "~" $PWD)
            _git_fish_echo (printf "added (%s%s%s) to list of visited repos, total: %s%d%s\n" \
				$git_color $repo_dir $reset \
				$git_color $total_number_of_repos_visited $reset)
        end
    end

    # if not contains -- $PWD $GIT_REPOS_VISITED
    #     set --append GIT_REPOS_VISITED $PWD
    #     set -l git_repos_visited_count (count $GIT_REPOS_VISITED)
    #     set -l repo_dir (string replace "$HOME" "~" $PWD)
    #     _git_fish_echo (printf "added (%s%s%s) to list of visited repos, total: %s%d%s\n" \
    #         $git_color $repo_dir $reset \
    #         $git_color $git_repos_visited_count $reset)
    # end
end

function repos-list --description "list all the git repos that have been visited"
    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l reset (set_color normal)

    set -l select_all_query "SELECT * FROM repos;"

    if not isatty stdout
        # for non-interactive shells, just print the list of repos
        # so it is easier to pipe to other commands
        sqlite3 $GIT_FISH_REPOS_DB $select_all_query | while read -l path timestamp number_of_times_visited
            set -l repo_dir (string replace "$HOME" "~" $path)
            printf "%s %d %d\n" $repo_dir $timestamp $number_of_times_visited
        end
    else
        set -l paths
        set -l timestamps
        set -l number_of_times_visited_list
        sqlite3 $GIT_FISH_REPOS_DB $select_all_query | while read -l path timestamp number_of_times_visited
            set --append paths $path
            set --append timestamps $timestamp
            set --append number_of_times_visited_list $number_of_times_visited
        end

        set -l longest_path_length 0
        for repo in $paths
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
        printf "%s%s%s\n" $git_color "repos visited:" $reset

        set -l git_repos_visited_count (count $paths)

        # 1 is added to the log10 of the count as the width will have to be
        # at least 1 more than the log10 of the count e.g. 12 repos will have 2 digits
        set -l index_width (math "floor(log10($git_repos_visited_count)) + 1")
        set -l count 0
        for repo in $paths
            set count (math $count + 1)
            set -l remote_origin_url (git -C $repo config --get remote.origin.url)
            set -l repo_length (string length $repo)
            set -l padding (string repeat --count (math $longest_path_length - $repo_length) ' ')
            set -l directory_styling --bold
            if test $repo = $PWD
                set directory_styling blue --italics
            end
            set directory_styling (set_color $directory_styling)

            #NOTE: <kpbaks 2023-05-21 22:29:44> Under system running SilverBlue the $HOME is /var/home/$USER
            set repo (string replace --regex "^/var$HOME" "~" $repo | string replace --regex "^$HOME" "~")

            printf "%"$index_width"d) " $count

            printf "%s%s%s%s -> %s%s%s\n" $directory_styling $repo $reset $padding $git_color $remote_origin_url $reset
        end

    end
end

function repos-clear --description "clear the list of visited repos"
    set -l query "DELETE FROM repos;"
    sqlite3 $GIT_FISH_REPOS_DB $query
    _git_fish_echo "cleared list of visited repos"
end


function repos
    set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l normal (set_color normal)
    set -l prefix (printf "%s[git.fish]%s" $git_color $normal)
    set -l github_icon ""
    set -l gitlab_icon ""
    set -l bitbucket_icon ""
    set -l git_icon ""

    set -l argc (count $argv)
    if test $argc -eq 1
        set -l verb $argv[1]
        switch $verb
            case clear
                repos-clear
                return 0
            case list
                repos-list
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
        --prompt "$git_icon git repos > " \
        --height 80% \
        --reverse \
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
