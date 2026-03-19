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

REF_AUDIO="/Users/admin/Music/sample-audio-clips/linda_hostas_mulch_10s.wav"
REF_TEXT="Oh I'm telling you, the moment I put that second layer of mulch down, those hostas just took off. I don't know why I waited so long, frank said do it in the fall"

# ---------------------------------------------------------------------------
# Chunk text: split on sentence boundaries ([.!?] followed by whitespace or
# end-of-string), then merge consecutive short sentences up to MIN_CHARS so
# the TTS model always receives a meaningful utterance.
#
# Tunables:
#   MIN_CHARS – merge sentences together until the running chunk reaches this
#               length.  Keeps very short sentences (e.g. "OK.  Yes.") from
#               producing tiny, tonally-odd audio clips.
#   MAX_CHUNK  – hard ceiling; a single sentence longer than this is split at
#               the last word boundary before the limit.
# ---------------------------------------------------------------------------
typeset -a CHUNKS

MIN_CHARS=80    # merge short sentences up to this length
MAX_CHUNK=400   # hard ceiling per chunk

# _split_long_sentence: word-wrap a sentence that exceeds MAX_CHUNK
_split_long_sentence() {
  local text="$1"
  local seg=""
  for word in ${=text}; do
    if [ -z "$seg" ]; then
      seg="$word"
    elif (( ${#seg} + 1 + ${#word} <= MAX_CHUNK )); then
      seg="$seg $word"
    else
      CHUNKS+=("$seg")
      seg="$word"
    fi
  done
  [ -n "$seg" ] && CHUNKS+=("$seg")
}

# _flush_pending: add $pending to CHUNKS (splitting if too long)
_flush_pending() {
  local text="$1"
  [ -z "$text" ] && return
  if (( ${#text} > MAX_CHUNK )); then
    _split_long_sentence "$text"
  else
    CHUNKS+=("$text")
  fi
}

# Use Python (available on macOS) to tokenise sentences, one per line.
# The regex splits after [.!?] when followed by whitespace + capital or EOL.
# Trim each line so stray leading/trailing spaces don't confuse the merger.
typeset -a SENTENCES
while IFS= read -r sent; do
  sent="${sent## }"   # ltrim
  sent="${sent%% }"   # rtrim
  [ -n "$sent" ] && SENTENCES+=("$sent")
done < <(python3 - "$TEXT" <<'PYEOF'
import sys, re
text = sys.argv[1]
# Split after sentence-ending punctuation followed by whitespace + uppercase,
# or end-of-string.  Keep the punctuation with the preceding sentence.
parts = re.split(r'(?<=[.!?])\s+(?=[A-Z\"\(\[])', text)
for p in parts:
    p = p.strip()
    if p:
        print(p)
PYEOF
)

echo "[DEBUG] Sentences found: ${#SENTENCES[@]}"

# Merge short consecutive sentences up to MIN_CHARS
pending=""
for sent in "${SENTENCES[@]}"; do
  if [ -z "$pending" ]; then
    pending="$sent"
  else
    merged="$pending $sent"
    if (( ${#pending} < MIN_CHARS && ${#merged} <= MAX_CHUNK )); then
      # Both fit and pending is still short — keep merging
      pending="$merged"
    else
      _flush_pending "$pending"
      pending="$sent"
    fi
  fi
done
_flush_pending "$pending"

echo "[DEBUG] Total chunks: ${#CHUNKS[@]}"
for i in $(seq 1 ${#CHUNKS[@]}); do
  echo "[DEBUG] Chunk $i (${#CHUNKS[$i]} chars): ${CHUNKS[$i]}"
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
