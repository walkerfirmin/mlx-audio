## 11. The Paranoid Conspiracy Podcast Host

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "I'\''m not saying they planned it. I'\''m saying — and this is an important distinction — I'\''m saying the incentives were already in place for it to happen, and nobody who benefited from it happening did anything to stop it. Which is either negligence or strategy, and I'\''ll let you decide which one requires less coordination. That'\''s all I'\''m saying. I'\''ve been doing this show for six years. I don'\''t need to overstate things anymore. The understated version is alarming enough. If you'\''ve been listening since the beginning, you know I'\''ve been wrong about some things. I'\''ve been right about more. I'\''m not asking you to trust me. I'\''m asking you to look at the documents I linked in the description and decide for yourself. That'\''s it. That'\''s always been it.",
    "voice": "gender: Male.\npitch: Mid-range with upward spikes on words he wants flagged — emphasis as punctuation.\nspeed: Modulated radio pace with sudden accelerations when the point is building.\nvolume: Podcast-mic close, occasionally drops to near-whisper for effect then snaps back.\nage: Late 30s.\nclarity: Overly crisp, broadcaster-trained, every word carved out of the air with intention.\nfluency: Constructed spontaneity — sounds like he'\''s thinking out loud but has rehearsed every turn.\naccent: Generic American broadcast neutral, all geography sanded off deliberately.\ntexture: Soundproofing foam and blue light, three monitors and a folder of screenshots.\nemotion: Controlled intensity — the restraint is the threat, not the volume.\ntone: Reasonable man patiently explaining why you should be less calm than you are.\npersonality: Genuinely believes he is the last honest person with a microphone and finds that more exhausting than exciting.",
    "speed": 0.95
  }' \
  --output derek_understated_version.wav
```

10 second or first sentence

```
I'm not saying they planned it. I'm saying - and this is an important distinction - I'm saying the incentives were already in place for it to happen.
```

**Automator Script Title:** Speak with MLX TTS (derek\_understated\_version) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/derek_understated_version-1_10s.wav"
REF_TEXT="Im not saying they planned it. Im saying and this is an important distinction Im saying the incentives were already in place for it to happen."
```

Automator Script

```
character_scripts/derek_understated_version.sh
```
