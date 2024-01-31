# set --local c complete --command (status filename | path basename | string split --fields=1 .)

set -l c complete -c repos
$c -f # disable file completion for repos command

set -l verbs clear list check init
set -l cond "not __fish_seen_subcommand_from $verbs"

$c -n $cond -a clear -d "clear list of visited repositories"
$c -n $cond -a list -d "list visited repositories"
$c -n $cond -a check -d "update the database, by removing all repos no longer on disk"
$c -n $cond -a init -d "initialize the database, by searching for all git repos under $argv[1]"
