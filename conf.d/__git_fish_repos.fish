# --------------------------------------------------------------------------------------------------
# description:
# external dependencies:
# - fzf
# - git
# - sqlite3
# ideas:
# - create a separate cli in rust for this
# --------------------------------------------------------------------------------------------------
status is-interactive; or return

for cmd in fzf sqlite3
    if not command --query $cmd
        __git.fish::echo "$cmd not found, $(set_color $fish_color_command)repos$(set_color normal) function will not be available"
        return
    end
end

# Create the database if it doesn't exist
# This database will be used to store the last time a repo was visited
set --query GIT_FISH_REPOS_DB; or set --universal GIT_FISH_REPOS_DB $__fish_user_data_dir/git.fish/repos.sqlite3

mkdir -p (path dirname $GIT_FISH_REPOS_DB)
if not test -f $GIT_FISH_REPOS_DB
    set --local schema "
		CREATE TABLE repos (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			path TEXT UNIQUE NOT NULL,
			timestamp INTEGER,
			number_of_times_visited INTEGER DEFAULT 1
		);
	"
    command sqlite3 $GIT_FISH_REPOS_DB $schema
    __git.fish::echo "created database at $GIT_FISH_REPOS_DB"
end

function __git.fish::repos::add_git_repo_to_db --argument-names dir
    if not argparse --min-args 1 --max-args 1 -- $argv
        __git.fish::echo "usage: $(status function) <path>"
        return 1
    end

    if not test -d $dir
        __git.fish::echo "$dir is not a directory"
        return 1
    end

    if not test -d $dir/.git
        __git.fish::echo "$dir is not a git repo"
        return 1
    end

    set --local now (date +%s)

    # query the database to see if the repo has been visited before
    # if it has, then update the timestamp, and increment the number of times visited
    # if it hasn't, then add it to the database
    set --local query "
		INSERT INTO repos (path, timestamp) VALUES ('$dir', $now)
		ON CONFLICT(path) DO UPDATE SET timestamp=$now, number_of_times_visited=number_of_times_visited+1;
	"
    command sqlite3 $GIT_FISH_REPOS_DB $query

    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local reset (set_color normal)

    # if the repo has not been visited before, then print a message
    set --local number_of_times_visited (command sqlite3 $GIT_FISH_REPOS_DB "SELECT number_of_times_visited FROM repos WHERE path='$dir';")
    test $number_of_times_visited -eq 1; or return

    set --local total_number_of_repos_visited (command sqlite3 $GIT_FISH_REPOS_DB "SELECT COUNT(*) FROM repos;")
    set --local repo_dir (string replace "$HOME" "~" $dir)
    __git.fish::echo (printf "added (%s%s%s) to list of visited repos, total: %s%d%s\n" \
			$git_color $repo_dir $reset \
			$git_color $total_number_of_repos_visited $reset)
end

# Every time a directory with a .git directory is entered, store it in a universal variable
function __git.fish::repos::in_git_repo_root_directory_hook --on-event in_git_repo_root_directory
    __git.fish::repos::add_git_repo_to_db $PWD
end

# Intended to be used by the other repos-<command> functions, to check if the database is up to date
function __git.fish::repos::check
    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local reset (set_color normal)

    set --local select_all_query "SELECT path FROM repos;"
    set --local paths (command sqlite3 $GIT_FISH_REPOS_DB $select_all_query)

    # iterate over the list of paths
    # check if the path exists, if it does not then remove it from the database
    set --local repos_removed 0
    set --local repos_to_delete_from_db
    for path in $paths
        if not test -d $path
            set --append repos_to_delete_from_db $path
        end
    end

    # print how many repos were removed
    set --local repos_deleted_count (count $repos_to_delete_from_db)
    test $repos_deleted_count -eq 0; and return
    set --local delete_query "DELETE FROM repos WHERE path IN ($(string join ',' $repos_to_delete_from_db));"
    echo $delete_query
    return
    command sqlite3 $GIT_FISH_REPOS_DB $delete_query

    __git.fish::echo (printf "Removed %s%d%s repos from list of visited repos" $git_color $repos_deleted_count $reset)
