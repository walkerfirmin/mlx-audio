## 26. The Energized Tech Lead Who Actually Likes Standups

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Alright, yesterday I got the auth middleware refactor merged — finally — and unblocked Priya on the session work. Today I'\''m moving straight into the rate limiting layer, should have a draft PR up before lunch. No blockers on my end but I do want to flag something for after standup — the staging environment has been flaky since Tuesday and I think it'\''s worth five minutes with whoever owns infra this week before it becomes someone'\''s blocker instead of just an annoyance. That'\''s me, who'\''s next?",
    "voice": "gender: Male.\npitch: Bright mid-range, morning energy that is genuine rather than performed.\nspeed: Brisk and efficient, the pace of someone who respects that six other people are waiting.\nvolume: Video-call presence — clear and forward, no mumbling, no trailing off.\nage: Early 30s.\nclarity: Sharp and direct, technical terms delivered with familiarity, no over-explanation.\nfluency: Tight structured sentences, done-doing-blockers in muscle memory, no wasted words.\naccent: American, Pacific Northwest — clean and informal, slight startup cadence.\ntexture: Standing desk, second coffee, Slack already open on the second monitor.\nemotion: Genuinely caffeinated, finds the coordination satisfying rather than ceremonial.\ntone: The person who makes standup actually useful by modeling what useful sounds like.\npersonality: Has strong opinions about standup hygiene and expresses them entirely through example.",
    "speed": 1.02
  }' \
  --output alex_standup_model.wav
```

10 second or first sentence

```
Alright, yesterday I got the auth middleware refactor merged - finally - and unblocked Priya on the session work.
```

**Automator Script Title:** Speak with MLX TTS (alex\_standup\_model) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/alex_standup_model-1_10s.wav"
REF_TEXT="Alright, yesterday I got the auth middleware refactor merged - finally - and unblocked Priya on the session work."
```

Automator Script

```
character_scripts/alex_standup_model-1.sh
```
