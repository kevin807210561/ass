#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.10.0
# ARG_OPTIONAL_SINGLE([topic-url],,[eg. https://www.zhihu.com/question/613569488/answer/3138257334])
# ARG_OPTIONAL_SINGLE([content-video],,[can be local path or url supported by yt-dlp])
# ARG_OPTIONAL_SINGLE([input-file],,[for multiple topics, one topic in one line, sperate topic-url and content-video by space])
# ARG_HELP([Used for generate topic video from text.])
# ARGBASH_GO

# [ <-- needed because of Argbash

function log {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$0] $1 $2" >&2
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

[[ -z "$_arg_topic_url" ]] || [[ -z "$_arg_content_video" ]] || {
    "${SCRIPT_DIR}/input_single.sh" "$_arg_topic_url" "$_arg_content_video" || {
        log ERROR "generate for $_arg_topic_url $_arg_content_video failed"
        exit 1
    }
}
[[ -z "$_arg_input_file" ]] || {
    "${SCRIPT_DIR}/input_multiple.sh" "$_arg_input_file" || {
        log ERROR "generate for $_arg_input_file failed"
        exit 1
    }
}


# ] <-- needed because of Argbash
