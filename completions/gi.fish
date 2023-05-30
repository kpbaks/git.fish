set -l C complete --command gi

$C -s h -l help -d 'Show help information'

$C -a '(gi list | string replace --regex --all "[ ,]" "\n")'
