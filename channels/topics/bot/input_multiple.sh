#!/bin/bash

function log {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$0] $1 $2" >&2
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

input_file="$1" && [[ -n "$input_file" ]] || {
    log ERROR "must provide input file"
    exit 1
}

output_file="${input_file}.out"
while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    log INFO "processing input line '${line}'"
    reg='^[ ]*[^ ]+[ ]+[^ ]+[ ]*$'
    [[ "$line" =~ $reg ]] || {
        cat <<<"$line" >>"$output_file" || {
            log ERROR "write to output file failed"
            exit 1
        }
        continue
    }
    topic_url="${line#"${line%%[![:space:]]*}"}" && topic_url="${topic_url%% *}"
    content_video="${line%"${line##*[![:space:]]}"}" && content_video="${content_video##* }"
    log INFO "generate for $topic_url $content_video"
    if "${SCRIPT_DIR}/input_single.sh" "$topic_url" "$content_video"; then
        cat <<<"${line} done" >>"$output_file" || {
            log ERROR "write to output file failed"
            exit 1
        }
    else
        log ERROR "generate for ${topic_url} ${content_video} failed, skipped"
        cat <<<"$line" >>"$output_file" || {
            log ERROR "write to output file failed"
            exit 1
        }
    fi
done 3<"$input_file" || {
    log ERROR "read input file failed"
    exit 1
}
if [[ -f "$output_file" ]]; then
    mv -f "$output_file" "$input_file" || {
        log ERROR "write results failed"
        exit 1
    }
fi
