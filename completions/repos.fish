complete -c repos -f # disable file completion for repos command

set -l verbs clear list

complete -c repos -n "not __fish_seen_subcommand_from $verbs" -a clear -d "clear list of visited repositories"
complete -c repos -n "not __fish_seen_subcommand_from $verbs" -a list -d "list visited repositories"
