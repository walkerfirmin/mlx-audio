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

if ! command -v python3 &>/dev/null; then
  echo "[DEBUG] python3 not found — please install Python 3"
  osascript -e 'display notification "python3 is required but not installed." with title "TTS Error"'
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

REF_AUDIO="/Users/admin/Music/sample-audio-clips/cera_10s.wav"
REF_TEXT="What's up besties? You're tuned into my radio station where the vibes are chaotic but the playlist? Immaculate."

# ---------------------------------------------------------------------------
# Clean and chunk text using embedded Python (splits at sentence boundaries)
# ---------------------------------------------------------------------------
export TTS_INPUT_TEXT="$TEXT"
typeset -a CHUNKS
while IFS= read -r line; do
  if [ -n "$line" ]; then
    CHUNKS+=("$line")
  fi
done < <(python3 << 'EOF'
import os
import sys
import re

def clean_line(line):
    # Convert smart quotes / dashes
    line = line.replace("“", "\"").replace("”", "\"")
    line = line.replace("‘", "'").replace("’", "'")
    line = line.replace("—", ", ").replace("–", ", ")
    
    # Strip markdown headers (e.g. # Header, ## Header)
    line = re.sub(r"^#+\s+", "", line)
    
    # Clean lists: remove bullet points and list numbers at the beginning of lines
    line = re.sub(r"^\s*[-*+]\s+", "", line)
    line = re.sub(r"^\s*\d+\.\s+", "", line)
    
    # Convert markdown links [link text](url) -> link text
    line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line)
    
    # Strip markdown inline styling: **bold**, *italic*, __bold__, _italic_, `code`
    line = re.sub(r"\*\*([^*]+)\*\*", r"\1", line)
    line = re.sub(r"\*([^*]+)\*", r"\1", line)
    line = re.sub(r"__([^_]+)__", r"\1", line)
    line = re.sub(r"_([^_]+)_", r"\1", line)
    line = re.sub(r"`([^`]+)`", r"\1", line)
    
    # Replace multiple spaces with a single space
    line = re.sub(r"\s+", " ", line).strip()
    
    return line

def split_into_sentences(text):
    if not text:
        return []
    
    # Match sentence boundaries: punctuation (. ! ?) followed by space
    sentence_end = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9\"\'“‘])")
    
    raw_sentences = sentence_end.split(text)
    
    sentences = []
    for s in raw_sentences:
        s = s.strip()
        if not s:
            continue
        
        # Check if the split happened on an abbreviation, if so, merge it back
        if sentences:
            words = sentences[-1].split()
            if words:
                last_word = words[-1].rstrip(".!?").lower()
                if last_word in ["mr", "mrs", "dr", "ms", "sr", "jr", "vs", "ca", "eg", "ie", "etc", "al", "st"]:
                    sentences[-1] = sentences[-1] + " " + s
                    continue
        sentences.append(s)
        
    return sentences

def ensure_punctuation(text):
    text = text.strip()
    if not text:
        return text
    if text[-1] not in ".?!,;:":
        if text[-1] in ")\"'":
            if len(text) > 1 and text[-2] not in ".?!,;:":
                return text + "."
        else:
            return text + "."
    return text

def split_long_sentence(sentence, max_chars=400):
    # Try splitting on commas, semicolons, colons
    delimiters = re.compile(r"(?<=[,;:])\s+")
    parts = delimiters.split(sentence)
    
    chunks = []
    current_chunk = []
    current_len = 0
    
    for part in parts:
        part_len = len(part)
        if part_len > max_chars:
            if current_chunk:
                chunks.append(" ".join(current_chunk))
                current_chunk = []
                current_len = 0
            
            # If a part is still too long, split on space/word boundary
            words = part.split(" ")
            for word in words:
                if len(word) > max_chars:
                    if current_chunk:
                        chunks.append(" ".join(current_chunk))
                        current_chunk = []
                        current_len = 0
                    for k in range(0, len(word), max_chars):
                        chunks.append(word[k:k+max_chars])
                else:
                    space_padding = 1 if current_chunk else 0
                    if current_len + space_padding + len(word) > max_chars:
                        chunks.append(" ".join(current_chunk))
                        current_chunk = [word]
                        current_len = len(word)
                    else:
                        current_chunk.append(word)
                        current_len += space_padding + len(word)
        else:
            space_padding = 1 if current_chunk else 0
            if current_len + space_padding + part_len > max_chars:
                chunks.append(" ".join(current_chunk))
                current_chunk = [part]
                current_len = part_len
            else:
                current_chunk.append(part)
                current_len += space_padding + part_len
                
    if current_chunk:
        chunks.append(" ".join(current_chunk))
    return chunks

def build_chunks(sentences, max_chars=400):
    chunks = []
    current_chunk = []
    current_len = 0

    for sentence in sentences:
        sentence = ensure_punctuation(sentence)
        sentence_len = len(sentence)
        if sentence_len > max_chars:
            if current_chunk:
                chunks.append(" ".join(current_chunk))
                current_chunk = []
                current_len = 0
            sub_chunks = split_long_sentence(sentence, max_chars)
            chunks.extend(sub_chunks)
        else:
            space_padding = 1 if current_chunk else 0
            if current_len + space_padding + sentence_len > max_chars:
                chunks.append(" ".join(current_chunk))
                current_chunk = [sentence]
                current_len = sentence_len
            else:
                current_chunk.append(sentence)
                current_len += space_padding + sentence_len

    if current_chunk:
        chunks.append(" ".join(current_chunk))
    return chunks

def main():
    text = os.environ.get("TTS_INPUT_TEXT", "")
    lines = text.splitlines()
    cleaned_sentences = []
    for line in lines:
        cleaned_line = clean_line(line)
        if cleaned_line:
            line_sentences = split_into_sentences(cleaned_line)
            cleaned_sentences.extend(line_sentences)
            
    chunks = build_chunks(cleaned_sentences, max_chars=400)
    for chunk in chunks:
        if chunk.strip():
            print(chunk)

if __name__ == "__main__":
    main()
EOF
)

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
if (( ${#CHUNKS[@]} >= 2 )); then
  for i in $(seq 2 ${#CHUNKS[@]}); do
    _dispatch_tts $i
  done
fi

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