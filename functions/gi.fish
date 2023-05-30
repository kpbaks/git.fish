function gi --description 'Get .gitignore file from https://www.toptal.com/developers/gitignore/api'
	# https://docs.gitignore.io/
    set -l options (fish_opt --short=h --long=help)
    set --append options (fish_opt --short=f --long=force)
    set --append options (fish_opt --short=m --long=merge)
    if not argparse $options -- $argv
        return 1
    end

    set -l argc (count $argv)

	set -l reset (set_color normal)
	set -l red (set_color red)
	set -l green (set_color green)

    if set --query _flag_help; or test $argc -eq 0
        set -l usage "$(set_color --bold)Download common .gitignore rules for various programming languages and frameworks from https://docs.gitignore.io/$(set_color normal)

$(set_color yellow --underline)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options] LANG [LANG...]

$(set_color yellow --underline)Arguments:$(set_color normal)
	$(set_color green)LANG$(set_color normal)    Programming language or framework to download .gitignore rules for. Multiple languages can be specified.

$(set_color yellow --underline)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
	$(set_color green)-f$(set_color normal), $(set_color green)--force$(set_color normal)     Force overwrite of existing .gitignore file
	$(set_color green)-m$(set_color normal), $(set_color green)--merge$(set_color normal)     Merge with existing .gitignore file, avoiding duplicates

$(set_color yellow --underline)Examples:$(set_color normal)
	$(set_color blue)$(status current-command)$(set_color normal) python > .gitignore
	$(set_color blue)$(status current-command)$(set_color normal) python flask > .gitignore"

        echo $usage
        return 0
    end

	set -l http_get_command
    set -l http_get_command_args
    if command --query curl
    	set http_get_command curl
        set http_get_command_args -sSL
    else if command --query wget
		set http_get_command wget
        set http_get_command_args -qO-
	else
		printf "%sPlease install curl or wget to run this command%s" $red $reset >&2
		return 1
    end

    # TODO: <kpbaks 2023-05-30 19:28:26> tee to .gitignore if it doesn't exist
	# | tee .gitignore
    set -l query (string join , "$argv")
    set -l gitignore ($http_get_command $http_get_command_args https://www.toptal.com/developers/gitignore/api/$query)
    if string match --quiet "ERROR:" $gitignore
		printf "%serror:%s\n" $red $reset >&2
		echo $gitignore >&2
		return 1
	end

    for line in $gitignore
    echo $line
	end

	# TODO: <kpbaks 2023-05-30 19:52:55> handle --force and --merge flags
end
