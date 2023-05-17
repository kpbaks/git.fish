status is-interactive; or return

function __remind_me_to_use_branches --on-event in_git_repo_root_directory
    set -l branches (git branch --list --no-color)
    set -l current_branch (git rev-parse --abbrev-ref HEAD)
    set --query GIT_FISH_REMIND_ME_TO_USE_BRANCHES_DISABLED; and return

    if contains -- $current_branch main master
        set -l normal (set_color normal)
        _git_fish_echo (printf "You are on the %s%s%s branch. You should be on a %sfeature%s branch!" \
			(set_color yellow) $current_branch $normal (set_color green) $normal)
    end

    # Does the current branch have a remote?
    # If so, is it ahead or behind the remote?
    # If so, how many commits?
    # If so, how long ago was the last commit?
    # If so, who was the last committer?
    # If so, what was the last commit message?
    # If so, what is the remote URL?
    # If so, what is the remote name?
    # If so, what is the remote branch name?
    # If so, what is the remote branch URL?

    _git_fish_echo "The following branches exist:"

    set -l field_delimiter '#'
    set -l output_separator '|'
    # | column -t -s $field_delimiter --table-header --output-separator $output_separator
    set -l branches
    set -l contents
    set -l committerdates
    set -l authors
    git branch --format="%(HEAD) %(refname:short) $field_delimiter %(contents:subject) $field_delimiter %(committerdate:relative) $field_delimiter %(authorname)" --sort=-committerdate \
        | while read --delimiter $field_delimiter branch content committerdate author
        set --append branches (string trim -- $branch)
        set --append contents (string trim -- $content)
        set --append committerdates (string trim -- $committerdate)
        set --append authors (string trim -- $author)
    end

    set -l longest_branch ""
    set -l length_of_longest_branch 0
    for branch in $branches
        if test (string length $branch) -gt (string length $longest_branch)
            set longest_branch $branch
            set length_of_longest_branch (string length $branch)
        end
    end
    set -l longest_content ""
    set -l length_of_longest_content 0
    for content in $contents
        if test (string length $content) -gt (string length $longest_content)
            set longest_content $content
            set length_of_longest_content (string length $content)
        end
    end
    set -l longest_committerdate ""
    set -l length_of_longest_committerdate 0
    for committerdate in $committerdates
        if test (string length $committerdate) -gt (string length $longest_committerdate)
            set longest_committerdate $committerdate
            set length_of_longest_committerdate (string length $committerdate)
        end
    end
    set -l longest_author ""
    set -l length_of_longest_author 0
    for author in $authors
        if test (string length $author) -gt (string length $longest_author)
            set longest_author $author
            set length_of_longest_author (string length $author)
        end
    end

    set -l normal (set_color normal)
    set -l branch_color (set_color yellow)
    set -l content_color (set_color green)
    set -l committerdate_color (set_color blue)
    set -l author_color (set_color red)

    for i in (seq (count $authors))
        set -l branch $branches[$i]
        set -l content $contents[$i]
        set -l committerdate $committerdates[$i]
        set -l author $authors[$i]

        set -l branch_length (string length $branch)
        set -l content_length (string length $content)
        set -l committerdate_length (string length $committerdate)
        set -l author_length (string length $author)
        set -l branch_padding (string repeat --count (math "$length_of_longest_branch - $branch_length") " ")
        set -l content_padding (string repeat --count (math "$length_of_longest_content - $content_length") " ")
        set -l committerdate_padding (string repeat --count (math "$length_of_longest_committerdate - $committerdate_length") " ")
        set -l author_padding (string repeat --count (math "$length_of_longest_author - $author_length") " ")

        set -l branch "$branch$branch_padding"
        set -l content "$content$content_padding"
        set -l committerdate "$committerdate$committerdate_padding"
        set -l author "$author$author_padding"

        #       echo "branch: $branch"
        # echo "content: $content"
        # echo "committerdate: $committerdate"
        # echo "author: $author"

        printf "%s %s%s%s %s %s%s%s %s %s%s%s %s %s%s%s" \
            $output_separator \
            $branch_color $branch $normal \
            $output_separator \
            $content_color $content $normal \
            $output_separator \
            $committerdate_color $committerdate $normal \
            $output_separator \
            $author_color $author $normal
        printf " |\n"
    end


end
