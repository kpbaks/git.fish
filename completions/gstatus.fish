set -l c complete -c gstatus

$c -s h -l help -d 'Show help information'
$c -s H -l hint -d 'Show hints for how to interact with the {,un}/staged, untracked files'

$c -s b -l no-branches -d 'Do not show branches'
$c -s s -l no-staged -d 'Do not show staged files'
$c -s u -l no-unstaged -d 'Do not show unstaged files'
$c -s U -l no-untracked -d 'Do not show untracked files'
$c -s S -l no-stash -d 'Do not show stashes'
