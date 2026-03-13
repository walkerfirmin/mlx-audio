#!/bin/zsh

# Restore full PATH for Automator/launchd contexts
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Source Homebrew shellenv for complete environment
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

PID_FILE="/tmp/tts_player.pid"

# ---------------------------------------------------------------------------
# Toggle: if already playing, stop and exit
# ---------------------------------------------------------------------------
if [ -f "$PID_FILE" ]; then
  PLAYER_PID=$(cat "$PID_FILE")
  echo "[DEBUG] Found PID file with PID: $PLAYER_PID"

  if kill -0 $PLAYER_PID 2>/dev/null; then
    echo "[DEBUG] Audio is playing, stopping player process $PLAYER_PID"
    pkill -P $PLAYER_PID 2>/dev/null
    kill $PLAYER_PID 2>/dev/null
    rm -f "$PID_FILE"
    osascript -e 'display notification "Audio playback stopped." with title "TTS Stop"'
    echo "[DEBUG] Player stopped"
    exit 0
  else
    echo "[DEBUG] Process $PLAYER_PID not running, cleaning up stale PID file"
    rm -f "$PID_FILE"
  fi
fi

echo "[DEBUG] No audio playing, proceeding to play selected text"

# Robust stdin read (works in terminal AND Automator)
if [ -p /dev/stdin ] || [ ! -t 0 ]; then
  TEXT=$(cat | tr -d '\000-\010\013\014\016-\031\177')
else
  TEXT=""
fi

echo "[DEBUG] Text to convert: $TEXT"

if [ -z "$TEXT" ]; then
  echo "[DEBUG] No text provided, exiting"
  osascript -e 'display notification "No text selected." with title "TTS"'
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "[DEBUG] jq not found — install it with: brew install jq"
  osascript -e 'display notification "jq is required but not installed. Run: brew install jq" with title "TTS Error"'
  exit 1
fi

if ! command -v ffplay &>/dev/null; then
  echo "[DEBUG] ffplay not found — install it with: brew install ffmpeg"
  osascript -e 'display notification "ffplay is required (brew install ffmpeg)" with title "TTS Error"'
  exit 1
fi

