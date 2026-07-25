#!/bin/bash

# Enable debug mode
set -x

# Restore PATH so ffmpeg at /opt/homebrew/bin is visible to the server process
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
echo "[$(date)] PATH set to: $PATH" >> /tmp/mlx-audio.log

LOGFILE="/tmp/mlx-audio.log"

echo "[$(date)] Checking port 8002..." >> "$LOGFILE"
echo "[$(date)] Running lsof -i :8002" >> "$LOGFILE"

if ! lsof -i :8002 > /dev/null 2>&1; then
  echo "[$(date)] Port 8002 free. Starting mlx_audio.server..." >> "$LOGFILE"
  
  # Check if uv tool exists
  if [ ! -f "/Users/admin/.local/share/uv/tools/mlx-audio/bin/mlx_audio.server" ]; then
    echo "[$(date)] ERROR: mlx_audio.server binary not found!" >> "$LOGFILE"
  fi

  nohup /Users/admin/.local/share/uv/tools/mlx-audio/bin/mlx_audio.server \
    --host 0.0.0.0 --port 8002 >> "$LOGFILE" 2>&1 &
  PID=$!
  echo "[$(date)] mlx_audio.server started (PID: $PID)" >> "$LOGFILE"
  osascript -e "display notification \"mlx_audio.server started on 8002 (PID $PID)\" with title \"MLX Audio\""
else
  echo "[$(date)] Port 8002 already in use." >> "$LOGFILE"
  # Let's see what is using port 8002
  lsof -i :8002 >> "$LOGFILE"
  osascript -e "display notification \"mlx_audio.server already running on 8002\" with title \"MLX Audio\""
fi
