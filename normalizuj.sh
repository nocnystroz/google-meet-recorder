#!/bin/bash
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# Post-processing nagrania.
#
# Użycie: ./normalizuj.sh plik [opcje]
#
# Opcje:
#   --format FORMAT    konwersja do innego formatu: wav, mp3, ogg
#   --no-denoise       wyłącz redukcję szumów
#   --no-normalize     wyłącz normalizację głośności
#
# Domyślnie: redukcja szumów + normalizacja, format bez zmian.
# Wynikowy plik: oryginalna_nazwa_out.{format}
#
# Przykłady:
#   ./normalizuj.sh nagranie.wav                        # szumy + normalizacja
#   ./normalizuj.sh nagranie.wav --format mp3           # szumy + normalizacja + konwersja
#   ./normalizuj.sh nagranie.wav --no-denoise           # tylko normalizacja
#   ./normalizuj.sh nagranie.wav --no-normalize         # tylko redukcja szumów
#   ./normalizuj.sh nagranie.wav --format mp3 --no-denoise --no-normalize  # tylko konwersja

INPUT="$1"
if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    KATALOG=~/Nagrania-Meet
    mapfile -t PLIKI < <(ls -t "$KATALOG"/*.{wav,mp3,ogg} 2>/dev/null)
    if [[ ${#PLIKI[@]} -eq 0 ]]; then
        echo "Brak nagrań w $KATALOG."
        exit 1
    fi
    echo "Wybierz plik do obróbki:"
    for i in "${!PLIKI[@]}"; do
        echo "  $((i+1))) $(basename "${PLIKI[$i]}")"
    done
    echo ""
    read -rp "Numer pliku: " NR
    NR=$((NR - 1))
    if [[ $NR -lt 0 || $NR -ge ${#PLIKI[@]} ]]; then
        echo "Nieprawidłowy wybór."
        exit 1
    fi
    INPUT="${PLIKI[$NR]}"
    shift 2>/dev/null || true
else
    shift
fi

FORMAT="${INPUT##*.}"
DENOISE=1
NORMALIZE=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --denoise)      DENOISE=1 ;;
        --normalize)    NORMALIZE=1 ;;
        --no-denoise)   DENOISE=0 ;;
        --no-normalize) NORMALIZE=0 ;;
        --format)       FORMAT="$2"; shift ;;
        *) echo "Nieznana flaga: $1"; exit 1 ;;
    esac
    shift
done

case "$FORMAT" in
    wav|mp3|ogg) ;;
    *) echo "Nieznany format: $FORMAT. Użyj: wav, mp3, ogg"; exit 1 ;;
esac

if [[ $DENOISE -eq 0 && $NORMALIZE -eq 0 && "$FORMAT" == "${INPUT##*.}" ]]; then
    echo "Nie wybrano żadnej operacji. Użyj --format, lub wyłącz domyślne przez --no-denoise / --no-normalize."
    exit 1
fi

BASENAME="${INPUT%.*}"
OUTPUT="${BASENAME}_out.$FORMAT"

echo "=== Post-processing ==="
echo "Wejście:     $INPUT"
echo "Wyjście:     $OUTPUT"
OPS=()
[[ $DENOISE -eq 1 ]]    && OPS+=("redukcja szumów")
[[ $NORMALIZE -eq 1 ]]  && OPS+=("normalizacja głośności")
[[ "$FORMAT" != "${INPUT##*.}" ]] && OPS+=("konwersja do $FORMAT")
echo "Operacje:    $(IFS=", "; echo "${OPS[*]}")"
echo ""

# Buduj łańcuch filtrów
FILTRY=()
[[ $DENOISE -eq 1 ]] && FILTRY+=("highpass=f=80" "afftdn=nf=-25")

if [[ $NORMALIZE -eq 1 ]]; then
    FILTR_NOISE=""
    [[ $DENOISE -eq 1 ]] && FILTR_NOISE="$(IFS=,; echo "${FILTRY[*]}"),"

    echo "Krok 1/2: analiza głośności..."
    STATS=$(ffmpeg -i "$INPUT" \
        -af "${FILTR_NOISE}loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json" \
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
    echo "Krok 2/2: przetwarzanie..."

    FILTRY+=("loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=$IN_I:measured_TP=$IN_TP:measured_LRA=$IN_LRA:measured_thresh=$IN_THRESH:offset=$OFFSET:linear=true")
else
    echo "Przetwarzanie..."
fi

FILTR_STR="$(IFS=,; echo "${FILTRY[*]}")"

if [[ -n "$FILTR_STR" ]]; then
    ffmpeg -loglevel error -stats -i "$INPUT" -af "$FILTR_STR" -y "$OUTPUT"
else
    ffmpeg -loglevel error -stats -i "$INPUT" -y "$OUTPUT"
fi

echo ""
echo "Gotowe: $OUTPUT"
