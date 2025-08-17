#!/bin/bash
set -e

VIDEO=$1
SRT=$2
OUT=$3

if [ -z "$VIDEO" ] || [ -z "$SRT" ] || [ -z "$OUT" ]; then
  echo "Usage: postprocess-video.sh input.mp4 captions.srt output.mp4"
  exit 1
fi

ffmpeg -i "$VIDEO" -vf "subtitles=$SRT" -c:a copy "$OUT"
