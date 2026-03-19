## 33. The Neighbor Talking Over the Fence

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Oh I'\''m telling you, the moment I put that second layer of mulch down, those hostas just took off. I don'\''t know why I waited so long. Frank kept saying do it in the fall, do it in the fall, and I kept saying I'\''ll get to it, I'\''ll get to it. Well I got to it in March and they don'\''t know the difference apparently. Plants don'\''t read the calendar I suppose. You having trouble with yours? Because I'\''ve got more bags in the garage than I know what to do with, Tom brought way too many home — you know how he is at the hardware store. You'\''re welcome to them if you want.",
    "voice": "gender: Female.\npitch: Warm upper-mid range, the voice of someone who finds conversation genuinely nourishing.\nspeed: Easy and flowing, the pace of a Sunday afternoon with nowhere to be.\nvolume: Outdoor carrying voice, fence-conversation calibrated, a little louder than inside.\nage: Late 50s.\nclarity: Natural and unhurried, clarity comes from warmth not precision.\nfluency: Easy run-ons, digresses happily, always circles back.\naccent: Southern American, Georgia or Tennessee — rounded vowels, comfortable drawl, hospitality in the syntax.\ntexture: Backyard in late morning, mulch smell, the sound of a hose running somewhere nearby.\nemotion: Genuine neighborly pleasure, the satisfaction of a person who likes where she lives and who lives near her.\ntone: Advice that is also an invitation that is also just talking because talking is good.\npersonality: Has the bags of mulch. Will actually give you the bags of mulch. Has already decided she likes you.",
    "speed": 0.91
  }' \
  --output linda_hostas_mulch.wav
```

10 second or first sentence

```
Oh I'm telling you, the moment I put that second layer of mulch down, those hostas just took off. I don't know why I waited so long.
```

**Automator Script Title:** Speak with MLX TTS (linda\_hostas\_mulch) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/linda_hostas_mulch_10s.wav"
REF_TEXT="Oh I'm telling you, the moment I put that second layer of mulch down, those hostas just took off. I don't know why I waited so long, frank said do it in the fall"
```

Automator Script

```
character_scripts/linda_hostas_mulch.sh
```
