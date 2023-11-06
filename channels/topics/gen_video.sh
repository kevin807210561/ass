#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

title=$1 && [[ -n "$title" ]] || {
    echo "must provide title"
    exit 1
}
author_img=$2 && [[ -n "$author_img" ]] || {
    echo "must provide author image"
    exit 1
}
content_file=$3 && [[ -n "$content_file" ]] || {
    echo "must provide content file"
    exit 1
}
content_video=$4 && [[ -n "$content_video" ]] || {
    echo "must provide content video"
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
    echo "edge-tts for title failed"
    exit 1
}
ffmpeg \
    -f lavfi -i "color=c=black:s=$video_size" \
    -i title.mp3 \
    -vf "subtitles=title.srt:force_style='Alignment=10,Fontsize=50'" -c:a copy -shortest -y title.mp4 || {
    echo "gen title.mp4 failed"
    exit 1
}

# gen author
edge-tts-zh -t "一位网友是这样说的。" --write-media author.mp3 || {
    echo "edge-tts for author failed"
    exit 1
}
ffmpeg \
    -f lavfi -i "color=c=black:s=$video_size" \
    -i "$author_img" \
    -i author.mp3 \
    -filter_complex "[1:v:0]scale=${author_img_size}[resized_img],[0:v:0][resized_img]overlay=x=W/2-w/2:y=H/2-h/2" -c:a copy -shortest -y author.mp4 || {
    echo "gen author.mp4 failed"
    exit 1
}

# gen content
cat "$content_file" >content_file_cp.txt
echo "。对此你有什么看法，欢迎评论区留言。" >>content_file_cp.txt
# edge-tts-zh -f content_file_cp.txt --write-media content.mp3 --write-subtitles content.vtt || {
#     echo "edge-tts for content failed"
#     exit 1
# }
ffmpeg \
    -i "${SCRIPT_DIR}/Yawarakana hikari.opus-intro.wav" \
    -stream_loop -1 -i "${SCRIPT_DIR}/Yawarakana hikari.opus-loop.wav" \
    -i content.mp3 \
    -an -i "$content_video" \
    -i content.vtt \
    -filter_complex '[0:a:0][1:a:0]concat=n=2:v=0:a=1[background],[2:a:0][background]amix=duration=2:weights=2 0.1[outa]' \
    -vf "subtitles=content.vtt" -map '[outa]' -map 3:v:0 -shortest -y content.mp4 || {
    echo "gen content.mp4 failed"
    exit 1
}
