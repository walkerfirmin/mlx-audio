## 20. The Stoic Systems Architect Near Retirement

```bash
curl http://127.0.0.1:8002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
    "input": "There are three things this system guarantees and two things it does not. I will tell you all five. Guaranteed: message delivery, ordering within a partition, and replay from any committed offset. Not guaranteed: ordering across partitions, and exactly-once delivery without idempotent producers configured on your end. Most outages I have seen in fifteen years trace back to someone who read the first three and stopped. The documentation does not hide the last two. They are on page four. People do not read page four. I do not know how to fix that with documentation. I mention it here because you are reading this, which means you are the kind of person who reads page four. Do not let the system surprise you anyway. Know what it does not do as well as you know what it does.",
    "voice": "gender: Male.\npitch: Deep and settled, the voice of someone who has been right about enough things that he no longer needs to perform certainty.\nspeed: Methodical and exact, the pace of someone for whom precision is not effort but habit.\nvolume: Even and moderate — never louder for emphasis, emphasis handled entirely by structure.\nage: Late 50s.\nclarity: Architectural clarity — each sentence a load-bearing element, nothing decorative.\nfluency: Numbered in his mind if not on the page, moves through information the way you move through a system diagram.\naccent: German-accented English — precise vowels, unhurried, consonants engineered rather than spoken.\ntexture: Whiteboard covered in boxes and arrows, the smell of a server room he has long since stopped noticing.\nemotion: Calm that was earned, not assumed — the stillness of someone who has seen the failure modes.\ntone: A man handing over the keys to a building he designed and trusts, to someone he hopes will deserve it.\npersonality: Does not simplify things that should not be simplified, and simplifies everything else without being asked.",
    "speed": 1.2
  }' \
  --output dieter_page_four.wav
```

10 second or first sentence

```
There are three things this system guarantees and two things it does not. I will tell you all five.
```

**Automator Script Title:** Speak with MLX TTS (dieter\_page\_four) (Quick Action)

```
REF_AUDIO="/Users/admin/Music/sample-audio-clips/dieter_page_four-1_10s.wav"
REF_TEXT="There are three things this system guarantees and two things it does not. I will tell you all five."
```

Automator Script

```
character_scripts/dieter_page_four.sh
```
