#!/bin/bash
# Uruchom przed spotkaniem Google Meet.
# Ctrl+C zatrzymuje nagranie i sprząta.
#
# Użycie: ./nagraj-meet.sh [--raw] [--no-osd] [--format wav|mp3|ogg]
#   --raw             nagrywa bez filtrów (surowy dźwięk)
#   --no-osd          wyłącza nakładkę OSD na ekranie
#   --format mp3      zapisuje jako MP3 (mały plik, dobry do odsłuchu)
#   --format ogg      zapisuje jako OGG (mały plik, otwarte kodowanie)
#   --format wav      zapisuje jako WAV (domyślny, bezstratny, do edycji)

MIC="alsa_input.usb-GN_Audio_A_S_Jabra_Evolve2_30_SE_B000002766B311-00.mono-fallback"
BT_MONITOR="bluez_output.7B_9B_B9_FD_A2_1E.1.monitor"

# Łańcuch filtrów audio:
#   highpass=f=80      - usuwa pomruki i niskie szumy (klimatyzacja, stoły)
#   afftdn=nf=-25      - redukcja szumów FFT (syk, szum tła)
#   dynaudnorm=f=500   - wyrównuje głośność (cichy uczestnik -> głośniejszy)
FILTRY="highpass=f=80,afftdn=nf=-25,dynaudnorm=f=500:g=15"

# Parsowanie flag
FORMAT="wav"
RAW=0
NO_OSD=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --raw)    RAW=1 ;;
        --no-osd) NO_OSD=1 ;;
        --format) FORMAT="$2"; shift ;;
        *) echo "Nieznana flaga: $1"; exit 1 ;;
    esac
    shift
done

# Walidacja formatu
case "$FORMAT" in
    wav|mp3|ogg) ;;
    *) echo "Nieznany format: $FORMAT. Użyj: wav, mp3, ogg"; exit 1 ;;
esac

PLIK=~/nagranie-meet-$(date +%Y%m%d-%H%M).$FORMAT

# Wyświetla czas nagrywania w tytule terminala i (jeśli dostępne) na ekranie
timer_loop() {
    local start=$SECONDS
    local osd=0
    [[ $NO_OSD -eq 0 ]] && command -v osd_cat &>/dev/null && osd=1

    while kill -0 "$FFMPEG_PID" 2>/dev/null; do
        local elapsed=$((SECONDS - start))
        local h=$((elapsed / 3600))
        local m=$(( (elapsed % 3600) / 60 ))
        local s=$((elapsed % 60))
        local t
        t=$(printf "%02d:%02d:%02d" $h $m $s)

        # Tytuł okna terminala (widoczny w pasku zadań XFCE)
        printf "\033]0;⏺ REC %s\007" "$t"

        # OSD w rogu ekranu (wymaga: sudo apt install xosd-bin)
        if [[ $osd -eq 1 ]]; then
            echo "⏺ REC $t" | osd_cat \
                -p bottom -A right -c red \
                -f -*-fixed-*-*-*-*-20-*-*-*-*-*-*-* \
                -d 1 2>/dev/null &
        fi

        sleep 1
    done
    # Przywróć domyślny tytuł terminala
    printf "\033]0;\007"
}

cleanup() {
    echo ""
    echo "Zatrzymuję nagranie..."
    kill "$TIMER_PID" 2>/dev/null
    # Nie wysyłaj sygnału do ffmpeg ponownie — Ctrl+C już to zrobiło.
    # Czekamy aż ffmpeg dokończy zapis (trailer WAV itp.)
    wait "$FFMPEG_PID" 2>/dev/null
    pactl unload-module module-loopback 2>/dev/null
    pactl unload-module module-null-sink 2>/dev/null
    printf "\033]0;\007"
    echo "Zapisano: $PLIK"
    exit 0
}
trap cleanup INT TERM

# Posprzątaj poprzednią sesję
pactl unload-module module-loopback 2>/dev/null
pactl unload-module module-null-sink 2>/dev/null
sleep 0.5

# Wirtualny mikser
pactl load-module module-null-sink \
  sink_name=MeetMix \
  sink_properties=device.description=MeetMix

# Mikrofon Jabra -> MeetMix
pactl load-module module-loopback \
  source="$MIC" \
  sink=MeetMix \
  latency_msec=20

# Słuchawki BT (dźwięk z Meet) -> MeetMix
pactl load-module module-loopback \
  source="$BT_MONITOR" \
  sink=MeetMix \
  latency_msec=20

echo "=== Nagrywanie ==="
echo "Plik:   $PLIK"

if [[ $RAW -eq 1 ]]; then
    echo "Tryb:   surowy (bez filtrów)"
else
    echo "Tryb:   z filtrami (redukcja szumów + wyrównanie głośności)"
fi
echo "Ctrl+C zatrzymuje."
echo ""

if [[ $RAW -eq 1 ]]; then
    ffmpeg -loglevel error -stats -f pulse -i MeetMix.monitor "$PLIK" &
else
    ffmpeg -loglevel error -stats -f pulse -i MeetMix.monitor -af "$FILTRY" "$PLIK" &
fi

FFMPEG_PID=$!
timer_loop &
TIMER_PID=$!
wait "$FFMPEG_PID"
