#!/usr/bin/env python3
"""Synthesizes the app's shutter sound effects as small WAV files.

Pure stdlib (wave + math + random) — no external audio assets needed.
Run: python tool/gen_sounds.py
"""
import math
import random
import struct
import wave
import os

SR = 44100


def env_exp(n, total, decay):
    return math.exp(-decay * (n / total))


def noise_burst(duration_s, decay, lowpass=1.0, seed=0):
    n_samples = int(SR * duration_s)
    rnd = random.Random(seed)
    raw = [rnd.uniform(-1, 1) for _ in range(n_samples)]
    # simple one-pole lowpass to soften harshness when lowpass < 1
    out = []
    prev = 0.0
    alpha = lowpass
    for i, v in enumerate(raw):
        prev = prev + alpha * (v - prev)
        out.append(prev * env_exp(i, n_samples, decay))
    return out


def sine_burst(freq, duration_s, decay, amp=1.0, seed=0):
    n_samples = int(SR * duration_s)
    out = []
    for i in range(n_samples):
        t = i / SR
        out.append(amp * math.sin(2 * math.pi * freq * t) * env_exp(i, n_samples, decay))
    return out


def mix(*layers, offsets_s=None):
    if offsets_s is None:
        offsets_s = [0.0] * len(layers)
    total_len = max(int(SR * off) + len(layer) for layer, off in zip(layers, offsets_s))
    buf = [0.0] * total_len
    for layer, off in zip(layers, offsets_s):
        start = int(SR * off)
        for i, v in enumerate(layer):
            buf[start + i] += v
    peak = max(1e-6, max(abs(v) for v in buf))
    if peak > 1:
        buf = [v / peak for v in buf]
    return buf


def write_wav(path, samples, gain=0.9):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for v in samples:
            s = max(-1.0, min(1.0, v * gain))
            frames += struct.pack('<h', int(s * 32767))
        w.writeframes(bytes(frames))
    print('wrote', path, f'{len(samples)/SR*1000:.0f}ms')


def build_click_shutter():
    # Sharp digital click: bright noise transient + a quick mechanical clack.
    click = noise_burst(0.02, decay=40, lowpass=0.9, seed=1)
    clack = sine_burst(1800, 0.03, decay=30, amp=0.6, seed=2)
    thunk = sine_burst(140, 0.05, decay=18, amp=0.5, seed=3)
    return mix(click, clack, thunk, offsets_s=[0.0, 0.004, 0.01])


def build_soft():
    # Muffled, lower-pitched shutter for cheap/plastic cameras.
    click = noise_burst(0.035, decay=18, lowpass=0.35, seed=11)
    thunk = sine_burst(90, 0.09, decay=10, amp=0.55, seed=12)
    return mix(click, thunk, offsets_s=[0.0, 0.012])


def build_boot_chime():
    # Two-tone rising electronic "power on" chirp, not a musical jingle.
    low = sine_burst(440, 0.09, decay=14, amp=0.55, seed=21)
    high = sine_burst(660, 0.12, decay=12, amp=0.55, seed=22)
    return mix(low, high, offsets_s=[0.0, 0.08])


def build_focus_beep():
    # A single short, high, fast-decaying confirmation beep.
    return sine_burst(1200, 0.05, decay=60, amp=0.5, seed=31)


def build_click():
    # Very short, quiet mechanical click for generic UI buttons — distinct
    # from (and quieter than) the shutter sound so it never competes.
    click = noise_burst(0.012, decay=55, lowpass=0.4, seed=41)
    thunk = sine_burst(120, 0.02, decay=35, amp=0.25, seed=42)
    return mix(click, thunk, offsets_s=[0.0, 0.003])


def build_error_beep():
    # Two short low "denied" tones in quick succession.
    first = sine_burst(220, 0.07, decay=20, amp=0.5, seed=51)
    second = sine_burst(220, 0.07, decay=20, amp=0.5, seed=52)
    return mix(first, second, offsets_s=[0.0, 0.12])


# --- Camera Skins: per-skin shutter + boot-chime sound identities ---------
# Only these two "identity-bearing" sounds vary per skin (focus/click/error
# stay global, shared, utilitarian). Night Vision reuses shutter_click.wav
# and boot_chime.wav verbatim; Archive reuses shutter_soft.wav verbatim —
# neither needs a new file.


