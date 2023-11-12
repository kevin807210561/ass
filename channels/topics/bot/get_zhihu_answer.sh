#!/bin/bash

function log {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$0] $1 $2" >&2
}

url="$1" && [[ -n "$url" ]] || {
    log ERROR "must provide url"
    exit 1
}

answer_html="$(mktemp)"
curl "$url" >"$answer_html" || {
    log ERROR "GET $url failed"
    exit 1
}
title="$(xq -x //h1 "$answer_html")" && [[ -n "$title" ]] || {
    log ERROR "get title failed"
    exit 1
}
author="$(xq -x '//div[@class="AuthorInfo"]/meta[@itemProp="name"]/@content' "$answer_html")" && [[ -n "$author" ]] || {
    log ERROR "get author failed"
    exit 1
}
content="$(xq -x //p "$answer_html")" && [[ -n "$content" ]] || {
    log ERROR "get content failed"
    exit 1
}

jq -n \
    --arg url "$url" \
    --arg title "$title" \
    --arg author "$author" \
    --arg content "$content" \
    '{
    url: $url,
    title: $title,
    author: $author,
    content: $content
}' || {
    log ERROR "generate result json failed"
    exit 1
}
