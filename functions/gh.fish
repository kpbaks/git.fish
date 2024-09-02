function gh
    # If user in an interactive shell, types `gh repo create` and
    # successfully creates a repo and says yes in the dialog to clone
    # the new repo to $PWD/<new-repo>
    # Then cd into <new-repo> afterwards.
    if status is-interactive
        and test (count $argv) -eq 2
        and test $argv[1] = repo -a $argv[2] = create
        set -l dirs_before (path filter -d *)

        if command gh repo create
            set -l dirs_after (path filter -d *)
            for dir in $dirs_after
                if not contains -- $dir $dirs_before
                    builtin cd $dir
                    break
                end
            end
        end

    else
        command gh $argv
    end
end
