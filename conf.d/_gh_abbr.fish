command --query gh; or return
set -l A abbr --add

$A ghs gh status

# open the current repo in the browser
$A ghb gh browse

$A ghp gh pr list
$A ghr gh repo view --web
$A ghg gh gist list
