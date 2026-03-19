#!/bin/zsh
# Produces 
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# Read text from stdin or first argument
# ---------------------------------------------------------------------------
if [ -n "$1" ]; then
  TEXT="$1"
elif [ -p /dev/stdin ] || [ ! -t 0 ]; then
  TEXT=$(cat | tr -d '\000-\010\013\014\016-\031\177')
fi

if [ -z "$TEXT" ]; then
  echo "Usage: echo 'your text' | $0"
  echo "   or: $0 'your text'"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found — install with: brew install jq"
  exit 1
fi

TTS_HOST="http://localhost:8002"
OUTPUT_FILE="$(pwd)/tts_$(date +%s).wav"

# REF_AUDIO="/Users/admin/Music/personal-audio/cleaned.wav"
# REF_TEXT="hey good morning so as yesterday we looked over the spreadsheet detailing the process for how were going to do deployments on mobile and following that luis provided the scope including those wave two items"
REF_AUDIO="/Users/admin/Music/personal-audio/variant_1.wav"
REF_TEXT="Once you’ve validated a direction, move into development. Even at this stage, keep iterating. Use analytics, feedback loops, and lightweight A/B testing to refine as you go."
# INSTRUCT="Speak in a natural, conversational professional tone — like a developer giving a verbal standup to their team. Relaxed but focused. Moderate pace, slightly faster on routine items, slower and more deliberate when highlighting blockers or important context. Light vocal energy, not monotone. Use natural sentence-level pausing at punctuation. Avoid dramatic inflection — this should sound like a real person talking, not a presentation."
INSTRUCT=""

JSON_PAYLOAD=$(jq -n \
  --arg model "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit" \
  --arg input "$TEXT" \
  --arg ref_audio "$REF_AUDIO" \
  --arg ref_text "$REF_TEXT" \
  --arg instruct "$INSTRUCT" \
  --argjson speed 1.0 \
  --argjson seed 42 \
  '{model: $model, input: $input, ref_audio: $ref_audio, ref_text: $ref_text, instruct: $instruct, speed: $speed, seed: $seed}')

echo "Sending TTS request..."

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST "$TTS_HOST/v1/audio/speech" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  -o "$OUTPUT_FILE")

if [ "$HTTP_CODE" != "200" ]; then
  echo "Error: TTS request failed (HTTP $HTTP_CODE)"
  rm -f "$OUTPUT_FILE"
  exit 1
fi

echo "Saved: $OUTPUT_FILE"