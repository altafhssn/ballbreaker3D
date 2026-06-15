"""Generates synthesized SFX WAVs for Smash Breaker into SmashBreaker/audio/."""
import math
import os
import random
import struct
import wave

SR = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "SmashBreaker", "audio")
os.makedirs(OUT_DIR, exist_ok=True)

random.seed(42)


def write_wav(name, samples):
    peak = max(0.0001, max(abs(s) for s in samples))
    scale = 0.9 / peak if peak > 0.9 else 1.0
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
            for s in samples
        )
        w.writeframes(frames)
    print(f"  {name}.wav  ({len(samples)/SR:.2f}s)")


def silence(dur):
    return [0.0] * int(SR * dur)


def tone(freq_start, freq_end, dur, vol=0.5, shape="sine", decay=2.0, attack=0.004):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq_start + (freq_end - freq_start) * t
        phase += 2.0 * math.pi * f / SR
        if shape == "sine":
            v = math.sin(phase)
        elif shape == "square":
            v = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            v = random.uniform(-1, 1)
        env = (1.0 - t) ** decay
        a = min(1.0, (i / SR) / attack) if attack > 0 else 1.0
        out.append(v * vol * env * a)
    return out


def noise_burst(dur, vol=0.5, decay=2.5, smooth=1):
    n = int(SR * dur)
    raw = [random.uniform(-1, 1) for _ in range(n)]
    if smooth > 1:
        sm = []
        acc = 0.0
        for i, v in enumerate(raw):
            acc += v
            if i >= smooth:
                acc -= raw[i - smooth]
            sm.append(acc / smooth)
        raw = sm
    return [v * vol * (1.0 - i / n) ** decay for i, v in enumerate(raw)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


print("Generating SFX:")

# Gameplay
write_wav("brick_hit", tone(900, 500, 0.07, 0.45, "square", 3.0))
write_wav("brick_break", mix(noise_burst(0.14, 0.5, 3.0, 4), tone(480, 280, 0.12, 0.35, "sine", 2.5)))
write_wav("paddle_hit", mix(tone(210, 150, 0.09, 0.8, "sine", 2.0), noise_burst(0.02, 0.15, 2.0, 2)))
write_wav("wall_hit", tone(1100, 1050, 0.04, 0.25, "sine", 3.0))
write_wav("explosion", mix(noise_burst(0.35, 0.8, 2.2, 8), tone(75, 45, 0.3, 0.55, "sine", 1.8)))
write_wav("powerup", seq(tone(523, 523, 0.07, 0.5), tone(659, 659, 0.07, 0.5), tone(784, 784, 0.09, 0.5, "sine", 1.5)))
write_wav("life_lost", tone(400, 150, 0.4, 0.5, "sine", 1.6))
write_wav("level_complete", seq(
    tone(523, 523, 0.11, 0.45), tone(659, 659, 0.11, 0.45),
    tone(784, 784, 0.11, 0.45), tone(1046, 1046, 0.2, 0.5, "sine", 1.8)))
write_wav("game_over", mix(tone(320, 70, 0.8, 0.6, "sine", 1.4), noise_burst(0.5, 0.12, 2.0, 12)))

# UI
write_wav("click", tone(1500, 1400, 0.03, 0.3, "sine", 3.0))
write_wav("purchase", seq(tone(659, 659, 0.09, 0.5), tone(1046, 1046, 0.14, 0.5, "sine", 1.8)))
write_wav("denied", tone(180, 160, 0.18, 0.3, "square", 1.5))

print("Done ->", OUT_DIR)