end

function __git.fish::repos::list --description "list all the git repos that have been visited"
    __git.fish::repos::check

    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local reset (set_color normal)

    set --local github_icon ""
    set --local gitlab_icon ""
    set --local bitbucket_icon ""
    set --local git_icon ""

    set --local select_all_query "SELECT * FROM repos;"

    # TODO: <kpbaks 2023-06-05 21:15:20> add --relative flag to print relative timestamps
    # use `path mtime --relative`

    set --local paths
    set --local timestamps
    set --local number_of_times_visited_list
    command sqlite3 $GIT_FISH_REPOS_DB $select_all_query | while read -d "|" -l id path timestamp number_of_times_visited
        set --append paths $path
        set --append timestamps $timestamp
        set --append number_of_times_visited_list $number_of_times_visited
    end

    set --local longest_path_length 0
    for path in $paths
        set longest_path_length (math "max $longest_path_length,$(string length $path)")
    end


    set --local git_repos_visited_count (count $paths)
    if test $git_repos_visited_count -eq 0
        __git.fish::echo "no repos have been visited"
        return
    end

    # TODO: improve this output
    # somehow incorporate the local status of the repo
    # show it like in the neovim statusline with + and - and ~
    # if the user is in a repo, the highlight it with a different color/or bold it
    # do not hightlight the https://git{hub,lab}.com/ part of the url
    # only the user/repo part
    # highlight the repos owned by the user, in a different color
    printf "%s%d repo%s visited%s\n" $git_color $git_repos_visited_count (test $git_repos_visited_count -eq 1; and echo ""; or echo "s") $reset
    # 1 is added to the log10 of the count as the width will have to be
    # at least 1 more than the log10 of the count e.g. 12 repos will have 2 digits
    set --local index_width (math "floor(log10($git_repos_visited_count)) + 1")
    set --local count 0
    for repo in $paths
        set count (math $count + 1)
        set --local remote_origin_url (git -C $repo config --get remote.origin.url)
        set --local repo_length (string length $repo)
        set --local padding_amount (math "$longest_path_length - $repo_length + 1")
        # if test $padding_amount -eq 0
        #     set padding_amount 1
        # end
        set --local padding (string repeat --count $padding_amount ' ')
        set --local directory_styling --bold
        # Highlight the repo if it is the current directory
        if test $repo = $PWD
            set directory_styling blue --italics
        end
        set directory_styling (set_color $directory_styling)

        #NOTE: <kpbaks 2023-05-21 22:29:44> Under system running SilverBlue the $HOME is /var/home/$USER
        set repo (string replace --regex "^/var$HOME" "~" $repo | string replace --regex "^$HOME" "~")

        printf "%"$index_width"d) " $count

        # TODO: <kpbaks 2023-06-05 21:20:59> inspect the remote origin url and print the appropriate icon
        # if it is a github repo, print the github icon
        # if it is a gitlab repo, print the gitlab icon
        # if it is a bitbucket repo, print the bitbucket icon


        printf "%s%s%s%s -> %s%s%s\n" $directory_styling $repo $reset $padding $git_color $remote_origin_url $reset
    end
end

function __git.fish::repos::init --description "Initialize the repos database by searching recursely from \$argv[1]"
    if not argparse --min-args 1 --max-args 1 -- $argv
        return 1
    end

    if not test -d $argv[1]
        __git.fish::echo (printf "%s is not a directory" $argv[1])
        return 1
    end

    set --local found_git_repos_count 0
    find -type d -name .git -exec dirname {} \; | path resolve | while read -l path
        set --local insert_query "INSERT INTO repos (path, timestamp, number_of_times_visited) VALUES ('$path', strftime('%s', 'now'), 0);"
        command sqlite3 $GIT_FISH_REPOS_DB $insert_query
        set found_git_repos_count (math $found_git_repos_count + 1)
        # TODO: <kpbaks 2023-09-20 20:28:46> highlight the path that they share as a prefix
        printf "- %s\n" $path
    end

    __git.fish::echo "found $found_git_repos_count git repos"
end

