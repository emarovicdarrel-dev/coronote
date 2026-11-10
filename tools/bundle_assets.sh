#!/usr/bin/env bash
# Downloads instrument recordings and fonts into docs/ so the installed app works offline.
set -u
mkdir -p docs/samples/sf
B=https://tonejs.github.io/audio/salamander
for f in A0 C8; do curl -fsSL -o docs/samples/$f.mp3 $B/$f.mp3 || echo "skip $f"; done
for o in 1 2 3 4 5 6 7; do for n in C Ds Fs A; do curl -fsSL -o docs/samples/$n$o.mp3 $B/$n$o.mp3 || echo "skip $n$o"; done; done
S=https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM
for n in electric_piano_1 church_organ string_ensemble_1 acoustic_guitar_nylon electric_bass_finger celesta orchestral_harp choir_aahs vibraphone violin flute; do
  curl -fsSL -o docs/samples/sf/$n-mp3.js $S/$n-mp3.js || echo "skip $n"
done
python3 tools/bundle_fonts.py || echo "fonts not bundled (app will still work online)"
du -sh docs/samples docs/fonts 2>/dev/null || true
