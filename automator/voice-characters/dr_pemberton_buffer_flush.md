## 22. The Measured British Technical Presenter

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "It'\''s worth pausing on this paragraph because it contains a constraint that is easy to read past. The specification states that the buffer must be flushed before the handle is released. What it does not state — but what the implementation enforces — is that flush operations are synchronous in single-threaded contexts and asynchronous in multi-threaded ones. The behavior is correct in both cases. The timing is not identical. If your test suite runs single-threaded and your production environment does not, you will pass every test and encounter this in production. The specification is not wrong. It is simply not sufficient on its own. That distinction matters when you are debugging at two in the morning.",
    "voice": "gender: Male.\npitch: Upper-mid baritone, measured and authoritative without condescension.\nspeed: Lecture pace — unhurried, pauses slightly longer before and after important clauses.\nvolume: Seminar room projection, fills space without strain.\nage: Late 40s.\nclarity: RP-adjacent British English, precise without being fussy, technical vocabulary handled with ease.\nfluency: Academic but not stiff — complete sentences with internal rhythm, structured as if paragraphs are being spoken.\naccent: Southern English, educated — Oxford or Cambridge adjacent, slight warmth underneath the formality.\ntexture: Lecture theatre with good acoustics, the sound of chalk on a board somewhere nearby.\nemotion: Engaged intelligence — this person finds the edge cases genuinely interesting and does not pretend otherwise.\ntone: Conference talk from someone who has already been paged about this at two in the morning.\npersonality: Believes the gap between specification and implementation is where all the interesting engineering lives.",
    "speed": 0.88
  }' \
  --output dr_pemberton_buffer_flush.wav
```

10 second or first sentence

```
It's worth pausing on this paragraph because it contains a constraint that is easy to read past. The specification states that the buffer must be flushed before the handle is released.
```

**Automator Script Title:** Speak with MLX TTS (dr\_pemberton\_buffer\_flush) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/dr_pemberton_buffer_flush_10s.wav"
REF_TEXT="It's worth pausing on this paragraph because it contains a constraint that is easy to read past. The specification states that the buffer must be flushed before the handle is released."
```

Automator Script

```
character_scripts/dr_pemberton_buffer_flush.sh
```
