status is-interactive; or return 0

for cmd in fzf sqlite3
    if not command --query $cmd
        __git.fish::echo "$cmd not found, $(set_color $fish_color_command)repos$(set_color normal) function will not be available"
        return 0
    end
end

# Create the database if it doesn't exist
# This database will be used to store the last time a repo was visited
set --query git_fish_repos_sqlite3_db
or set --universal git_fish_repos_sqlite3_db $__fish_user_data_dir/git.fish/repos.sqlite3

command mkdir -p (path dirname $git_fish_repos_sqlite3_db)
if not test -f $git_fish_repos_sqlite3_db
    set -l schema "
		CREATE TABLE repos (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			path TEXT UNIQUE NOT NULL,
			timestamp INTEGER,
			number_of_times_visited INTEGER DEFAULT 1
		);
	"
    command sqlite3 $git_fish_repos_sqlite3_db $schema

    printf '%sgit.fish:repos [info]%s: created database at %s\n' (set_color green) (set_color reset) $git_fish_repos_sqlite3_db >&2
end

function __git::repos::add_git_repo_to_db -a dir
    if not test -d $dir
        __git.fish::echo "$dir is not a directory"
        return 1
    end

    if not test -d $dir/.git
        __git.fish::echo "$dir is not a git repo"
        return 1
    end

    set -l now (date +%s)

    # query the database to see if the repo has been visited before
    # if it has, then update the timestamp, and increment the number of times visited
    # if it hasn't, then add it to the database
    set -l query "
		INSERT INTO repos (path, timestamp) VALUES ('$dir', $now)
		ON CONFLICT(path) DO UPDATE SET timestamp=$now, number_of_times_visited=number_of_times_visited+1;
	"
    command sqlite3 $git_fish_repos_sqlite3_db $query

    # set -l git_color (set_color "#f44d27") # taken from git's logo
    set -l git_color (set_color red)
    set -l reset (set_color normal)

    # if the repo has not been visited before, then print a message
    set -l number_of_times_visited (command sqlite3 $git_fish_repos_sqlite3_db "SELECT number_of_times_visited FROM repos WHERE path='$dir';")
    test $number_of_times_visited -eq 1; or return 0

    set -l total_number_of_repos_visited (command sqlite3 $git_fish_repos_sqlite3_db "SELECT COUNT(*) FROM repos;")
    set -l repo_dir (string replace "$HOME" "~" $dir)
    __git.fish::echo (printf "added (%s%s%s) to list of visited repos, total: %s%d%s (use %srepos%s to interact with them)\n" \
			$git_color $repo_dir $reset \
			$git_color $total_number_of_repos_visited $reset \
        (set_color $fish_color_command) $reset)
end

function __git::repos::in_git_repo_root_directory_hook --on-event in_git_repo_root_directory
    # Every time a directory with a .git directory is entered, add that directory to the db
    __git::repos::add_git_repo_to_db $PWD
end

# Intended to be used by the other repos-<command> functions, to check if the database is up to date
function __git::repos::check
    set -l paths (command sqlite3 $git_fish_repos_sqlite3_db "SELECT path FROM repos;")

    # iterate over the list of paths
    # check if the path exists, if it does not then remove it from the database
    set -l repos_to_delete_from_db
    for path in $paths
        if not test -d $path
            set -a repos_to_delete_from_db $path
        end
    end

    test (count $repos_to_delete_from_db) -eq 0; and return 0

    set repos_to_delete_from_db (printf "'%s'\n" $repos_to_delete_from_db | string join ',')
    set -l delete_query "DELETE FROM repos WHERE path IN ($repos_to_delete_from_db);"
    echo $delete_query
    command sqlite3 $git_fish_repos_sqlite3_db $delete_query
    # TODO: the count printed is wrong
    __git.fish::echo (printf "Removed %s%d%s repos from list of visited repos" $git_color (count $repos_to_delete_from_db) $reset)
end

