function gfold
    block --local # don't let the interactive shell interfere
    set -l maxdepth 3
    set -l border_count (math "min($COLUMNS, 80)")
    for dir in (find -maxdepth $maxdepth -type d -name ".git")
        set root_dir (path dirname $dir)
        pushd $root_dir
        set -l remote_url (git config --local --get remote.origin.url)
        string repeat --count $border_count -
        set_color yellow
        echo "repo: $remote_url"
        set_color normal
        git status --short
        popd
    end
end
