#!/bin/zsh
# fix_wavs.sh — Re-encode all .wav files to 16-bit PCM mono 24kHz
# Only replaces originals after ALL conversions succeed.

TARGET_DIR="${1:-/Users/admin/Music/audio-clips}"
TEMP_DIR=$(mktemp -d)
FAILED=0

echo "[INFO] Scanning: $TARGET_DIR"
echo "[INFO] Temp dir: $TEMP_DIR"

typeset -a WAV_FILES
while IFS= read -r -d '' f; do
  WAV_FILES+=("$f")
done < <(find "$TARGET_DIR" -maxdepth 1 -name "*.wav" -print0)

if (( ${#WAV_FILES[@]} == 0 )); then
  echo "[INFO] No .wav files found in $TARGET_DIR"
  exit 0
fi

echo "[INFO] Found ${#WAV_FILES[@]} .wav file(s)"

# --- Pass 1: convert everything to temp dir ---
for src in "${WAV_FILES[@]}"; do
  filename=$(basename "$src")
  tmp_out="$TEMP_DIR/$filename"

  echo "[CONVERT] $filename"
  if ffmpeg -y -i "$src" -ar 24000 -ac 1 -c:a pcm_s16le "$tmp_out" -loglevel error; then
    echo "[OK]      $filename"
  else
    echo "[FAIL]    $filename"
    (( FAILED++ ))
  fi
done

# --- Abort if any conversion failed ---
if (( FAILED > 0 )); then
  echo ""
  echo "[ABORT] $FAILED conversion(s) failed — originals untouched."
  echo "[INFO]  Temp files left at: $TEMP_DIR"
  exit 1
fi

echo ""
echo "[INFO] All conversions succeeded. Replacing originals..."

# --- Pass 2: replace originals only after full success ---
for src in "${WAV_FILES[@]}"; do
  filename=$(basename "$src")
  tmp_out="$TEMP_DIR/$filename"
  mv "$tmp_out" "$src"
  echo "[REPLACED] $filename"
done

rm -rf "$TEMP_DIR"
echo ""
echo "[DONE] ${#WAV_FILES[@]} file(s) replaced."