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
```

Podczas nagrywania widać bieżący status w terminalu:
```
size=    2048kB time=00:02:13.45 bitrate= 123.4kbits/s
```

Tytuł okna terminala pokazuje licznik czasu (widoczny w pasku zadań XFCE):
```
⏺ REC 00:23:45
```

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

Skrypt ma wpisane na sztywno nazwy urządzeń audio. Na innym sprzęcie uruchom konfigurator — sam wykryje dostępny sprzęt i zaktualizuje skrypt:

```bash
./setup.sh
```

Konfigurator pokazuje numerowaną listę mikrofonów i wyjść audio, pyta o wybór, i zapisuje go do `nagraj-meet.sh`. Wymaga podłączonego sprzętu (słuchawki BT muszą być sparowane i połączone w chwili uruchamiania).

---

## Troubleshooting

**Brak dźwięku z Meet w nagraniu**
W `pavucontrol` (zakładka Odtwarzanie) sprawdź, że Chrome wysyła audio do właściwego wyjścia — loopback automatycznie przechwytuje jego monitor.

**Po restarcie komputera**
Wirtualne urządzenia są tymczasowe — uruchamiaj skrypt przed każdym spotkaniem.

**Chcę edytować nagranie w Audacity**
Audacity 3.4.2 z `apt` nie ma PulseAudio — nie można nim nagrywać z MeetMix, ale można otworzyć gotowy plik WAV do edycji. Jeśli potrzebujesz nagrywać przez Audacity: `snap install audacity` (wersja 3.7.5 ma PulseAudio).

---

## Post-processing (opcjonalnie)

Po nagraniu możesz przepuścić plik przez `normalizuj.sh` — redukuje szumy i normalizuje głośność do standardu EBU R128 (używanego w radio/TV):

```bash
./normalizuj.sh ~/Nagrania-Meet/nagranie-meet-20260509-1900.wav
./normalizuj.sh ~/Nagrania-Meet/nagranie-meet-20260509-1900.wav --format mp3
./normalizuj.sh ~/Nagrania-Meet/nagranie-meet-20260509-1900.wav --format ogg
```

Wynikowy plik zapisuje się obok oryginału z przyrostkiem `_norm`, np. `nagranie-meet-20260509-1900_norm.mp3`.

Każda operacja jest opcjonalna — wybierasz tylko to czego potrzebujesz:

```bash
./normalizuj.sh nagranie.wav --normalize                    # tylko normalizacja
./normalizuj.sh nagranie.wav --denoise                      # tylko redukcja szumów
./normalizuj.sh nagranie.wav --format mp3                   # tylko konwersja formatu
./normalizuj.sh nagranie.wav --denoise --normalize          # szumy + normalizacja
./normalizuj.sh nagranie.wav --denoise --normalize --format mp3  # wszystko + konwersja
```

Format domyślnie zostaje taki sam jak oryginał. Normalizacja działa dwuprzebiegowo (dokładniejsza niż w locie).

---

## Pliki
- `setup.sh` — konfigurator, uruchom raz na nowym sprzęcie
- `nagraj-meet.sh` — uruchom przed nagraniem, Ctrl+C kończy
- `normalizuj.sh` — post-processing: redukcja szumów + normalizacja + konwersja
- `stop-meet.sh` — awaryjne czyszczenie gdy skrypt padł bez sprzątania (crash, `kill -9`, zamknięty terminal)
