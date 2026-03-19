## 28. The Overloaded PM Keeping It Together

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "Good morning everyone, quick one from me. Yesterday was mostly stakeholder syncs and getting the Q2 scope doc into a reviewable state — I'\''ll drop the link in the channel right after this, please do look at it before EOD because we have the planning session Thursday and I want it not to be a surprise to anyone. Today I'\''m finalizing acceptance criteria for the three tickets that go into sprint planning tomorrow, and I have a one-on-one with Marcus at two that I'\''m hoping resolves the dependency question we'\''ve been circling. Blocker — technically not a blocker but flagging it — I need someone to confirm the API contract change from last week is in the changelog before I finalize the external comms. Whoever owns that, Slack me. Thanks, that'\''s me.",
    "voice": "gender: Female.\npitch: Professional mid-range, controlled and forward, the voice of someone running four things simultaneously.\nspeed: Efficient and slightly compressed, the pace of a calendar with no gaps in it.\nvolume: Meeting-room clear, projects without effort, every word recoverable.\nage: Mid 30s.\nclarity: Precise and structured, bullet-point brain made audible, no sentence left unfinished.\nfluency: Organized run-ons that resolve cleanly, asides bracketed and closed.\naccent: American, East Coast — possibly DC or New York, the neutral-professional accent of someone in meetings all day.\ntexture: Laptop camera on, ring light, three browser windows minimized, one open.\nemotion: Controlled urgency — a lot is happening and she has decided that projecting calm is part of the job.\ntone: Update that is also a coordination mechanism that is also a gentle pressure campaign.\npersonality: Knows that clarity in standup saves forty minutes of Slack thread later and optimizes accordingly.",
    "speed": 1.0
  }' \
  --output jordan_pm_tight_schedule.wav
```

10 second or first sentence

```
Good morning everyone, quick one from me. Yesterday was mostly stakeholder syncs and getting the Q2 scope doc into a reviewable state.
```

**Automator Script Title:** Speak with MLX TTS (jordan\_pm\_tight\_schedule) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/jordan_pm_tight_schedule-1_10s.wav"
REF_TEXT="Good morning everyone, quick one from me. Yesterday was mostly stakeholder syncs and getting the Q2 scope doc into a reviewable state, i'll drop the link in the"
```

Automator Script

```
character_scripts/jordan_pm_tight_schedule.sh
```
