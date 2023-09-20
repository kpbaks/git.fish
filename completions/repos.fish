set --local c complete --command repos
$c -f # disable file completion for repos command

set --local verbs clear list check init

$c -n "not __fish_seen_subcommand_from $verbs" -a clear -d "clear list of visited repositories"
$c -n "not __fish_seen_subcommand_from $verbs" -a list -d "list visited repositories"
$c -n "not __fish_seen_subcommand_from $verbs" -a check -d "update the database, by removing all repos no longer on disk"
$c -n "not __fish_seen_subcommand_from $verbs" -a init -d "initialize the database, by searching for all git repos under $argv[1]"