function __git.fish::repos::clear --description "clear the list of visited repos"
    # TODO: <kpbaks 2023-09-20 20:32:12> add a --select flag to select which repos to clear with fzf
    # TODO: <kpbaks 2023-09-20 20:32:37> or use $argv to select which repos to clear, and then
    # have completion for `repos clear` to show the list of repos, so it is easier to select
    set --local number_of_repos_in_db (command sqlite3 $GIT_FISH_REPOS_DB "SELECT COUNT(*) FROM repos;")
    command sqlite3 $GIT_FISH_REPOS_DB "DELETE FROM repos;"
    switch $number_of_repos_in_db
        case 0
            __git.fish::echo "no repos have been visited"
        case 1
            __git.fish::echo "cleared the 1 repo from list of visited repos"
        case '*'
            __git.fish::echo (printf "cleared all %d repos from list of visited repos" $number_of_repos_in_db)
    end
end

# This function is the public interface to the repos functionality
function repos --description "manage the list of visited repos"
    set --local git_color (set_color "#f44d27") # taken from git's logo
    set --local normal (set_color normal)
    set --local prefix (printf "%s[git.fish]%s" $git_color $normal)

    set --local options (fish_opt --short h --long help)
    if not argparse $options -- $argv
        return 1
    end

    if set --query _flag_help
        # TODO: <kpbaks 2023-09-20 20:33:11> improve the help message
        echo "usage: repos [init|clear|list|check]"
        return 0
    end

    set --local argc (count $argv)
    if test $argc -eq 1
        set --local verb $argv[1]
        switch $verb
            case clear
                __git.fish::repos::clear
                return 0
            case list
                __git.fish::repos::list
                return 0
            case check
                __git.fish::repos::check
                return 0
            case init
                __git.fish::repos::init $PWD
                return 0
            case '*'
                __git.fish::echo "Unknown command: $verb"
                return 1
        end
    end

    # update the repos db, so that the user only selects from valid repos
    __git.fish::repos::check

    # TODO: <kpbaks 2023-09-20 20:33:37> add a flag to control the sorting of the repos, e.g. by timestamp, or by number of times visited
    # and if it is ascending or descending
    set --local select_all_query "SELECT * FROM repos ORDER BY timestamp DESC;"
    set --local repos (command sqlite3 $GIT_FISH_REPOS_DB $select_all_query)
    # if there are no repos, just return
    # this will prevent the fzf prompt from showing up
    if test (count $repos) -eq 0
        __git.fish::echo "no repos have been visited"
        return 1
    end

    set --local valid_repos (command sqlite3 $GIT_FISH_REPOS_DB "select path from repos order by timestamp desc;")

    # fzf delimits items with newlines, so we need to convert the array i.e. transpose it.
    # to be delimited by newlines
    # TODO: <kpbaks 2023-09-16 13:58:19> improve the visuals of the fzf prompt
    # see kpbaks/fuzzy-file.fish for inspiration
    # TODO: <kpbaks 2023-09-20 18:06:08> make the preview command configurable with a variable
    # TODO: <kpbaks 2023-09-20 20:04:32> create keybind to open remote origin url in browser
    printf "%s\n" $valid_repos \
        | command fzf \
        --prompt "$git_icon select the git repo to cd into: " \
        --border-label=" $(string upper "repos") " \
        --height 80% \
        --cycle \
        --no-mouse \
        --header-first \
        --scroll-off=5 \
        --color='marker:#00ff00' \
        --color='border:#F80069' \
        --no-scrollbar \
        --color="gutter:-1" \
        --color="hl:#FFB600" \
        --color="hl+:#FFB600" \
        --pointer='|>' \
        --bind=ctrl-d:preview-page-down \
        --bind=ctrl-u:preview-page-up \
        --bind=ctrl-f:page-down \
        --bind=ctrl-b:page-up \
        --reverse \
        --color="border:#f44d27" \
        --preview 'git -c color.status=always -C {} status' \
        | read -l selected_repo

    if test -z $selected_repo
        __git.fish::echo "No repo selected. Staying right here 😊"
        return 0
    end

    __git.fish::echo "Changing directory to selected repo: $selected_repo"
    cd $selected_repo
end
