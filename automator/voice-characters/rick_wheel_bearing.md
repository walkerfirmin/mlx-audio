## 34. The Mechanic Explaining What's Wrong With Your Car

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Alright so the good news is it'\''s not the transmission, which is what I was worried about when you described the noise. The bad news is it'\''s the front left wheel bearing and it'\''s pretty far gone. You can hear it on the lift — that grinding you'\''ve been hearing, that'\''s it. Now you can drive on it a little longer, I'\''m not going to lie to you, but I'\''m also not going to tell you it'\''s fine because it'\''s not fine. It'\''ll get worse faster than you'\''d expect and when it goes it can take the hub with it, and then we'\''re having a different conversation about a bigger number. I can have it done by four if you want to leave it.",
    "voice": "gender: Male.\npitch: Mid-range and matter-of-fact, the voice of someone who has delivered this news in various forms for twenty years.\nspeed: Workday pace, unhurried but not slow, the rhythm of someone who has three other cars to look at today.\nvolume: Shop voice — a little loud from years of talking over air tools, moderated for the office.\nage: Mid 40s.\nclarity: Plain and direct, technical terms translated without condescension, knows you are not a mechanic.\nfluency: Practical sentences with an honest structure — good news first, bad news straight, options last.\naccent: New England, Massachusetts — not heavy Boston, the flatter version from further west, Worcester maybe.\ntexture: Grease on the counter, the smell of a shop that has been a shop for a long time.\nemotion: Straightforward professional honesty — not unkind, not softening it beyond usefulness.\ntone: The mechanic who tells you the truth because he figures you can handle it and deserve to.\npersonality: Has a waiting room full of people and is treating you like you are the only one.",
    "speed": 0.93
  }' \
  --output rick_wheel_bearing.wav
```

10 second or first sentence

```
Alright so the good news is it's not the transmission, which is what I was worried about when you described the noise.
```

**Automator Script Title:** Speak with MLX TTS (rick\_wheel\_bearing) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/rick_wheel_bearing_10s.wav"
REF_TEXT="Alright so the good news is it's not the transmission, which is what I was worried about when you described the noise, the bad news is its the front left wheel"
```

Automator Script

```
character_scripts/rick_wheel_bearing.sh
```
