set -l filename (status filename)
set -l scriptdir (path dirname $filename)
set -l basename (path basename $filename)
set -l name (string sub --end=-5 $basename) # remove .fish extension

# set -l f $scriptdir/../functions/$basename
# test -f $f; or return 1

# functions --query @test; or begin
#     printf "%serror:%s @test not found, please install jorgebucaran/fishtape.fish\n" (set_color red) (set_color normal) >&2
#     return 1
# end

# source $f

set -l title "[$name]"

set -l conventional_commits_regexp "^(feat|fix|build|chore|ci|docs|style|refactor|perf|test)(\(([^(]+)\))?(!)?: (.+)"

# function parse_conventional_commit -a commit
#     set -l conventional_commit_regexp "^(feat|fix|build|chore|ci|docs|style|refactor|perf|test)(\(([^(]+)\))?(!)?: (.+)"
#     set -l matches (string match --regex --groups-only $conventional_commit_regexp $commit)
#     switch (count $matches)
#         case 2
#             printf "%s\n" $matches
#         case 4 5
#             # Do not print the "(scope)" capture
#             printf "%s\n" $matches[1] $matches[3..]
#         case '*'
#             # Does not match the spec
#             return 1
#     end
# end

# function pretty_print_conventional_commit -a commit
#     set -l matches (parse_conventional_commit $commit)
#     if test $status -ne 0
#         echo $commit # Print the commit as is
#         return 1
#     end

#     set -l type $matches[1]
#     set -l desc $matches[-1]

#     set -l reset (set_color normal)
#     set -l italics (set_color --italics)

#     set -l breaking 0
#     switch (count $matches)
#         case 3
#             # Can either be a scope or a breaking change '!'
#             if test $matches[2] = "!"
#                 set breaking 1
#             else
#                 set -f scope $matches[2]
#             end
#         case 4
#             # Scope and breaking change
#             set -f scope $matches[2]
#             set breaking 1
#         case '*'
#     end

#     set -l set_color_opts
#     if test $breaking -eq 1
#         # It is a breaking commit so we want it to stand out
#         # set set_color_opts --background
#         set set_color_opts --reverse
#     end

#     switch $type
#         case feat
#             set -f color_type (set_color $set_color_opts green)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case fix
#             set -f color_type (set_color $set_color_opts red)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case build
#             set -f color_type (set_color $set_color_opts yellow)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case chore
#             set -f color_type (set_color $set_color_opts yellow)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case ci docs
#             set -f color_type (set_color $set_color_opts yellow)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case style
#             set -f color_type (set_color $set_color_opts yellow)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case refactor perf
#             set -f color_type (set_color $set_color_opts magenta)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#         case test
#             set -f color_type (set_color $set_color_opts cyan)
#             set -f color_scope (set_color --bold)
#             set -f color_desc $italics
#     end

#     # Print the different parts of the commit
#     printf "%s%s%s" $color_type $type $reset
#     if set --query scope
#         printf "%s(%s)%s" $color_scope $scope $reset
#     end
#     if test $breaking -eq 1
#         printf "%s%s%s" $color_desc "!" $reset
#     end
#     printf ": %s%s%s" $color_desc $desc $reset
#     printf "\n"
# end

# set -l commit "fix(tests)!: breaking"
# string match --regex --groups-only $conventional_commits_regexp $commit
# string match --regex --groups-only $conventional_commits_regexp "feat(scope): hello there"
