# Nagrywanie Google Meet + Mikrofon — Linux

**Ten komputer:** PipeWire 1.0.5, mikrofon Jabra Evolve2 30 SE (USB), słuchawki BT, Ubuntu XFCE

## Jak nagrywać

```bash
cd ~/geminicli_files/audio-rozkminka
./nagraj-meet.sh
```

**Ctrl+C** zatrzymuje i zapisuje plik — w tym samym terminalu, nie trzeba drugiego okna.

> **Ważne:** uruchamiaj przez `./nagraj-meet.sh`, nie przez `sh nagraj-meet.sh`.
> `sh` to dash (nie bash) i nie obsługuje składni użytej w skrypcie.

Plik ląduje w `~/Nagrania-Meet/nagranie-meet-YYYYMMDD-HHMM.wav` (folder tworzony automatycznie).

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
2. Wrzuca do niego mikrofon + dźwięk z wyjścia audio
3. Nagrywa przez `ffmpeg` z filtrami audio
4. Po Ctrl+C sprząta wirtualne urządzenia

Słuchawki/głośniki działają normalnie przez cały czas — słyszysz spotkanie bez zmian.

```
Mikrofon ──┐
           ├──► MeetMix ──► filtry ──► nagranie-meet-*.wav
Wyjście ───┘
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

## Przenoszenie na inny komputer

Skrypt ma wpisane na sztywno nazwy urządzeń audio tego konkretnego komputera. Na innym sprzęcie trzeba je zmienić.

**Krok 1 — znajdź nazwę mikrofonu:**
```bash
pactl list short sources | grep -v monitor
```
Szukaj linii z `alsa_input` lub `bluez_source`. Skopiuj całą nazwę (pierwsza kolumna po numerze).

**Krok 2 — znajdź monitor wyjścia audio:**
```bash
pactl list short sources | grep monitor
```
Szukaj monitora tego wyjścia, przez które słyszysz Meet (słuchawki, głośniki). Nazwa kończy się na `.monitor`.

**Krok 3 — wklej do skryptu:**
W `nagraj-meet.sh` zmień dwie linie na górze:
```bash
MIC="tutaj-nazwa-twojego-mikrofonu"
BT_MONITOR="tutaj-nazwa-monitora-wyjscia.monitor"
```

---

## Troubleshooting

**Brak dźwięku z Meet w nagraniu**
W `pavucontrol` (zakładka Odtwarzanie) sprawdź, że Chrome wysyła audio do właściwego wyjścia — loopback automatycznie przechwytuje jego monitor.

**Po restarcie komputera**
Wirtualne urządzenia są tymczasowe — uruchamiaj skrypt przed każdym spotkaniem.

**Chcę edytować nagranie w Audacity**
Audacity 3.4.2 z `apt` nie ma PulseAudio — nie można nim nagrywać z MeetMix, ale można otworzyć gotowy plik WAV do edycji. Jeśli potrzebujesz nagrywać przez Audacity: `snap install audacity` (wersja 3.7.5 ma PulseAudio).

---

## Pliki
- `nagraj-meet.sh` — uruchom przed nagraniem, Ctrl+C kończy
- `stop-meet.sh` — awaryjne czyszczenie gdy skrypt padł bez sprzątania (crash, `kill -9`, zamknięty terminal)
