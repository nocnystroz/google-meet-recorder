#!/bin/bash
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# Post-processing nagrania: redukcja szumów + normalizacja EBU R128 + opcjonalna konwersja.
#
# Użycie: ./normalizuj.sh plik.wav [--format wav|mp3|ogg]
#   --format mp3   konwertuje do MP3
#   --format ogg   konwertuje do OGG
#   --format wav   zostawia jako WAV (domyślnie)
#
# Wynikowy plik: oryginalna_nazwa_norm.{format}

INPUT="$1"
FORMAT="wav"

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format) FORMAT="$2"; shift ;;
        *) echo "Nieznana flaga: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    echo "Użycie: ./normalizuj.sh plik.wav [--format wav|mp3|ogg]"
    echo ""
    echo "Przykłady:"
    echo "  ./normalizuj.sh ~/Nagrania-Meet/nagranie-meet-20260509-1900.wav"
    echo "  ./normalizuj.sh ~/Nagrania-Meet/nagranie-meet-20260509-1900.wav --format mp3"
    exit 1
fi

case "$FORMAT" in
    wav|mp3|ogg) ;;
    *) echo "Nieznany format: $FORMAT. Użyj: wav, mp3, ogg"; exit 1 ;;
esac

BASENAME="${INPUT%.*}"
OUTPUT="${BASENAME}_norm.$FORMAT"

echo "=== Post-processing ==="
echo "Wejście: $INPUT"
echo "Wyjście: $OUTPUT"
echo ""

# Filtry szumów (te same co przy nagrywaniu, ale teraz na gotowym pliku)
NOISE="highpass=f=80,afftdn=nf=-25"

# Pass 1 — analiza głośności (loudnorm EBU R128)
echo "Krok 1/2: analiza głośności..."
STATS=$(ffmpeg -i "$INPUT" \
    -af "$NOISE,loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json" \
    -f null - 2>&1 | grep -A 20 '{')

extract() { echo "$STATS" | grep "\"$1\"" | sed 's/.*: *"\([^"]*\)".*/\1/'; }
IN_I=$(extract "input_i")
IN_TP=$(extract "input_tp")
IN_LRA=$(extract "input_lra")
IN_THRESH=$(extract "input_thresh")
OFFSET=$(extract "target_offset")

if [[ -z "$IN_I" ]]; then
    echo "Błąd: nie udało się przeanalizować pliku audio."
    exit 1
fi

echo "  Głośność wejściowa: ${IN_I} LUFS  (cel: -16 LUFS)"
echo ""

# Pass 2 — redukcja szumów + normalizacja
echo "Krok 2/2: redukcja szumów i normalizacja..."
ffmpeg -loglevel error -stats -i "$INPUT" \
    -af "$NOISE,loudnorm=I=-16:TP=-1.5:LRA=11:\
measured_I=$IN_I:measured_TP=$IN_TP:measured_LRA=$IN_LRA:\
measured_thresh=$IN_THRESH:offset=$OFFSET:linear=true" \
    -y "$OUTPUT"

echo ""
echo "Gotowe: $OUTPUT"
