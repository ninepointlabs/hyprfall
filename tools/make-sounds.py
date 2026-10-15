#!/usr/bin/env python3
"""Generate every sound in app/sounds/ from scratch: a tiny rock-and-roll synth.

Fuzzed square "guitars" playing power chords, a picked bass, a lead with
vibrato and bends, and a noise drum kit, mixed to 16-bit mono WAV. No
samples, no dependencies, so the audio is ours and reproducible:

    python3 tools/make-sounds.py

Both songs are original: a galloping E-minor adventure riff for the title and
a driving A-minor jungle run for the game. Nothing is lifted from an existing
song, Saturday-matinee cliffhanger serials notwithstanding.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "sounds")
random.seed(1981)

NOTE_INDEX = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
              "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def freq(name):
    """'A4' -> 440.0; None/'-' -> rest."""
    if not name or name == "-":
        return 0.0
    pitch, octave = name[:-1], int(name[-1])
    n = NOTE_INDEX[pitch] + (octave + 1) * 12
    return 440.0 * 2 ** ((n - 69) / 12)


def blank(seconds):
    return [0.0] * int(seconds * RATE)


def mix_into(buf, samples, start=0.0, gain=1.0):
    i0 = int(start * RATE)
    need = i0 + len(samples)
    if need > len(buf):
        buf.extend([0.0] * (need - len(buf)))
    for i, s in enumerate(samples):
        buf[i0 + i] += s * gain


def env(n, attack=0.004, decay=0.08, sustain=0.6, release=0.04):
    a, d, r = int(attack * RATE), int(decay * RATE), int(release * RATE)
    out = []
    for i in range(n):
        if i < a:
            v = i / max(1, a)
        elif i < a + d:
            v = 1 - (1 - sustain) * (i - a) / max(1, d)
        else:
            v = sustain
        if i > n - r:
            v *= max(0.0, (n - i) / max(1, r))
        out.append(v)
    return out


def tone(f, seconds, kind="square", duty=0.5, vibrato=0.0, slide=0.0, bend_in=0.0, **kw):
    """One oscillator. slide: fractional pitch change over the note;
    bend_in: start this many semitones flat and bend up in the first 60 ms."""
    n = int(seconds * RATE)
    e = env(n, **kw)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        ff = f * (1 + slide * t / max(seconds, 1e-6))
        if bend_in:
            ff *= 2 ** (-bend_in * max(0.0, 1 - t / 0.06) / 12)
        if vibrato and t > 0.12:
            ff *= 1 + vibrato * math.sin(2 * math.pi * 6 * t)
        phase = (phase + ff / RATE) % 1.0
        if f == 0:
            s = 0.0
        elif kind == "square":
            s = 1.0 if phase < duty else -1.0
        elif kind == "saw":
            s = 2 * phase - 1
        elif kind == "triangle":
            s = 4 * abs(phase - 0.5) - 1
        else:
            s = math.sin(2 * math.pi * phase)
        out.append(s * e[i])
    return out


def fuzz(samples, drive=2.6):
    k = math.tanh(drive)
    return [math.tanh(s * drive) / k for s in samples]


def guitar(notes, seconds, mute=False, drive=2.8):
    """A fuzzed power chord: each note twice, slightly detuned, through a clipper.
    Palm-muted chords are short and darker."""
    n = int(seconds * RATE)
    mix = [0.0] * n
    for name in notes:
        f = freq(name)
        for detune, kind in ((0.997, "saw"), (1.003, "square")):
            v = tone(f * detune, seconds, kind, 0.4,
                     decay=0.05 if mute else 0.25, sustain=0.08 if mute else 0.55, release=0.03)
            for i in range(n):
                mix[i] += v[i] * 0.5
    out = fuzz([s / max(1, len(notes)) for s in mix], drive)
    if mute:
        # crude low-pass: palm mutes are thuddy, not fizzy
        y = 0.0
        for i in range(n):
            y += 0.25 * (out[i] - y)
            out[i] = y
    return out


def power(root):
    """'E2' -> ['E2', 'B2', 'E3']"""
    f = NOTE_INDEX[root[:-1]] + int(root[-1]) * 12
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return [root, names[(f + 7) % 12] + str((f + 7) // 12), names[f % 12] + str(f // 12 + 1)]


def noise(seconds, decay=0.05, hold=1, tone_hz=0.0, tone_decay=0.03):
    n = int(seconds * RATE)
    out = []
    v = 0.0
    for i in range(n):
        if i % hold == 0:
            v = random.uniform(-1, 1)
        amp = math.exp(-i / (decay * RATE))
        s = v
        if tone_hz:
            s = 0.5 * v + 0.7 * math.sin(2 * math.pi * tone_hz * i / RATE * math.exp(-i / (tone_decay * RATE)))
        out.append(s * amp)
    return out


def kick():
    n = int(0.22 * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = 50 + 110 * math.exp(-t / 0.03)
        phase += f / RATE
        out.append(math.sin(2 * math.pi * phase) * math.exp(-t / 0.09))
    return out


def snare():
    return noise(0.18, 0.06, tone_hz=190, tone_decay=0.04)


def hat(open_=False):
    hp = []
    prev = 0.0
    for s in noise(0.12 if open_ else 0.04, 0.05 if open_ else 0.012):
        hp.append(s - prev)
        prev = s
    return hp


def crash():
    return noise(1.4, 0.45, hold=1)


def lowpass(buf, cutoff=4500):
    """One-pole low-pass: takes the fizz off the fuzz."""
    a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    y = 0.0
    for i in range(len(buf)):
        y += a * (buf[i] - y)
        buf[i] = y
    return buf


def write(name, buf, gain=0.32):
    peak = max(1e-6, max(abs(x) for x in buf))
    scale = gain / peak
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * scale)) * 32767)) for x in buf))
    print(f"{name}: {len(buf) / RATE:.2f}s")


# ------------------------------------------------------------------ band --

def drums(buf, start, beat, bars, fill_last=True, gain=1.0):
    """Straight rock beat: kick on 1 and 3 (plus the and of 3), snare on 2 and 4, eighth hats."""
    for bar in range(bars):
        t0 = start + bar * beat * 4
        last = fill_last and bar == bars - 1
        for e in range(8):
            t = t0 + e * beat / 2
            if last and e >= 4:
                # tom-ish fill into the next section
                mix_into(buf, noise(0.12, 0.05, tone_hz=[180, 150, 120, 95][e - 4], tone_decay=0.08), t, 0.55 * gain)
                continue
            mix_into(buf, hat(open_=(e == 7)), t, 0.16 * gain)
            if e in (0, 5) or (e == 4 and bar % 2):
                mix_into(buf, kick(), t, 0.85 * gain)
            if e in (2, 6):
                mix_into(buf, snare(), t, 0.5 * gain)
        if bar == 0:
            mix_into(buf, crash(), t0, 0.22 * gain)


def chug(buf, start, beat, roots, pattern, gain=0.5):
    """roots: one per bar. pattern: 8 chars per bar, 'x' open chord, 'm' palm mute, '.' rest."""
    for bar, root in enumerate(roots):
        for e, c in enumerate(pattern):
            if c == ".":
                continue
            t = start + bar * beat * 4 + e * beat / 2
            chord = power(root)
            if c == "x":
                mix_into(buf, guitar(chord, beat * 0.95), t, gain)
            else:
                mix_into(buf, guitar(chord[:2], beat * 0.45, mute=True), t, gain * 0.9)


def bass(buf, start, beat, roots, gain=0.5):
    for bar, root in enumerate(roots):
        low = root[:-1] + str(int(root[-1]) - 1)
        for e in range(8):
            t = start + bar * beat * 4 + e * beat / 2
            mix_into(buf, tone(freq(low), beat * 0.45, "triangle", decay=0.06, sustain=0.7), t, gain)


def lead(buf, start, beat, notes, gain=0.32):
    """notes: (note, beats) or (note, beats, bend). A bright square with vibrato,
    a touch of fuzz, and an echo an eighth later."""
    t = start
    for item in notes:
        note, beats = item[0], item[1]
        bend = item[2] if len(item) > 2 else 0.0
        if note != "-":
            v = fuzz(tone(freq(note), beat * beats * 0.95, "square", 0.3, vibrato=0.012, bend_in=bend,
                          decay=0.1, sustain=0.7, release=0.05), 1.6)
            mix_into(buf, v, t, gain)
            mix_into(buf, v, t + beat * 0.75, gain * 0.25)
        t += beat * beats
    return t


# ------------------------------------------------------------------ songs --

def title():
    """Galloping E-minor adventure riff: intro, verse with the hook, a lift, a turnaround."""
    beat = 60 / 152
    buf = blank(0)
    bar = beat * 4
    # 1-4: the riff alone, then drums join on 3
    riff_roots = ["E2", "E2", "E2", "E2"]
    chug(buf, 0, beat, riff_roots, "xmmxmmxm", 0.5)
    drums(buf, bar * 2, beat, 2)
    bass(buf, bar * 2, beat, ["E2", "E2"], 0.45)
    # 5-12: Em C D Em / C D Em B, with the hook on top
    verse = ["E2", "C3", "D3", "E2", "C3", "D3", "E2", "B2"]
    chug(buf, bar * 4, beat, verse, "xmmxmmxm", 0.45)
    bass(buf, bar * 4, beat, verse, 0.45)
    drums(buf, bar * 4, beat, 8)
    hook = [
        ("E4", 1), ("G4", 0.5), ("A4", 0.5), ("B4", 1.5), ("-", 0.5),
        ("C5", 1), ("B4", 0.5), ("A4", 0.5), ("G4", 2),
        ("A4", 1), ("B4", 0.5), ("D5", 0.5), ("E5", 1.5, 1.0), ("D5", 0.5),
        ("B4", 3), ("-", 1),
        ("E5", 1), ("D5", 0.5), ("C5", 0.5), ("D5", 1), ("E5", 1),
        ("F#5", 1.5, 1.0), ("E5", 0.5), ("D5", 1), ("A4", 1),
        ("B4", 1), ("E5", 1), ("G5", 1.5, 2.0), ("F#5", 0.5),
        ("E5", 1), ("D#5", 1), ("B4", 2),
    ]
    lead(buf, bar * 4, beat, hook, 0.34)
    # 13-16: the lift: big open chords, then the riff again to loop
    lift = ["C3", "D3", "E2", "E2"]
    for i, root in enumerate(lift):
        t = bar * (12 + i)
        if i < 2:
            mix_into(buf, guitar(power(root), bar * 0.98), t, 0.5)
        else:
            chug(buf, t, beat, [root], "xmmxmmxm", 0.45)
    bass(buf, bar * 12, beat, lift, 0.45)
    drums(buf, bar * 12, beat, 4)
    lead(buf, bar * 12, beat, [("G5", 2, 1.0), ("E5", 2), ("A5", 2, 2.0), ("F#5", 2), ("E5", 4, 1.0), ("-", 4)], 0.3)
    write("title.wav", lowpass(buf[: int(bar * 16 * RATE)]), gain=0.34)


def jungle():
    """The in-game loop: A-minor, driving eighths, room for sound effects."""
    beat = 60 / 144
    bar = beat * 4
    buf = blank(0)
    roots = ["A2", "A2", "F2", "G2", "A2", "A2", "C3", "G2",
             "F2", "G2", "A2", "A2", "F2", "G2", "E2", "E2"]
    pattern = "mmmxmmxm"
    chug(buf, 0, beat, roots, pattern, 0.38)
    bass(buf, 0, beat, roots, 0.4)
    drums(buf, 0, beat, 8, gain=0.8)
    drums(buf, bar * 8, beat, 8, gain=0.8)
    riff = [
        ("-", 4), ("-", 2), ("A4", 0.5), ("C5", 0.5), ("D5", 1),
        ("E5", 1.5, 1.0), ("D5", 0.5), ("C5", 1), ("A4", 1), ("G4", 2), ("-", 2),
        ("-", 4), ("-", 2), ("C5", 0.5), ("D5", 0.5), ("E5", 1),
        ("G5", 1.5, 2.0), ("E5", 0.5), ("D5", 1), ("C5", 1), ("D5", 4),
        ("-", 4), ("E5", 1), ("D5", 0.5), ("C5", 0.5), ("A4", 2),
        ("-", 4), ("C5", 1), ("D5", 1), ("E5", 2, 1.0),
        ("-", 4), ("F5", 1), ("E5", 0.5), ("D5", 0.5), ("C5", 1), ("B4", 1),
        ("G#4", 4, 1.0), ("B4", 2), ("E5", 2),
    ]
    lead(buf, 0, beat, riff, 0.24)
    write("jungle.wav", lowpass(buf[: int(bar * 16 * RATE)], 3800), gain=0.26)


# -------------------------------------------------------------------- sfx --

def sfx():
    b = blank(0); mix_into(b, tone(freq("C5"), 0.13, "square", 0.25, slide=0.9, decay=0.05, sustain=0.4)); write("jump.wav", b, 0.18)
    b = blank(0); mix_into(b, guitar(power("A3"), 0.25), 0); mix_into(b, tone(freq("E5"), 0.12, "square", 0.3, bend_in=2), 0.02, 0.4); write("grab.wav", b, 0.22)
    b = blank(0); mix_into(b, noise(0.22, 0.08, hold=3), 0, 0.6); mix_into(b, tone(freq("G4"), 0.18, "square", 0.25, slide=0.6), 0, 0.4); write("release.wav", b, 0.18)
    b = blank(0)
    for i, n in enumerate(["E5", "G#5", "B5", "E6"]):
        mix_into(b, fuzz(tone(freq(n), 0.16 if i < 3 else 0.5, "square", 0.3, vibrato=0.01, decay=0.1, sustain=0.6)), i * 0.07)
    mix_into(b, guitar(power("E3"), 0.6), 0.21, 0.5)
    write("treasure.wav", b, 0.26)
    b = blank(0); mix_into(b, noise(0.12, 0.04, hold=8), 0); mix_into(b, tone(freq("E2"), 0.12, "square", 0.4, slide=-0.4), 0, 0.6); write("bump.wav", b, 0.25)
    b = blank(0); mix_into(b, tone(freq("C5"), 0.35, "square", 0.25, slide=-0.8, decay=0.3, sustain=0.5)); mix_into(b, kick(), 0.35, 1.0); mix_into(b, noise(0.15, 0.05, hold=6), 0.35, 0.5); write("thud.wav", b, 0.3)
    b = blank(0); mix_into(b, noise(0.7, 0.22, hold=1), 0); mix_into(b, tone(freq("C5"), 0.3, "sine", slide=-0.6), 0, 0.4); write("splash.wav", b, 0.3)
    b = blank(0)
    for i in range(7):
        mix_into(b, tone(freq("A4") * (0.92 ** i), 0.09, "sine", slide=0.5, decay=0.05, sustain=0.3), i * 0.16, 0.7)
    mix_into(b, tone(freq("A2"), 1.2, "triangle", slide=-0.5, decay=0.6, sustain=0.4), 0, 0.5)
    write("sink.wav", b, 0.26)
    b = blank(0)
    for i, root in enumerate(["E3", "D3", "C3", "B2"]):
        mix_into(b, guitar(power(root), 0.16 if i < 3 else 0.7), i * 0.16, 0.6)
    mix_into(b, crash(), 0.48, 0.3)
    write("death.wav", b, 0.3)
    b = blank(0)
    for i, root in enumerate(["E3", "D3", "C3", "B2", "A2"]):
        mix_into(b, guitar(power(root), 0.45 if i < 4 else 1.6), i * 0.45, 0.6)
    mix_into(b, crash(), 1.8, 0.35)
    mix_into(b, kick(), 1.8, 0.8)
    write("gameover.wav", b, 0.3)
    b = blank(0)
    beat = 60 / 152
    for i, root in enumerate(["C3", "D3", "E3"]):
        mix_into(b, guitar(power(root), beat * (0.9 if i < 2 else 3.5)), i * beat, 0.6)
        mix_into(b, kick(), i * beat, 0.8)
    mix_into(b, crash(), beat * 2, 0.4)
    lead(b, 0, beat, [("G5", 1), ("A5", 1), ("B5", 3, 2.0)], 0.4)
    for i in range(6):
        mix_into(b, snare(), beat * 2 + i * beat / 4, 0.3)
    write("win.wav", b, 0.3)
    b = blank(0)
    mix_into(b, noise(0.3, 0.12, hold=2), 0, 0.3)
    mix_into(b, guitar(power("E2"), 0.9), 0.18, 0.7)
    mix_into(b, kick(), 0.18, 0.9)
    mix_into(b, crash(), 0.18, 0.3)
    write("start.wav", b, 0.3)
    b = blank(0); mix_into(b, tone(freq("B5"), 0.05, "square", 0.5), 0); mix_into(b, tone(freq("E5"), 0.08, "square", 0.5), 0.06); write("pause.wav", b, 0.16)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sfx()
    jungle()
    title()
