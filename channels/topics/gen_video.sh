#!/bin/bash

function log {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$0] $1 $2" >&2
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

title=$1 && [[ -n "$title" ]] || {
    log ERROR "must provide title"
    exit 1
}
author_img=$2 && [[ -n "$author_img" ]] || {
    log ERROR "must provide author image"
    exit 1
}
content_file=$3 && [[ -n "$content_file" ]] || {
    log ERROR "must provide content file"
    exit 1
}
content_video=$4 && [[ -n "$content_video" ]] || {
    log ERROR "must provide content video"
    exit 1
}
content_video_fps_str="$(ffprobe -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$content_video")" && content_video_fps=$((content_video_fps_str)) || {
    log ERROR "failed to get fps of the content video"
    exit 1
}

video_size="1280x720"
author_img_size="640:360"
voice="zh-CN-YunxiNeural"
rate="+20%"
shopt -s expand_aliases
alias edge-tts-zh="edge-tts -v \$voice --rate \$rate"

# gen title
echo "1" >title.srt
echo "00:00:00,000 --> 10:00:00,000" >>title.srt
cat <<<"$title" >>title.srt
edge-tts-zh -t "今日话题，${title}。" --write-media title.mp3 || {
    log ERROR "edge-tts for title failed"
    exit 1
}
title_duration=$(ffprobe -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration title.mp3) || {
    log ERROR "get title.mp3 duration failed"
    exit 1
}
ffmpeg \
    -f lavfi -i "color=c=black:s=${video_size}:r=${content_video_fps}" \
    -i title.mp3 \
    -vf "subtitles=title.srt:force_style='Alignment=10,Fontsize=50'" -t "$title_duration" -y title.mp4 || {
    log ERROR "gen title.mp4 failed"
    exit 1
}

# gen author
edge-tts-zh -t "一位网友是这样说的。" --write-media author.mp3 || {
    log ERROR "edge-tts for author failed"
    exit 1
}
author_duration=$(ffprobe -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration author.mp3) || {
    log ERROR "get author.mp3 duration failed"
    exit 1
}
ffmpeg \
    -f lavfi -i "color=c=black:s=${video_size}:r=${content_video_fps}" \
    -i "$author_img" \
    -i author.mp3 \
    -filter_complex "[1:v:0]scale=${author_img_size}[resized_img],[0:v:0][resized_img]overlay=x=W/2-w/2:y=H/2-h/2" -t "$author_duration" -y author.mp4 || {
    log ERROR "gen author.mp4 failed"
    exit 1
}

# gen content
cat "$content_file" >content_file_cp.txt
echo "。对此你有什么看法，欢迎评论区留言。" >>content_file_cp.txt
# edge-tts-zh -f content_file_cp.txt --write-media content.mp3 || {
#     log ERROR "edge-tts for content failed"
#     exit 1
# }
# whisper content.mp3
content_duration=$(ffprobe -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration content.mp3) || {
    log ERROR "get content.mp3 duration failed"
    exit 1
}
ffmpeg \
    -i content.mp3 \
    -an -i "$content_video" \
    -i content.srt \
    -vf "subtitles=content.srt" -t "$content_duration" -y content.mp4 || {
    log ERROR "gen content.mp4 failed"
    exit 1
}

# concact all clips
ffmpeg \
    -i title.mp4 \
    -i author.mp4 \
    -i content.mp4 \
    -i "${SCRIPT_DIR}/Yawarakana hikari.opus-intro.wav" \
    -stream_loop -1 -i "${SCRIPT_DIR}/Yawarakana hikari.opus-loop.wav" \
    -filter_complex '[0:v:0][1:v:0][2:v:0]concat=n=3:v=1:a=0[outv];[0:a:0][1:a:0][2:a:0]concat=n=3:v=0:a=1[main],[3:a:0][4:a:0]concat=n=2:v=0:a=1[bgm],[main][bgm]amix=duration=2:weights=2 0.1[outa]' \
    -map [outv] -map [outa] -shortest -y result.mp4
