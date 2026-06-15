"""Generates a seamless synthwave BGM loop for Smash Breaker.

24-second loop, A minor, 80 BPM: warm chord pad + plucked bass + sparse
arpeggio. Stereo 22050 Hz 16-bit WAV -> SmashBreaker/audio/bgm_main.wav
"""
import math
import struct
import wave
import os

SR = 22050
BPM = 80.0
BEAT = 60.0 / BPM            # 0.75 s
BAR = BEAT * 4               # 3 s
CHORD_LEN = BAR * 2          # 6 s per chord
LOOP_LEN = CHORD_LEN * 4     # 24 s
N = int(SR * LOOP_LEN)

OUT = os.path.join(os.path.dirname(__file__), "SmashBreaker", "audio", "bgm_main.wav")

# A minor progression: Am — F — C — G (voiced mid-register)
CHORDS = [
    {"name": "Am", "pad": [220.00, 261.63, 329.63], "bass": 55.00},
    {"name": "F",  "pad": [174.61, 220.00, 261.63], "bass": 43.65},
    {"name": "C",  "pad": [196.00, 261.63, 329.63], "bass": 65.41},
    {"name": "G",  "pad": [196.00, 246.94, 293.66], "bass": 49.00},
]

L = [0.0] * N
R = [0.0] * N


def add_tone(buf, start, dur, freq, gain, attack, release, harmonics=1):
    """Soft additive tone with attack/release envelope."""
    i0 = int(start * SR)
    n = int(dur * SR)
    for i in range(n):
        idx = i0 + i
        if idx >= N:
            idx -= N          # wrap = loop-safe tails
        t = i / SR
        # Envelope
        if t < attack:
            env = t / attack
        elif t > dur - release:
            env = max(0.0, (dur - t) / release)
        else:
            env = 1.0
        v = 0.0
        for h in range(1, harmonics + 1):
            v += math.sin(2 * math.pi * freq * h * t) / h
        buf[idx] += v * gain * env


print("Rendering pad...")
for ci, chord in enumerate(CHORDS):
    t0 = ci * CHORD_LEN
    for f in chord["pad"]:
        # Two detuned layers per side for width
        add_tone(L, t0, CHORD_LEN, f * 1.0015, 0.055, 0.8, 1.2, harmonics=3)
        add_tone(L, t0, CHORD_LEN, f * 0.9985, 0.045, 0.9, 1.2, harmonics=2)
        add_tone(R, t0, CHORD_LEN, f * 0.9985, 0.055, 0.8, 1.2, harmonics=3)
        add_tone(R, t0, CHORD_LEN, f * 1.0015, 0.045, 0.9, 1.2, harmonics=2)

print("Rendering bass...")
for ci, chord in enumerate(CHORDS):
    base = ci * CHORD_LEN
    for beat in range(8):                  # 8 beats per chord segment
        t0 = base + beat * BEAT
        # Pluck: strong on 1 and 5, soft elsewhere
        gain = 0.22 if beat % 4 == 0 else 0.13
        dur = BEAT * 0.9
        add_tone(L, t0, dur, chord["bass"], gain, 0.005, dur * 0.7, harmonics=2)
        add_tone(R, t0, dur, chord["bass"], gain, 0.005, dur * 0.7, harmonics=2)

print("Rendering arp...")
SIXTEENTH = BEAT / 4
for ci, chord in enumerate(CHORDS):
    base = ci * CHORD_LEN
    notes = chord["pad"] + [f * 2 for f in chord["pad"]]   # two octaves
    step = 0
    for s in range(int(CHORD_LEN / SIXTEENTH)):
        if s % 2 == 1:
            continue                       # rest every other 16th = sparse
        t0 = base + s * SIXTEENTH
        f = notes[step % len(notes)]
        step += 1
        dur = SIXTEENTH * 1.8
        pan_left = (step % 2 == 0)
        main, other = (L, R) if pan_left else (R, L)
        add_tone(main, t0, dur, f, 0.085, 0.004, dur * 0.8)
        # Echo into the opposite channel half a beat later
        add_tone(other, t0 + BEAT * 0.5, dur, f, 0.038, 0.004, dur * 0.8)

print("Loop crossfade + normalize...")
FADE = int(SR * 0.25)
for i in range(FADE):
    w = i / FADE
    for buf in (L, R):
        buf[N - FADE + i] = buf[N - FADE + i] * (1.0 - w) + buf[i] * w

peak = max(max(abs(v) for v in L), max(abs(v) for v in R))
scale = 0.82 / peak
print(f"peak {peak:.3f} -> scaling {scale:.3f}")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with wave.open(OUT, "w") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    frames = bytearray()
    for i in range(N):
        frames += struct.pack(
            "<hh",
            int(max(-1.0, min(1.0, L[i] * scale)) * 32767),
            int(max(-1.0, min(1.0, R[i] * scale)) * 32767),
        )
    w.writeframes(bytes(frames))

print(f"OK: {OUT}  ({LOOP_LEN:.0f}s loop, {os.path.getsize(OUT)//1024} KB)")
