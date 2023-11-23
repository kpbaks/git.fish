set --local c complete --command gi

$c -s h -l help -d 'Show help information'
$c -s m -l merge -d 'Merge with existing .gitignore file'

$c -a '(gi list | string replace --regex --all "[ ,]" "\n")'