def build_shutter_silver2003():
    # Crisp, brighter, shorter — clean flash photography, no low thunk.
    click = noise_burst(0.015, decay=50, lowpass=0.85, seed=61)
    clack = sine_burst(2400, 0.02, decay=45, amp=0.6, seed=62)
    return mix(click, clack, offsets_s=[0.0, 0.003])


def build_boot_chime_silver2003():
    # A single crisp ascending tone — reads "clean," not "electronic."
    return sine_burst(880, 0.08, decay=16, amp=0.55, seed=63)


def build_shutter_oceanic():
    # Longer decay, heavier lowpass, lower thunk — a muffled "underwater"
    # softness.
    click = noise_burst(0.04, decay=14, lowpass=0.22, seed=71)
    thunk = sine_burst(70, 0.12, decay=7, amp=0.55, seed=72)
    return mix(click, thunk, offsets_s=[0.0, 0.02])


def build_boot_chime_oceanic():
    # Slower, legato two-tone at lower pitches, more overlap than the
    # default chime.
    low = sine_burst(330, 0.14, decay=10, amp=0.5, seed=73)
    high = sine_burst(440, 0.16, decay=8, amp=0.5, seed=74)
    return mix(low, high, offsets_s=[0.0, 0.06])


def build_boot_chime_archive():
    # Three short mechanical clicks — a disposable's film-advance
    # thumbwheel, not an electronic chime real disposables don't have.
    c1 = noise_burst(0.015, decay=50, lowpass=0.5, seed=81)
    c2 = noise_burst(0.015, decay=50, lowpass=0.5, seed=82)
    c3 = noise_burst(0.015, decay=50, lowpass=0.5, seed=83)
    return mix(c1, c2, c3, offsets_s=[0.0, 0.09, 0.18])


def build_shutter_industrial():
    # Harsher/metallic — a bright ring layered on the standard click stack.
    click = noise_burst(0.02, decay=40, lowpass=0.9, seed=91)
    clack = sine_burst(1800, 0.03, decay=30, amp=0.6, seed=92)
    thunk = sine_burst(140, 0.05, decay=18, amp=0.5, seed=93)
    ring = sine_burst(3200, 0.015, decay=50, amp=0.4, seed=94)
    return mix(click, clack, thunk, ring, offsets_s=[0.0, 0.004, 0.01, 0.004])


def build_boot_chime_industrial():
    # Two short hard beeps, no legato — an instrument-panel self-test, not
    # a friendly chirp.
    first = sine_burst(300, 0.05, decay=25, amp=0.55, seed=95)
    second = sine_burst(300, 0.05, decay=25, amp=0.55, seed=96)
    return mix(first, second, offsets_s=[0.0, 0.09])


if __name__ == '__main__':
    base = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
    write_wav(os.path.join(base, 'shutter_click.wav'), build_click_shutter())
    write_wav(os.path.join(base, 'shutter_soft.wav'), build_soft())
    write_wav(os.path.join(base, 'boot_chime.wav'), build_boot_chime())
    write_wav(os.path.join(base, 'focus_beep.wav'), build_focus_beep())
    write_wav(os.path.join(base, 'click.wav'), build_click())
    write_wav(os.path.join(base, 'error_beep.wav'), build_error_beep())
    write_wav(os.path.join(base, 'shutter_silver2003.wav'), build_shutter_silver2003())
    write_wav(os.path.join(base, 'boot_chime_silver2003.wav'), build_boot_chime_silver2003())
    write_wav(os.path.join(base, 'shutter_oceanic.wav'), build_shutter_oceanic())
    write_wav(os.path.join(base, 'boot_chime_oceanic.wav'), build_boot_chime_oceanic())
    write_wav(os.path.join(base, 'boot_chime_archive.wav'), build_boot_chime_archive())
    write_wav(os.path.join(base, 'shutter_industrial.wav'), build_shutter_industrial())
    write_wav(os.path.join(base, 'boot_chime_industrial.wav'), build_boot_chime_industrial())
