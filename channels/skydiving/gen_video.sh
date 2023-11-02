#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
video="$1"

ffmpeg -i "${SCRIPT_DIR}/一笑江湖 (DJ小瑞版).opus-intro.wav" -stream_loop -1 -i "${SCRIPT_DIR}/一笑江湖 (DJ小瑞版).opus-loop.wav" -an -i "$video" -filter_complex '[0:a:0][1:a:0]concat=n=2:v=0:a=1[outa]' -vf 'blackframe=0,metadata=select:key=lavfi.blackframe.pblack:value=99:function=less,setpts=N/FR/TB' -map '[outa]' -map 2:v:0 -shortest result.mp4
