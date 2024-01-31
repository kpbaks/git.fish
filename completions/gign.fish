# set --local c complete --command (status filename | path basename | string split --fields=1 .)
set -l c complete -c gign

$c -s h -l help -d 'Show help information'
$c -s m -l merge -d 'Merge with existing .gitignore file'

$c -a '(gign list | string replace --regex --all "[ ,]" "\n")'