function __git::repos::list -d "list all the git repos that have been visited"
    __git::repos::check

    set -l git_color (set_color red)
    set -l reset (set_color normal)

    set -l github_icon ""
    set -l gitlab_icon ""
    set -l bitbucket_icon ""
    set -l git_icon ""

    set -l select_all_query "SELECT * FROM repos;"

    # TODO: <kpbaks 2023-06-05 21:15:20> add --relative flag to print relative timestamps
    # use `path mtime --relative`
    # TODO: format output as a table similar to `./functions/gbo.fish`

    set -l paths
    set -l timestamps
    set -l number_of_times_visited_list
    command sqlite3 $git_fish_repos_sqlite3_db $select_all_query | while read -d "|" -l id path timestamp number_of_times_visited
        set --append paths $path
        set --append timestamps $timestamp
        set --append number_of_times_visited_list $number_of_times_visited
    end

    set -l longest_path_length 0
    for path in $paths
        set longest_path_length (math "max $longest_path_length,$(string length $path)")
    end


    set -l git_repos_visited_count (count $paths)
    if test $git_repos_visited_count -eq 0
        __git.fish::echo "no repos have been visited"
        return 0
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
    set -l index_width (math "floor(log10($git_repos_visited_count)) + 1")
    set -l count 0
    for repo in $paths
        set count (math $count + 1)
        set -l remote_origin_url (git -C $repo config --get remote.origin.url)
        set -l repo_length (string length $repo)
        set -l padding_amount (math "$longest_path_length - $repo_length + 1")
        # if test $padding_amount -eq 0
        #     set padding_amount 1
        # end
        set -l padding (string repeat --count $padding_amount ' ')
        set -l directory_styling --bold
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

function __git::repos::populate -d "populate the repos database by searching recursively for `.git/` directories from $argv[1]" -a dir
    set -l reset (set_color normal)
    set -l red (set_color red)

    if test (count $argv) -eq 0
        printf '%serror%s: no directory given as argument.\n' $red $reset >&2
        return 2
    end

    if not test -d $dir
        printf '%serror%s: %s is not a directory\n' $red $reset $dir >&2
        return 2
    end


    # FIXME: do not add the same repo twice
    # FIXME: do not add git submodules
    set -l found_git_repos_count 0
    # FIXME: what if `find` is not installed?
    find -type d -name .git -exec dirname {} \; | path resolve | while read -l path
        set -l insert_query "INSERT INTO repos (path, timestamp, number_of_times_visited) VALUES ('$path', strftime('%s', 'now'), 0);"
        command sqlite3 $git_fish_repos_sqlite3_db $insert_query
        set found_git_repos_count (math $found_git_repos_count + 1)
        # TODO: <kpbaks 2023-09-20 20:28:46> highlight the path that they share as a prefix
        printf "- %s\n" $path
    end

    __git.fish::echo "found $found_git_repos_count git repos"
end

function __git::repos::clear -d "clear the db of visited repos"
    # TODO: Add a --select flag to select which repos to clear with fzf
    # or use $argv to select which repos to clear, and then
    # have completion for `repos clear` to show the list of repos, so it is easier to select
    set -l number_of_repos_in_db (command sqlite3 $git_fish_repos_sqlite3_db "SELECT COUNT(*) FROM repos;")
    command sqlite3 $git_fish_repos_sqlite3_db "DELETE FROM repos;"

    switch $number_of_repos_in_db
        case 0
            printf 'no repos have been visited\n'
        case '*'
            printf "cleared all repos from list of visited repos, removed: %d" $number_of_repos_in_db
    end
end

