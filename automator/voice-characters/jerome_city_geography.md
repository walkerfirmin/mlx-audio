## 36. The Rideshare Driver Who Wants to Talk

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "input": "You know what'\''s interesting about this job — and I know everybody probably tells you their whole life story, I'\''ll keep it short — but you see the city different when you'\''re driving it all day. Like there'\''s a version of this city that only exists between midnight and four in the morning, and it'\''s a completely different place than the nine to five version. Different people, different energy, different problems. I'\''ve been doing this six years. I'\''ve got a whole geography in my head that'\''s not on any map. Just — this block is where people cry. This neighborhood is where people are going somewhere good. This street, every time, somebody'\''s leaving something behind. I don'\''t know how you'\''d put that on a map but it'\''s real.",
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "voice": "gender: Male.\npitch: Conversational mid-range, the voice of someone who talks for a living and has gotten good at it.\nspeed: Relaxed and easy, the pace of a fifteen minute ride with no traffic.\nvolume: Front-seat voice, turned slightly toward the passenger, warm and inclusive.\nage: Late 30s.\nclarity: Natural and unpolished, clarity through rhythm rather than precision.\nfluency: Spoken-word flow, thinks while talking and lands somewhere he did not know he was going.\naccent: Caribbean-American, Haitian roots, Miami raised — French rhythm underneath American English, musical and warm.\ntexture: Car air freshener, city lights through glass, the particular intimacy of a stranger'\''s vehicle at night.\nemotion: Genuine philosophical curiosity about the work — has found meaning in it and is slightly surprised by that.\ntone: Observation offered freely to whoever happens to be in the backseat.\npersonality: Remembers every interesting passenger. Wonders if they remember him.",
    "speed": 0.92
  }' \
  --output jerome_city_geography.wav
```

10 second or first sentence

```
You know what's interesting about this job - and I know everybody probably tells you their whole life story, I'll keep it short - but you see the city different.
```

**Automator Script Title:** Speak with MLX TTS (jerome\_city\_geography) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/jerome_city_geography_10s.wav"
REF_TEXT="You know what's interesting about this job - and I know everybody probably tells you their whole life story, I'll keep it short - but you see the city different."
```

Automator Script

```
character_scripts/jerome_city_geography.sh
```
