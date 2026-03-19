## 18. The Senior Engineer Who's Been Here Before

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "The reason this function takes a callback instead of returning a promise isn'\''t an accident — it was a deliberate choice made in 2019 when the library needed to support environments where promise polyfills were unreliable. That context got lost. Most of the original contributors moved on. What you'\''re left with is an API that looks like a mistake but is actually a scar. Scars mean something happened. In this case what happened is that someone shipped to production in an environment that broke three hours before a demo and made a decision under pressure that turned out to be correct. The callback is load-bearing. Do not remove the callback. What you can do — and what I would do — is wrap it. I'\''ll show you exactly how.",
    "voice": "gender: Male.\npitch: Mid-range and grounded, the voice of someone who stopped needing to sound impressive about ten years ago.\nspeed: Conversational and even, slightly faster through the history, slower and precise on the actionable parts.\nvolume: Screenshare-call voice — present, direct, no performance.\nage: Late 30s.\nclarity: Clean and unambiguous, chooses Anglo-Saxon words over Latinate ones wherever possible.\nfluency: Complete sentences that know where they are going before they start.\naccent: American, East Coast — possibly Boston area, technical precision with faint blue-collar roots.\ntexture: Dark terminal, second monitor with the source code open, a mug that stopped being coffee an hour ago.\nemotion: The specific satisfaction of someone who finally gets to explain the thing that confused everyone.\ntone: Code review from someone who wants you to actually understand, not just fix the lint error.\npersonality: Has strong opinions about naming conventions and will only bring them up once.",
    "speed": 0.93
  }' \
  --output senior_eng_the_callback.wav
```

10 second or first sentence

```
The reason this function takes a callback instead of returning a promise isn't an accident - it was a deliberate choice made in 2019.
```

**Automator Script Title:** Speak with MLX TTS (senior\_eng\_the\_callback) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/senior_eng_the_callback-1_10s.wav"
REF_TEXT="The reason this function takes a callback instead of returning a promise isn't an accident - it was a deliberate choice made in 2019."
```

Automator Script

```
character_scripts/senior_eng_the_callback.sh
```
