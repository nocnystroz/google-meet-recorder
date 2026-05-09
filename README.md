# Nagrywanie Google Meet + Mikrofon — Linux

**Twój sprzęt:** PipeWire 1.0.5, mikrofon Jabra Evolve2 30 SE (USB), słuchawki BT, Ubuntu XFCE

## Jak nagrywać

```bash
cd ~/geminicli_files/audio-rozkminka
./nagraj-meet.sh
```

**Ctrl+C** zatrzymuje i zapisuje plik — w tym samym terminalu, nie trzeba drugiego okna.

> **Ważne:** uruchamiaj przez `./nagraj-meet.sh`, nie przez `sh nagraj-meet.sh`.
> `sh` to dash (nie bash) i nie obsługuje składni użytej w skrypcie.

Plik ląduje w katalogu domowym: `~/nagranie-meet-YYYYMMDD-HHMM.wav`

### Flagi

```bash
./nagraj-meet.sh                        # z filtrami, format WAV
./nagraj-meet.sh --raw                  # bez filtrów
./nagraj-meet.sh --format mp3           # mały plik, dobry do odsłuchu
./nagraj-meet.sh --format ogg           # mały plik, otwarte kodowanie
./nagraj-meet.sh --raw --format mp3     # bez filtrów, jako MP3
./nagraj-meet.sh --no-osd               # wyłącza nakładkę OSD na ekranie
```

Podczas nagrywania widać bieżący status w terminalu:
```
size=    2048kB time=00:02:13.45 bitrate= 123.4kbits/s
```

Tytuł okna terminala pokazuje licznik czasu (widoczny w pasku zadań XFCE):
```
⏺ REC 00:23:45
```

Nakładka OSD w prawym dolnym rogu ekranu działa po zainstalowaniu `xosd-bin`:
```bash
sudo apt install xosd-bin
```
Skrypt wykrywa ją automatycznie. Flaga `--no-osd` wyłącza nakładkę gdy jest zainstalowana.

---

## Co robi skrypt

1. Tworzy wirtualny mikser **MeetMix**
2. Wrzuca do niego mikrofon Jabra + dźwięk ze słuchawek BT
3. Nagrywa przez `ffmpeg` z filtrami audio
4. Po Ctrl+C sprząta wirtualne urządzenia

Słuchawki BT działają normalnie przez cały czas — słyszysz spotkanie bez zmian.

```
Mikrofon Jabra ──┐
                 ├──► MeetMix ──► filtry ──► nagranie-meet-*.wav
BT słuchawki ────┘
(monitor)
```

---

## Filtry audio (domyślne)

| Filtr | Co robi |
|---|---|
| `highpass=f=80` | Usuwa pomruki, szum klimatyzacji, dudnienia poniżej 80Hz |
| `afftdn=nf=-25` | Redukcja szumów FFT — syk mikrofonu, szum tła |
| `dynaudnorm=f=500:g=15` | Wyrównuje głośność uczestników |

**Jeśli szumy są za duże** — otwórz skrypt i zmień `nf=-25` na `nf=-30` lub `nf=-35` w linii `FILTRY=`. Bardziej agresywna redukcja, ale może lekko "myć" głos.

---

## Troubleshooting

**Brak dźwięku z Meet w nagraniu**
W `pavucontrol` (zakładka Odtwarzanie) sprawdź, że Chrome wysyła audio do słuchawek BT — loopback automatycznie przechwytuje ich monitor.

**Po restarcie komputera**
Wirtualne urządzenia są tymczasowe — uruchamiaj skrypt przed każdym spotkaniem.

**Chcę edytować nagranie w Audacity**
Audacity 3.4.2 z `apt` nie ma PulseAudio — nie można nim nagrywać z MeetMix, ale można otworzyć gotowy plik WAV do edycji. Jeśli potrzebujesz nagrywać przez Audacity: `snap install audacity` (wersja 3.7.5 ma PulseAudio).

**Chcę mniejszy plik**
Zmień rozszerzenie pliku w skrypcie z `.wav` na `.mp3` lub `.ogg` — ffmpeg automatycznie użyje odpowiedniego kodeka.

---

## Pliki
- `nagraj-meet.sh` — uruchom przed nagraniem, Ctrl+C kończy
- `stop-meet.sh` — czyści urządzenia jeśli coś zostało
