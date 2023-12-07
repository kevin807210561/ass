#!/bin/bash

function log {
    echo "$(date "+%Y-%m-%d %H:%M:%S") [$0] $1 $2" >&2
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

title=$1 && [[ -n "$title" ]] || {
    log ERROR "must provide title"
    exit 1
}
author=$2 && answer_url="${author:0:12}" && [[ -n "$author" ]] || {
    log ERROR "must provide author"
    exit 1
}
answer_url=$3 && answer_url="${answer_url:0:58}" && [[ -n "$answer_url" ]] || {
    log ERROR "must provide answer url"
    exit 1
}
content_file=$4 && [[ -n "$content_file" ]] || {
    log ERROR "must provide content file"
    exit 1
}
content_video=$5 && [[ -n "$content_video" ]] || {
    log ERROR "must provide content video"
    exit 1
}
if [[ ! -f "$content_video" ]]; then
    content_video=$(yt-dlp "$content_video" -o "content.%(ext)s" --print filename --no-simulate) || {
        log ERROR "download content video failed"
        exit 1
    }
fi

content_video_fps="$(ffprobe -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate "$content_video")" || {
    log ERROR "failed to get fps of the content video"
    exit 1
}

video_width=1280
video_height=720
zhihu_img_width=800
zhihu_img_height=240
shopt -s expand_aliases
alias edge-tts-zh="edge-tts -v zh-CN-YunxiNeural --rate +20%"
whisper_model="${WHISPER_MODEL:-small}"

# gen title
echo "1" >title.srt
echo "00:00:00,000 --> 10:00:00,000" >>title.srt
title_to_split="${title}"
title_split_len="12"
while [[ -n "${title_to_split}" ]]; do
    cat <<<"${title_to_split:0:${title_split_len}}" >>title.srt
    title_to_split="${title_to_split:${title_split_len}}"
done
edge-tts-zh -t "今日话题，${title}。" --write-media title.mp3 || {
    log ERROR "edge-tts for title failed"
    exit 1
}
title_duration=$(ffprobe -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration title.mp3) || {
    log ERROR "get title.mp3 duration failed"
    exit 1
}
ffmpeg \
    -f lavfi -i "color=c=black:s=${video_width}x${video_height}:r=${content_video_fps}" \
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
    -f lavfi -i "color=c=black:s=${video_width}x${video_height}:r=${content_video_fps}" \
    -i "${SCRIPT_DIR}/zhihu_banner.png" \
    -i author.mp3 \
    -filter_complex "[1:v:0]scale=${zhihu_img_width}:${zhihu_img_height}[resized_img],[0:v:0][resized_img]overlay=x=W/2-w/2:y=H/2-h/2,drawtext=text='${author/:/\\:}':fontfile='${SCRIPT_DIR}/QingNiaoHuaGuangJianMeiHei-2.ttf':fontsize=40:x=w/2+${zhihu_img_height}/2-tw/2:y=h/2-th,drawtext=text='${answer_url/:/\\:}':x=w/2+${zhihu_img_height}/2-tw/2:y=h/2+${zhihu_img_height}/10" -t "$author_duration" -y author.mp4 || {
    log ERROR "gen author.mp4 failed"
    exit 1
}

# gen content
cat "$content_file" >content_file_cp.txt
echo "。对此你有什么看法，欢迎评论区留言。" >>content_file_cp.txt
edge-tts-zh -f content_file_cp.txt --write-media content.mp3 || {
    log ERROR "edge-tts for content failed"
    exit 1
}
whisper --model "$whisper_model" --fp16 False -f srt content.mp3 || {
    log ERROR "gen content.srt failed"
    exit 1
}
content_duration=$(ffprobe -select_streams a -of default=noprint_wrappers=1:nokey=1 -show_entries stream=duration content.mp3) || {
    log ERROR "get content.mp3 duration failed"
    exit 1
}
ffmpeg \
    -i content.mp3 \
    -an -i "$content_video" \
    -i content.srt \
    -vf "scale=${video_width}:${video_height},subtitles=content.srt:force_style='Fontsize=20'" -t "$content_duration" -y content.mp4 || {
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
    -filter_complex '[0:v:0]fade[titlev],[1:v:0]fade[authorv],[2:v:0]fade[contentv],[titlev][authorv][contentv]concat=n=3:v=1:a=0[outv];[0:a:0][1:a:0][2:a:0]concat=n=3:v=0:a=1[main],[3:a:0][4:a:0]concat=n=2:v=0:a=1[bgm],[main][bgm]amix=duration=2:weights=2 0.1[outa]' \
    -map [outv] -map [outa] -shortest -y result.mp4 || {
    log ERROR "gen result.mp4 failed"
    exit 1
}
