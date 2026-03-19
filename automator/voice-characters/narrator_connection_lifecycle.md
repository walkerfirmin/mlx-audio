## 21. The Calm Technical Narrator

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Section 3.2 — Connection Lifecycle Management. When a client initiates a connection, the handshake sequence proceeds in three distinct phases. Phase one establishes the transport layer and negotiates protocol version. Phase two exchanges capability flags, which determine which optional features are available for the duration of the session. Phase three commits the session identifier, after which the connection is considered active. Any failure during phases one or two results in a clean rejection with an error code. Failures during phase three are considered partial connections and must be explicitly closed by the client. Leaving partial connections open is the most common source of resource exhaustion in high-concurrency deployments.",
    "voice": "gender: Male.\npitch: Settled mid-to-low range, consistent throughout — no dramatic variation, no fatigue.\nspeed: Even and readable, the pace of someone who has calibrated to comprehension rather than performance.\nvolume: Podcast-quality presence, close and clear, the voice filling the ears without effort.\nage: Early 40s.\nclarity: Broadcast-clean, every technical term given its full weight, acronyms spaced slightly for parsing.\nfluency: Sentence-by-sentence delivery with a micro-pause at every period, giving structure audible form.\naccent: Standard American broadcast neutral — no regional markers, geography erased for accessibility.\ntexture: Well-lit reading room, neutral acoustics, the sound of information moving cleanly from one mind to another.\nemotion: Alert neutrality — not robotic, not warm, precisely calibrated to get out of the way of the content.\ntone: Audiobook narrator who has read enough technical material to understand it and respects that you need to also.\npersonality: Invisible by design — the voice exists to carry the words, not to be noticed.",
    "speed": 0.90
  }' \
  --output narrator_connection_lifecycle.wav
```

10 second or first sentence

```
Section 3.2 - Connection Lifecycle Management. When a client initiates a connection, the handshake sequence proceeds in three distinct phases.
```

**Automator Script Title:** Speak with MLX TTS ({Character\_Name}) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/narrator_connection_lifecycle_10s.wav"
REF_TEXT="Section 3.2 - Connection Lifecycle Management. When a client initiates a connection, the handshake sequence proceeds in three distinct phases."
```

Automator Script

```
character_scripts/narrator_connection_lifecycle.sh
```
