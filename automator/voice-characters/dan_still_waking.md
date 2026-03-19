## 27. The Senior Dev Who Is Clearly Still Waking Up

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Yeah so. Yesterday. I was in that database migration issue most of the day — I think I sent a message about it in the channel. Still not fully resolved, there'\''s a schema conflict on the users table that'\''s blocking the deploy. Today same thing, trying to get that closed out. If it'\''s not done by noon I'\''m going to ask for another set of eyes on it because I'\''ve been staring at it long enough that I'\''m probably not seeing something obvious. No other blockers. That'\''s it.",
    "voice": "gender: Male.\npitch: Low and slightly rough, a voice still finding its morning register.\nspeed: Slow to start, picks up slightly by the blockers section once the brain is engaged.\nvolume: A notch quieter than ideal, the volume of someone who has not yet fully committed to being awake.\nage: Mid 30s.\nclarity: Clear enough, occasional slight slurring on connective words, precision reserved for the actual technical content.\nfluency: Honest pauses while retrieving yesterday from memory, no filler energy.\naccent: American, general — no strong regional marker, the accent of someone who moved around.\ntexture: Kitchen table, laptop propped up, mug that is doing essential work right now.\nemotion: Functional but unpolished, the specific authenticity of someone who did not pretend to be a morning person.\ntone: Status update delivered by a person, not a role — slightly more human than the format expects.\npersonality: Will be sharp by 10am, is doing his best at 9:02.",
    "speed": 0.91
  }' \
  --output dan_still_waking.wav
```

10 second or first sentence

```
Yeah so. Yesterday. I was in that database migration issue most of the day - I think I sent a message about it in the channel.
```

**Automator Script Title:** Speak with MLX TTS (dan\_still\_waking) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/dan_still_waking-1_10s.wav"
REF_TEXT="Yeah so. Yesterday. I was in that database migration issue most of the day - I think I sent a message about it in the channel."
```

Automator Script

```
character_scripts/dan_still_waking.sh
```