function __git::repos::cd
    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l blue (set_color blue)

    # Update the repos db, so that the user only selects from valid repos
    __git::repos::check

    set -l repos (command sqlite3 $git_fish_repos_sqlite3_db "SELECT * FROM repos ORDER BY timestamp DESC;")
    # If there are no repos, just return,
    # this will prevent the fzf prompt from showing up
    if test (count $repos) -eq 0
        printf '%serror%s: no repos have been visited\n' $red $reset
        return 1
    end

    set -l valid_repos (command sqlite3 $git_fish_repos_sqlite3_db "select path from repos order by timestamp desc;")
    if test (count $valid_repos) -ge 2
        # I often find myself jumping back and forth between two git repositories.
        # By Swapping the first 2 rows of the query you just have to press `enter`
        # to go to git repository you visited before this one ;)
        set -l last_visited_repo $valid_repos[1]
        set valid_repos[1] $valid_repos[2]
        set valid_repos[2] $last_visited_repo
    end

    set -l fzf_opts \
        --prompt "select the git repo to cd into: " \
        --border-label=" $(string upper "repos") " \
        --height 80% \
        --cycle \
        --no-mouse \
        --ansi \
        --header-first \
        --scroll-off=5 \
        --color='marker:#00ff00' \
        --no-scrollbar \
        --color="gutter:-1" \
        --color="hl:#FFB600" \
        --color="hl+:#FFB600" \
        --color="prompt:yellow:italic" \
        --color="label:yellow:bold" \
        --color="pointer:bright-red" \
        --color="preview-border:yellow" \
        --color="info:magenta:dim" \
        --pointer='|>' \
        --bind=ctrl-d:preview-page-down \
        --bind=ctrl-u:preview-page-up \
        --bind=ctrl-f:page-down \
        --bind=ctrl-b:page-up \
        --bind=tab:close \
        --reverse

    # TODO: document in readme
    set --query git_fish_repos_cd_show_preview
    or set --universal git_fish_repos_cd_show_preview 1

    # TODO: document in readme
    set --query git_fish_repos_cd_preview_command
    or set --universal git_fish_repos_cd_preview_command 'git -c color.status=always -C {} status'

    if test $git_fish_repos_cd_show_preview -eq 1
        set -a fzf_opts --preview $git_fish_repos_cd_preview_command
        # TODO: instead of hardcoding the minimum width, use fzf's ability to update the preview window
        # location every time the window is resized
        # I have checked with version `0.46.1` and it is not possible to update the preview window location every time the window is resized :(
        # set -a fzf_opts "--preview-window=right:60%(down)"
        if test $COLUMNS -le 120
            # Terminal is not wide enough to have the preview to the right
            set -a fzf_opts --preview-window=down
        else
            set -a fzf_opts --preview-window=right
        end
    end

    for valid_repo in $valid_repos
        set -l dirname (path dirname $valid_repo)
        printf "%s%s%s/%s\n" $blue $dirname $reset (path basename $valid_repo)
    end | command fzf $fzf_opts \
        | read -l selected_repo

    if test -z $selected_repo
        # User pressed `escape` or terminated the process, i.e. made to selection, so just return
        return 0
    end

    builtin cd $selected_repo
end

# This function is the public interface to the repos functionality
function repos -d "Manage the db of visited git repos" -a subcommand
    set -l options h/help
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l blue (set_color blue)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l bold (set_color --bold)

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow
        # Overall description of the command
        printf "%sManage the db of visited git repos%s\n" $bold $reset
        printf "\n"
        # Usage
        printf "%sUSAGE:%s %s%s%s [OPTIONS] [COMMAND]\n" $section_title_color $reset (set_color $fish_color_command) (status current-command) $reset
        printf "\n"
        # Subcommands
        printf "%sCOMMANDS:%s\n" $section_title_color $reset
        printf "\t%populate%s <DIR>  Populate the repos database by searching recursively for `.git/` directories\n" $green $reset
        printf "\t%sclear%s          Clear the db of visited repos\n" $green $reset
        printf "\t%slist%s           List all the git repos that have been visited\n" $green $reset
        printf "\t%scheck%s          Check if the database is up to date\n" $green $reset
        printf "\t%scd%s             Use fzf to select a visited repo to cd into\n" $green $reset
        printf "\n"
        # Description of the options and flags
        printf "%sOPTIONS:%s\n" $section_title_color $reset
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $green $reset $green $reset
        printf "\n"

        __git::help_footer

        return 0
    end >&2

    if test (count $argv) -eq 0
        printf '%serror%s: no command given\n\n' $red $reset
        eval (status function) --help
        return 2
    end

    switch $argv[1]
        case cd
            __git::repos::cd $argv[2..]
        case clear
            __git::repos::clear $argv[2..]
        case list
            __git::repos::list $argv[2..]
        case check
            __git::repos::check $argv[2..]
        case init
            __git::repos::populate $PWD
        case overview
            echo todo
        case '*'
            printf "%serror%s: unknown command: %s\n\n" $red $reset $verb
            eval (status function) --help
            return 2
    end

    return 0
end
