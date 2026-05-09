# Nagrywanie Google Meet + Mikrofon — Linux

Skrypty do nagrywania spotkań Google Meet (głos + dźwięk ze spotkania) na Linuksie z PipeWire/PulseAudio.

## Wymagania

```bash
sudo apt install ffmpeg pulseaudio-utils
```

## Szybki start

```bash
git clone https://github.com/nocnystroz/audio-rozkminka
cd audio-rozkminka
./setup.sh        # skonfiguruj urządzenia audio (raz)
./nagraj-meet.sh  # nagraj spotkanie
```

---

## Nagrywanie

```bash
./nagraj-meet.sh
```

**Ctrl+C** zatrzymuje i zapisuje plik w `~/Nagrania-Meet/`.

> Uruchamiaj przez `./nagraj-meet.sh`, nie `sh nagraj-meet.sh`.

### Flagi

```bash
./nagraj-meet.sh                                        # mic 4x, Meet 1x, WAV
./nagraj-meet.sh --mic-vol 3.0                         # zmniejsz wzmocnienie mikrofonu
./nagraj-meet.sh --meet-vol 0.5                        # ścisz dźwięk ze spotkania
./nagraj-meet.sh --mic-vol 4.0 --meet-vol 0.8 --format mp3
```

| Flaga | Domyślnie | Opis |
|---|---|---|
| `--mic-vol N` | `4.0` | Wzmocnienie mikrofonu (1.0 = bez zmiany) |
| `--meet-vol N` | `1.0` | Głośność dźwięku ze spotkania |
| `--format` | `wav` | Format wyjściowy: `wav`, `mp3`, `ogg` |

Podczas nagrywania tytuł terminala pokazuje czas (widoczny w pasku zadań XFCE):
```
⏺ REC 00:23:45
```

### Schemat działania

```
Mikrofon (×4.0) ──┐
                   ├──► ffmpeg amix ──► nagranie-meet-*.wav
Meet audio (×1.0) ─┘
```

ffmpeg miksuje oba wejścia bezpośrednio — bez wirtualnych urządzeń pośrednich.

---

## Konfiguracja na nowym sprzęcie

```bash
./setup.sh
```

Wykrywa dostępne mikrofony i wyjścia audio, pokazuje czytelne nazwy sprzętu, zapisuje wybór do `nagraj-meet.sh`. Wymaga podłączonego sprzętu w chwili uruchamiania.

---

## Post-processing

```bash
./normalizuj.sh                          # wybierz plik z listy interaktywnie
./normalizuj.sh nagranie.wav             # redukcja szumów + normalizacja EBU R128
./normalizuj.sh nagranie.wav --format mp3
./normalizuj.sh nagranie.wav --no-denoise
./normalizuj.sh nagranie.wav --no-normalize
./normalizuj.sh nagranie.wav --format mp3 --no-denoise --no-normalize  # tylko konwersja
```

Domyślnie stosuje redukcję szumów (`afftdn`) i normalizację głośności (EBU R128, dwuprzebiegową). Format zostaje taki sam jak oryginał jeśli nie podano `--format`. Wynik zapisywany z przyrostkiem `_out`.

---

## Pliki

| Plik | Opis |
|---|---|
| `setup.sh` | Konfigurator — uruchom raz na nowym sprzęcie |
| `nagraj-meet.sh` | Nagrywanie — Ctrl+C kończy |
| `normalizuj.sh` | Post-processing: redukcja szumów, normalizacja, konwersja |
| `stop-meet.sh` | Awaryjne czyszczenie wirtualnych urządzeń |

---

Jeśli skrypty Ci pomogły: [☕ Buy me a coffee](https://buymeacoffee.com/m.slawinski)
