# Google Meet Recorder for Linux

Shell scripts to record Google Meet sessions (your voice + meeting audio) on Linux with PipeWire/PulseAudio, using `ffmpeg` for mixing and post-processing.

## Requirements

```bash
sudo apt install ffmpeg pulseaudio-utils
```

## Quick Start

```bash
git clone https://github.com/nocnystroz/google-meet-recorder
cd google-meet-recorder
./setup.sh        # detect and configure audio devices (run once)
./nagraj-meet.sh  # start recording
```

---

## Recording

```bash
./nagraj-meet.sh
```

Press **Ctrl+C** to stop and save. Files are saved to `~/Nagrania-Meet/`.

> Always run as `./nagraj-meet.sh`, not `sh nagraj-meet.sh`.

### Flags

```bash
./nagraj-meet.sh                                         # mic 4x, meeting 1x, WAV
./nagraj-meet.sh --mic-vol 3.0                          # reduce mic boost
./nagraj-meet.sh --meet-vol 0.5                         # lower meeting audio
./nagraj-meet.sh --mic-vol 4.0 --meet-vol 0.8 --format mp3
```

| Flag | Default | Description |
|---|---|---|
| `--mic-vol N` | `4.0` | Microphone volume multiplier (1.0 = no change) |
| `--meet-vol N` | `1.0` | Meeting audio volume multiplier |
| `--format` | `wav` | Output format: `wav`, `mp3`, `ogg` |

The terminal window title shows a live recording timer visible in the taskbar:
```
⏺ REC 00:23:45
```

### How It Works

```
Microphone (×4.0) ──┐
                     ├──► ffmpeg amix ──► recording.wav
Meeting audio (×1.0) ┘
```

ffmpeg mixes both inputs directly — no virtual audio devices needed.

---

## Setup on a New Machine

```bash
./setup.sh
```

Detects available microphones and audio outputs, displays friendly device names, and saves your choice to `nagraj-meet.sh`. Make sure your headphones/speakers are connected when running setup.

---

## Post-processing

```bash
./normalizuj.sh                           # pick a file interactively
./normalizuj.sh recording.wav             # denoise + EBU R128 normalization
./normalizuj.sh recording.wav --format mp3
./normalizuj.sh recording.wav --no-denoise
./normalizuj.sh recording.wav --no-normalize
./normalizuj.sh recording.wav --format mp3 --no-denoise --no-normalize  # convert only
```

By default applies noise reduction (`afftdn`) and loudness normalization (EBU R128, two-pass). Output format stays the same as the input unless `--format` is specified. Output file gets an `_out` suffix.

---

## Files

| File | Description |
|---|---|
| `setup.sh` | Audio device configurator — run once per machine |
| `nagraj-meet.sh` | Recording script — Ctrl+C to stop |
| `normalizuj.sh` | Post-processing: noise reduction, normalization, format conversion |
| `stop-meet.sh` | Emergency cleanup of virtual audio devices |

---

If these scripts helped you: [☕ Buy me a coffee](https://buymeacoffee.com/m.slawinski)