MAX_CHARS=20000
if (( ${#TEXT} > MAX_CHARS )); then
  echo "[DEBUG] Input too long (${#TEXT} chars), truncating to $MAX_CHARS"
  TEXT="${TEXT:0:$MAX_CHARS}"
fi

TTS_HOST="http://localhost:8002"
AUDIO_DIR="/tmp/mlx_tts"
TIMESTAMP=$(date +%s)
mkdir -p "$AUDIO_DIR"
echo "[DEBUG] TTS Host: $TTS_HOST"
echo "[DEBUG] Audio directory: $AUDIO_DIR"

REF_AUDIO="/Users/admin/Music/sample-audio-clips/jerome_city_geography_10s.wav"
REF_TEXT="You know what's interesting about this job - and I know everybody probably tells you their whole life story, I'll keep it short - but you see the city different."

# ---------------------------------------------------------------------------
# Chunk text: every 400 chars (word boundary) OR every 2nd newline
# ---------------------------------------------------------------------------
typeset -a CHUNKS

_split_long_line() {
  local text="$1"
  local seg=""
  for word in ${=text}; do
    if [ -z "$seg" ]; then
      seg="$word"
    elif (( ${#seg} + 1 + ${#word} <= 400 )); then
      seg="$seg $word"
    else
      CHUNKS+=("$seg")
      seg="$word"
    fi
  done
  [ -n "$seg" ] && CHUNKS+=("$seg")
}

chunk=""
newline_count=0

while IFS= read -r line; do
  if [ -z "$chunk" ]; then
    if (( ${#line} > 400 )); then
      _split_long_line "$line"
    else
      chunk="$line"
      newline_count=0
    fi
  else
    tentative="${chunk}
${line}"
    if (( ${#tentative} > 400 )); then
      CHUNKS+=("$chunk")
      if (( ${#line} > 400 )); then
        chunk=""
        newline_count=0
        _split_long_line "$line"
      else
        chunk="$line"
        newline_count=0
      fi
    else
      chunk="$tentative"
      (( newline_count++ ))
      if (( newline_count >= 2 )); then
        CHUNKS+=("$chunk")
        chunk=""
        newline_count=0
      fi
    fi
  fi
done <<< "$TEXT"

[ -n "$chunk" ] && CHUNKS+=("$chunk")

echo "[DEBUG] Total chunks: ${#CHUNKS[@]}"
for i in $(seq 1 ${#CHUNKS[@]}); do
  echo "[DEBUG] Chunk $i: ${CHUNKS[$i]}"
done

# ---------------------------------------------------------------------------
# Build file paths and dispatch TTS requests (chunk 1 first for priority)
# ---------------------------------------------------------------------------
typeset -a AUDIO_FILES
for i in $(seq 1 ${#CHUNKS[@]}); do
  AUDIO_FILES+=("$AUDIO_DIR/tts_${TIMESTAMP}_chunk${i}.wav")
done

FIFO="$AUDIO_DIR/tts_${TIMESTAMP}.fifo"

_dispatch_tts() {
  local idx=$1
  local chunk_text="${CHUNKS[$idx]}"
  local audio_file="${AUDIO_FILES[$idx]}"

  local json_payload=$(jq -n \
    --arg model "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-6bit" \
    --arg input "$chunk_text" \
    --arg ref_audio "$REF_AUDIO" \
    --arg ref_text "$REF_TEXT" \
    --argjson speed 1.0 \
    --argjson seed 42 \
    '{model: $model, input: $input, ref_audio: $ref_audio, ref_text: $ref_text, speed: $speed, seed: $seed}')

  echo "[DEBUG] Dispatching TTS request for chunk $idx..."
  (
    HTTP_CODE=$(curl -s -w "%{http_code}" -X POST "$TTS_HOST/v1/audio/speech" \
      -H "Content-Type: application/json" \
      -d "$json_payload" \
      -o "$audio_file")
    if [ "$HTTP_CODE" != "200" ]; then
      echo "[DEBUG] Chunk $idx TTS error (HTTP $HTTP_CODE)" >&2
      touch "${audio_file}.failed"
    else
      echo "[DEBUG] Chunk $idx ready: $audio_file"
      touch "${audio_file}.ready"
    fi
  ) &
}

# Prioritize chunk 1 so the server starts on it before the rest arrive
_dispatch_tts 1
for i in $(seq 2 ${#CHUNKS[@]}); do
  _dispatch_tts $i
done

echo "[DEBUG] All ${#CHUNKS[@]} TTS requests dispatched."

# ---------------------------------------------------------------------------
# Playback manager — SINGLE ffplay process reading WAV stream from FIFO
# ---------------------------------------------------------------------------
# NOTE: If the TTS server supports chunked transfer encoding (streaming),
# a further optimization is to pipe curl -N directly to ffplay for chunk 1,
# eliminating the file-write round-trip entirely. Test with:
#   curl -v -N -X POST "$TTS_HOST/v1/audio/speech" ... 2>&1 | grep -i transfer
# and look for "Transfer-Encoding: chunked".
# ---------------------------------------------------------------------------
(
  mkfifo "$FIFO"

  # Start ffplay immediately — it blocks on FIFO read, overlapping its
  # startup latency with TTS generation of chunk 1
  ffplay -nodisp -autoexit -loglevel error -i "$FIFO" &
  FFPLAY_PID=$!

  # Hold a write fd open so ffplay doesn't see EOF between chunks
  exec 3>"$FIFO"

  ALL_FAILED=true

  for i in $(seq 1 ${#AUDIO_FILES[@]}); do
    AUDIO_FILE="${AUDIO_FILES[$i]}"
    WAIT_TICKS=0
    MAX_TICKS=$(( 60 * 20 ))  # 60s timeout: 20 ticks/sec * 60s

    while true; do
      if [ -f "${AUDIO_FILE}.ready" ]; then
        ALL_FAILED=false
        echo "[DEBUG] Streaming chunk $i to ffplay: $AUDIO_FILE"
        if [ "$i" -eq 1 ]; then
          cat "$AUDIO_FILE" >&3
        else
          # Strip 44-byte WAV header so ffplay sees one continuous stream
          tail -c +45 "$AUDIO_FILE" >&3
        fi
        echo "[DEBUG] Chunk $i streamed"
        break
      elif [ -f "${AUDIO_FILE}.failed" ]; then
        echo "[DEBUG] Chunk $i failed, skipping"
        break
      fi
      sleep 0.05
      (( WAIT_TICKS++ ))
      if (( WAIT_TICKS > MAX_TICKS )); then
        echo "[DEBUG] Chunk $i timed out, skipping"
        break
      fi
    done
  done

  # Close write fd — ffplay sees EOF and finishes
  exec 3>&-

  if $ALL_FAILED; then
    osascript -e 'display notification "TTS failed for all chunks." with title "TTS Error"'
  fi

  echo "[DEBUG] All chunks streamed, waiting for ffplay to finish..."
  wait $FFPLAY_PID

  echo "[DEBUG] ffplay finished, cleaning up..."
  rm -f "$FIFO"
  for f in "${AUDIO_FILES[@]}"; do
    rm -f "$f" "${f}.ready" "${f}.failed"
  done
  rm -f "$PID_FILE"
  echo "[DEBUG] Done"
) &

PLAYER_PID=$!
echo "[DEBUG] Playback manager PID: $PLAYER_PID"
echo $PLAYER_PID > "$PID_FILE"

cleanup() {
  pkill -P $PLAYER_PID 2>/dev/null
  kill $PLAYER_PID 2>/dev/null
  rm -f "$FIFO" "$PID_FILE"
  for f in "${AUDIO_FILES[@]}"; do
    rm -f "$f" "${f}.ready" "${f}.failed"
  done
}
trap cleanup INT TERM

wait $PLAYER_PID 2>/dev/null
echo "[DEBUG] Playback manager exited"