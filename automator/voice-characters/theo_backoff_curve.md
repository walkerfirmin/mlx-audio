## 25. The Late-Night Internal Tools Engineer Doing a Walkthrough

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "So this part of the pipeline is mine, which means I can actually tell you why it works the way it does instead of just describing it. The retry logic looks weird because it is weird — but it'\''s weird for a reason. We have three downstream services with completely different failure profiles. Service A fails fast and recovers fast. Service B fails slow and recovers slow. Service C fails randomly with no pattern we have ever successfully modeled. If you use a standard exponential backoff across all three, you'\''re optimizing for none of them. What we do instead is maintain a per-service failure profile that updates in real time and adjusts the backoff curve dynamically. Is it overengineered? Absolutely. Did we need it? We did not need it until the day we very much needed it.",
    "voice": "gender: Male.\npitch: Relaxed mid-range, the pitch of someone on a Loom recording at 11pm who is comfortable with the camera.\nspeed: Informal walkthrough pace — natural breathing, occasional self-interruption, real thinking audible.\nvolume: Screen-recording close, casual and unproduced, the sound of a voice memo that became documentation.\nage: Early 30s.\nclarity: Natural clarity without broadcast polish — technically precise, colloquially delivered.\nfluency: Run-ons that resolve cleanly, asides that earn their place, the rhythm of someone who codes the way they talk.\naccent: British, northern England — Yorkshire or Manchester, practical and direct, no time for decoration.\ntexture: Laptop fan, one window open, the particular focus of a person alone with a problem they have already solved.\nemotion: The satisfied exhaustion of someone explaining a system they built and then actually had to use.\ntone: Internal Loom video that gets shared beyond the team because it'\''s the only place the real explanation lives.\npersonality: Documents the why because he has been the person who inherited a system with only the what.",
    "speed": 0.94
  }' \
  --output theo_backoff_curve.wav
```

10 second or first sentence

```
So this part of the pipeline is mine, which means I can actually tell you why it works the way it does instead of just describing it.
```

**Automator Script Title:** Speak with MLX TTS (theo\_backoff\_curve) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/theo_backoff_curve_10s.wav"
REF_TEXT="So this part of the pipeline is mine, which means I can actually tell you why it works the way it does instead of just describing it."
```

Automator Script

```
character_scripts/theo_backoff_curve.sh
```
