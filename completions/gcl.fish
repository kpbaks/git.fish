set --local c complete --command (status filename | path basename | string split --fields=1 .)

$c -s l -l local -d "Use the config of the local git repository"
$c -s h -l help -d "Show help information"
