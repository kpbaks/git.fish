function ghdlf -d "Download a file from a GitHub repository"
    set reset (set_color normal)
    set green (set_color green)
    set red (set_color red)
    set bold (set_color --bold)

    # TODO: use quiet and token
    set options h/help v/verbose p/parents t/token=
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    if set --query _flag_help
        set option_color $green
        set section_title_color $yellow
        printf "%sDownload a file from a GitHub repository%s\n" $bold $reset
        printf "\n"
        # TODO: finish help
        # TODO: explain that you need a OAuth token for accessing private repos

        printf "\n"
        __git::help_footer
        return 0
    end >&2

    if command --query jaq
        set jq_program jaq
    else if command --query jq
        set jq_program jq
    else
        # TODO: explain error
        return 1
    end

    if not isatty stdin
        # TODO: read input from pipe and use that
    end

    # Handle different ways input can be given
    switch (count $argv)
        case 0
            # No arguments given, and stdin isatty, so we attempt to use the clipboard as input
            eval (status function) (fish_clipboard_paste)
            return
        case 1
            # TODO: handle case where input is given as: https://github.com/kpbaks/git.fish/blob/main/functions/ghdlf.fish

            string split --max=2 / $argv | read --line owner repo filepath
        case 3
            set owner $argv[1]
            set repo $argv[2]
            set filepath $argv[3]
        case '*'
            # TODO: explain error
            eval (status function) --help
            return 2
    end

    set GH_API_BASE_URL 'https://api.github.com'
    set GH_REPO_CONTENTS_ENDPOINT "$GH_API_BASE_URL/repos/%s/%s/contents/%s"
    # set api_request_url "$GH_API_BASE_URL/repos/$owner/$repo/$filepath" # FIXME: does not work
    set api_request_url (printf $GH_REPO_CONTENTS_ENDPOINT $owner $repo $filepath)

    if set --query _flag_verbose
        printf 'sending HTTP GET request to %s ...\n' $api_request_url
    end

    set temp_download_file (command mktemp)
    if set --query _flag_verbose
        printf 'created temporary file: %s\n' $temp_download_file
    end
    set curl_opts --silent --location --output $temp_download_file

    if not command curl $curl_opts $api_request_url
        # TODO: explain to the user why this failed
        return $status
    end

    # TODO: use --parents flag
    # If the filepath is specified as inside a directory, we need to create the parent directories
    # if they do already exist.
    if string match '*/*' $filepath
        set -l mkdir_command "command mkdir -p (path dirname $filepath)"
        if set --query _flag_verbose
            printf 'creating (potentially missing) parent directories by calling: %s%s\t' (print (echo $mkdir_command | fish_indent --ansi)) $rest
        end
        eval $mkdir_command
        # command mkdir -p (path dirname $filepath)
    end
    # TODO: handle case where file does not exist and .content is not set
    command $jq_program --raw-output '.content' <$temp_download_file | command base64 --decode >$filepath

    command rm $temp_download_file
    if set --query _flag_verbose
        printf 'removing temporary file: %s\n' $temp_download_file
    end
end
