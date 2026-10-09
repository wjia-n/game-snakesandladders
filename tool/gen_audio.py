#!/usr/bin/env python3
"""Synthesize Snakes & Ladders SFX + music loops as 16-bit mono WAVs.

Physical identity: ivory die rattling in a carved wooden tray, wooden token
knocks, rope-and-timber ladder climbs, a hand-painted serpent's slide,
brass fanfare for the crown. Warm parlour music-box loops. No external samples.
"""
import numpy as np, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(42)

def save(name, x):
    x = np.clip(x, -1, 1)
    pcm = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f'{name}: {len(x)/SR:.2f}s')

def env(n, a=0.002, d=0.05):
    t = np.arange(n) / SR
    e = np.ones(n)
    na = max(1, int(a * SR)); nd = max(1, int(d * SR))
    e[:na] = np.linspace(0, 1, na)
    e[na:na+nd] = np.linspace(1, 0, min(nd, n-na))
    if na+nd < n: e[na+nd:] = 0
    return e

def knock(freq=180, dur=0.09, noise_mix=0.5):
    """Short woody knock: damped sine + noise burst."""
    n = int(dur * SR); t = np.arange(n)/SR
    tone = np.sin(2*np.pi*freq*t) * np.exp(-t*38)
    nz = rng.standard_normal(n) * np.exp(-t*90) * noise_mix
    return (tone + nz) * env(n, d=dur*0.7)

def click():
    # brass-ish button tick: bright short knock
    n = int(0.09*SR); t = np.arange(n)/SR
    x = np.zeros(n)
    x += np.sin(2*np.pi*1180*t)*np.exp(-t*120)*0.35
    k = knock(340, 0.07, 0.3)*0.9
    x[:len(k)] += k
    return x * env(n, d=0.08)

def dice():
    # ivory die rattling in a wooden tray: 4-5 small clatters
    n = int(0.55*SR); x = np.zeros(n)
    for i, dt in enumerate([0.0, 0.09, 0.20, 0.30, 0.40]):
        s = int(dt*SR)
        k = knock(300+rng.integers(-60, 60), 0.06, 0.75) * (0.9 - 0.12*i)
        x[s:s+len(k)] += k[:max(0, min(len(k), n-s))]
    return x * env(n, a=0.002, d=0.5)

def hop():
    # token hopping one square: single warm wooden knock
    return knock(230, 0.08, 0.45)

def ladder():
    # climbing: rising marimba-like wooden arpeggio
    n = int(1.0*SR); t = np.arange(n)/SR; x = np.zeros(n)
    for i, f in enumerate([392.0, 494.0, 587.0, 784.0]):
        s = int(i*0.13*SR); m = int(0.4*SR)
        tone = np.sin(2*np.pi*f*np.arange(m)/SR)*np.exp(-np.arange(m)/(0.12*SR))
        x[s:s+m] += tone*0.45
    # rope creak swish underneath
    sw = rng.standard_normal(n)*np.exp(-((t-0.25)/0.25)**2)*0.05
    return (x+sw) * env(n, a=0.004, d=0.95)

def snake():
    # serpent slide: descending filtered hiss + low wooden rumble
    n = int(1.1*SR); t = np.arange(n)/SR
    nz = rng.standard_normal(n)
    # crude lowpass: moving average
    k = np.ones(40)/40
    hiss = np.convolve(nz, k, mode='same')
    f0, f1 = 900.0, 180.0
    am = 0.5 + 0.5*np.sin(2*np.pi*(f0 + (f1-f0)*t/(n/SR))*t)
    x = hiss * am * 0.5 * np.exp(-t*2.2)
    # low descending slide-whistle-ish tone
    fr = 520*np.exp(-t*1.8) + 120
    phase = np.cumsum(2*np.pi*fr/SR)
    x += np.sin(phase)*0.18*np.exp(-t*2.5)
    return x * env(n, a=0.01, d=1.05)

def invalid():
    # overshoot: soft wooden bonk, dull
    n = int(0.25*SR); t = np.arange(n)/SR
    x = np.zeros(n)
    x += np.sin(2*np.pi*130*t)*np.exp(-t*22)*0.7
    k = knock(120, 0.12, 0.3)*0.5
    x[:len(k)] += k
    return x * env(n, d=0.22)

