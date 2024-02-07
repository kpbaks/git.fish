function ghdlf -d "Download a file from a GitHub repository"
    set reset (set_color normal)
    set green (set_color green)
    set red (set_color red)
    set bold (set_color --bold)

    # TODO: use quiet and token
    set options h/help q/quiet t/token=
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    if set --query _flag_help
        printf "%sDownload a file from a GitHub repository%s\n" $bold $reset
        printf "\n"
        # TODO: finish help
        # TODO: explain that you need a OAuth token for accessing private repos

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

    # Handle different ways input can be given
    switch (count $argv)
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

    set temp_download_file (command mktemp)
    set curl_opts --silent --location --output $temp_download_file

    if not command curl $curl_opts $api_request_url
        # TODO: explain to the user why this failed
        return $status
    end

    # If the filepath is specified as inside a directory, we need to create the parent directories
    # if they do already exist.
    if string match '*/*' $filepath
        command mkdir -p (path dirname $filepath)
    end
    # TODO: handle case where file does not exist and .content is not set
    command $jq_program --raw-output '.content' <$temp_download_file | command base64 --decode >$filepath

    command rm $temp_download_file
end
