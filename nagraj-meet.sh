#!/bin/bash
# Uruchom przed spotkaniem Google Meet.
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# Ctrl+C zatrzymuje nagranie i sprząta.
#
# Użycie: ./nagraj-meet.sh [--format wav|mp3|ogg] [--mic-vol N] [--meet-vol N]
#   --format mp3      zapisuje jako MP3
#   --format ogg      zapisuje jako OGG
#   --format wav      zapisuje jako WAV (domyślny)
#   --mic-vol  N      głośność mikrofonu, domyślnie 2.0 (1.0 = bez zmiany)
#   --meet-vol N      głośność dźwięku z Meet, domyślnie 1.0

MIC="alsa_input.usb-GN_Audio_A_S_Jabra_Evolve2_30_SE_B000002766B311-00.mono-fallback"
BT_MONITOR="alsa_output.usb-GN_Audio_A_S_Jabra_Evolve2_30_SE_B000002766B311-00.iec958-stereo.monitor"
KATALOG=~/Nagrania-Meet
mkdir -p "$KATALOG"

# Parsowanie flag
FORMAT="wav"
MIC_VOL="2.0"
MEET_VOL="1.0"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)   FORMAT="$2";   shift ;;
        --mic-vol)  MIC_VOL="$2";  shift ;;
        --meet-vol) MEET_VOL="$2"; shift ;;
        *) echo "Nieznana flaga: $1"; exit 1 ;;
    esac
    shift
done

case "$FORMAT" in
    wav|mp3|ogg) ;;
    *) echo "Nieznany format: $FORMAT. Użyj: wav, mp3, ogg"; exit 1 ;;
esac

PLIK="$KATALOG/nagranie-meet-$(date +%Y%m%d-%H%M%S).$FORMAT"

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
    printf "\033]0;\007"
    echo "Zapisano: $PLIK"
    exit 0
}
trap cleanup INT TERM

echo "=== Nagrywanie ==="
echo "Plik:      $PLIK"
echo "Mikrofon:  ${MIC_VOL}x"
echo "Meet:      ${MEET_VOL}x"
echo "Ctrl+C zatrzymuje."
echo ""

ffmpeg -loglevel error -stats \
    -f pulse -i "$MIC" \
    -f pulse -i "$BT_MONITOR" \
    -filter_complex "[0]volume=${MIC_VOL}[mic];[1]volume=${MEET_VOL}[meet];[mic][meet]amix=inputs=2:normalize=0" \
    "$PLIK" &

FFMPEG_PID=$!
timer_loop &
TIMER_PID=$!
wait "$FFMPEG_PID"