def game_start():
    # three knocks on the parlour table: knock-knock-KNOCK
    n = int(0.8*SR); x = np.zeros(n)
    for i, dt in enumerate([0.0, 0.17, 0.36]):
        s = int(dt*SR); k = knock(190, 0.11, 0.5)*(0.7+0.3*i)
        x[s:s+len(k)] += k
    return x * env(n, a=0.002, d=0.75)

def win_phrase():
    # brass fanfare + crown shimmer: rising arpeggio, warm inharmonic brass
    n = int(2.0*SR); t = np.arange(n)/SR; x = np.zeros(n)
    for i, f in enumerate([261.63, 329.63, 392.0, 523.25, 659.25, 783.99]):
        s = int(i*0.14*SR)
        tone = np.zeros(int(0.9*SR)); tt = np.arange(len(tone))/SR
        for mult, a in [(1, 0.5), (2, 0.22), (2.76, 0.10), (4.2, 0.05)]:
            tone += a*np.sin(2*np.pi*f*mult*tt)*np.exp(-tt*3.2)
        x[s:s+len(tone)] += tone*0.5
    # shimmer
    sh = np.sin(2*np.pi*2093*t)*np.exp(-np.maximum(0, t-0.9)*6)*(t > 0.9)*0.06
    return (x+sh) * env(n, a=0.005, d=1.9)

def lose_phrase():
    # gentle commiseration: descending cello-ish line
    n = int(1.6*SR); x = np.zeros(n)
    for i, f in enumerate([329.63, 293.66, 261.63, 246.94]):
        s = int(i*0.3*SR); m = int(0.7*SR); tt = np.arange(m)/SR
        tone = (np.sin(2*np.pi*f*tt)*0.5 + np.sin(2*np.pi*2*f*tt)*0.15)*np.exp(-tt*2.6)
        x[s:s+m] += tone*0.5
    return x * env(n, a=0.008, d=1.5)

def music_box_loop(name, bpm=76, bars=8, root=220.0, minor=False):
    # parlour music-box: soft plucked melody over a warm drone, seamless loop
    beat = 60.0/bpm; bar = beat*3; dur = bar*bars  # 3/4 parlour waltz
    n = int(dur*SR); t = np.arange(n)/SR; x = np.zeros(n)
    for mult, a in [(1, 0.05), (2, 0.022), (3, 0.010)]:
        x += a*np.sin(2*np.pi*root/2*mult*t)
    steps = [0, 2, 3, 5, 7, 8, 11] if minor else [0, 2, 4, 5, 7, 9, 11]
    melody = [0, 4, 7, 4, 9, 7, 5, 4, 2, 4, 7, 9, 7, 5, 4, 2]
    per = bar/2
    total = int(dur/per)
    for i in range(total):
        deg = melody[i % len(melody)]
        f = root * (2 ** (steps[deg % 7]/12)) * (2 if deg >= 7 else 1)
        s = int(i*per*SR); m = int(min(1.1*SR, n-s))
        tt = np.arange(m)/SR
        pl = (np.sin(2*np.pi*f*tt)*0.5 + np.sin(2*np.pi*2*f*tt)*0.12)*np.exp(-tt*4.5)
        x[s:s+m] += pl*0.30
    # gentle clockwork tick each beat
    for b in range(int(dur/beat)):
        s = int(b*beat*SR); m = int(0.03*SR)
        x[s:s+m] += rng.standard_normal(m)*0.02*np.exp(-np.arange(m)/(0.008*SR))
    # seamless loop edges
    f = int(0.15*SR)
    x[:f] *= np.linspace(0, 1, f); x[-f:] *= np.linspace(1, 0, f)
    save(name, x*0.85)

if __name__ == '__main__':
    save('click.wav', click())
    save('dice.wav', dice())
    save('hop.wav', hop())
    save('ladder.wav', ladder())
    save('snake.wav', snake())
    save('invalid.wav', invalid())
    save('start.wav', game_start())
    save('win.wav', win_phrase())
    save('lose.wav', lose_phrase())
    music_box_loop('music_menu.wav', bpm=72, bars=8, root=261.63, minor=False)
    music_box_loop('music_game.wav', bpm=84, bars=8, root=220.0, minor=True)
