set --local C complete --command gi

$C -s h -l help -d 'Show help information'
$C -s m -l merge -d 'Merge with existing .gitignore file'

$C -a '(gi list | string replace --regex --all "[ ,]" "\n")'
