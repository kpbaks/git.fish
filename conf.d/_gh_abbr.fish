command --query gh; or return

# Running gh will output information about http status codes and response times
# to stderr. This is not useful for the user, so we redirect it to /dev/null.
abbr --add gh --set-cursor "gh % 2>/dev/null"

abbr -a ghs gh status

# open the current repo in the browser
abbr -a ghb 'gh browse 2>/dev/null'
