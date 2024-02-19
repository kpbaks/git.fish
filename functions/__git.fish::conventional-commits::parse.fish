function __git.fish::conventional-commits::parse -a commit
    argparse --min-args 1 --max-args 1 -- $argv; or return 2

    set -l conventional_commit_regexp "^(feat|fix|build|chore|ci|docs|style|refactor|perf|test)(\(([^(]+)\))?(!)?: (.+)"
    set -l matches (string match --regex --groups-only $conventional_commit_regexp $commit)

    switch (count $matches)
        case 2 3
            printf "%s\n" $matches
        case 4 5
            # Do not print the "(scope)" capture
            printf "%s\n" $matches[1] $matches[3..]
        case '*'
            # Does not match the spec
            return 1
    end
end
