#!/bin/bash
# Uruchom przed spotkaniem Google Meet.
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# Ctrl+C zatrzymuje nagranie i sprząta.
#
# Użycie: ./nagraj-meet.sh [--raw] [--format wav|mp3|ogg]
#   --raw             nagrywa bez filtrów (surowy dźwięk)
#   --format mp3      zapisuje jako MP3 (mały plik, dobry do odsłuchu)
#   --format ogg      zapisuje jako OGG (mały plik, otwarte kodowanie)
#   --format wav      zapisuje jako WAV (domyślny, bezstratny, do edycji)

MIC="alsa_input.usb-GN_Audio_A_S_Jabra_Evolve2_30_SE_B000002766B311-00.mono-fallback"
BT_MONITOR="alsa_output.usb-GN_Audio_A_S_Jabra_Evolve2_30_SE_B000002766B311-00.iec958-stereo.monitor"
KATALOG=~/Nagrania-Meet
mkdir -p "$KATALOG"

# Łańcuch filtrów audio:
#   highpass=f=80      - usuwa pomruki i niskie szumy (klimatyzacja, stoły)
#   afftdn=nf=-25      - redukcja szumów FFT (syk, szum tła)
#   dynaudnorm=f=500   - wyrównuje głośność (cichy uczestnik -> głośniejszy)
FILTRY="highpass=f=80,afftdn=nf=-25,dynaudnorm=f=500:g=15"

# Parsowanie flag
FORMAT="wav"
RAW=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --raw)    RAW=1 ;;
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

PLIK="$KATALOG/nagranie-meet-$(date +%Y%m%d-%H%M).$FORMAT"

# Wyświetla czas nagrywania w tytule terminala (widoczny w pasku zadań XFCE)
timer_loop() {
    local start=$SECONDS
    while kill -0 "$FFMPEG_PID" 2>/dev/null; do
        local elapsed=$((SECONDS - start))
        local h=$((elapsed / 3600))
        local m=$(( (elapsed % 3600) / 60 ))
        local s=$((elapsed % 60))
        printf "\033]0;⏺ REC %02d:%02d:%02d\007" $h $m $s
        sleep 1
    done
    printf "\033]0;\007"
}

cleanup() {
    echo ""
    echo "Zatrzymuję nagranie..."
    kill "$TIMER_PID" 2>/dev/null
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

# Mikrofon -> MeetMix
pactl load-module module-loopback \
  source="$MIC" \
  sink=MeetMix \
  latency_msec=20

# Wyjście audio (dźwięk z Meet) -> MeetMix
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
