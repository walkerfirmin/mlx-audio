#!/bin/bash

for f in *.wav; do
  [[ "$f" == *_10s.wav ]] && continue
  base="${f%.wav}"
  ffmpeg -i "$f" -t 10 -c:a copy "${base}_10s.wav"
done