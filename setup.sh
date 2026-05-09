#!/bin/bash
# Konfigurator nagraj-meet.sh — wykrywa urządzenia audio i zapisuje wybór.

SKRYPT="$(dirname "$0")/nagraj-meet.sh"

echo "=== Konfigurator nagrywania Google Meet ==="
echo ""

# --- SPRAWDZENIE ZALEŻNOŚCI ---
BRAKUJE=0
for DEP in pactl ffmpeg; do
    if ! command -v "$DEP" &>/dev/null; then
        echo "BRAK: $DEP"
        BRAKUJE=1
    fi
done
if [[ $BRAKUJE -eq 1 ]]; then
    echo ""
    echo "Zainstaluj brakujące pakiety:"
    echo "  sudo apt install pulseaudio-utils ffmpeg"
    exit 1
fi
echo "Zależności OK (pactl, ffmpeg)"
echo ""

# --- MIKROFONY ---
echo "Dostępne mikrofony:"
mapfile -t MIC_NAMES < <(pactl list short sources | grep -v '\.monitor' | awk '{print $2}')
mapfile -t MIC_DESCS < <(pactl list sources | awk '
    /^\s+Name:/ { name=$2 }
    /^\s+device\.description/ { gsub(/.*= *"|"$/, ""); desc=$0; print name " — " desc }
' | grep -v '\.monitor')

if [[ ${#MIC_NAMES[@]} -eq 0 ]]; then
    echo "Nie znaleziono żadnych mikrofonów. Sprawdź połączenie sprzętu."
    exit 1
fi

for i in "${!MIC_NAMES[@]}"; do
    echo "  $((i+1))) ${MIC_DESCS[$i]:-${MIC_NAMES[$i]}}"
done

echo ""
read -rp "Wybierz numer mikrofonu: " MIC_NR
MIC_NR=$((MIC_NR - 1))
if [[ $MIC_NR -lt 0 || $MIC_NR -ge ${#MIC_NAMES[@]} ]]; then
    echo "Nieprawidłowy wybór."
    exit 1
fi
WYBRANY_MIC="${MIC_NAMES[$MIC_NR]}"
echo "Mikrofon: $WYBRANY_MIC"
echo ""

# --- WYJŚCIA AUDIO (monitory) ---
echo "Dostępne wyjścia audio (skąd leci dźwięk z Meet):"
mapfile -t MON_NAMES < <(pactl list short sources | grep '\.monitor' | awk '{print $2}')
mapfile -t MON_DESCS < <(pactl list sources | awk '
    /^\s+Name:/ { name=$2 }
    /^\s+device\.description/ { gsub(/.*= *"|"$/, ""); desc=$0; print name " — " desc }
' | grep '\.monitor')

if [[ ${#MON_NAMES[@]} -eq 0 ]]; then
    echo "Nie znaleziono żadnych wyjść audio."
    exit 1
fi

for i in "${!MON_NAMES[@]}"; do
    echo "  $((i+1))) ${MON_DESCS[$i]:-${MON_NAMES[$i]}}"
done

echo ""
read -rp "Wybierz numer wyjścia (przez które słyszysz Meet): " MON_NR
MON_NR=$((MON_NR - 1))
if [[ $MON_NR -lt 0 || $MON_NR -ge ${#MON_NAMES[@]} ]]; then
    echo "Nieprawidłowy wybór."
    exit 1
fi
WYBRANY_MON="${MON_NAMES[$MON_NR]}"
echo "Monitor: $WYBRANY_MON"
echo ""

# --- ZAPISZ DO nagraj-meet.sh ---
if [[ ! -f "$SKRYPT" ]]; then
    echo "Nie znaleziono $SKRYPT"
    exit 1
fi

sed -i "s|^MIC=.*|MIC=\"$WYBRANY_MIC\"|" "$SKRYPT"
sed -i "s|^BT_MONITOR=.*|BT_MONITOR=\"$WYBRANY_MON\"|" "$SKRYPT"

echo "=== Gotowe ==="
echo "Zapisano konfigurację w nagraj-meet.sh:"
echo "  MIC        = $WYBRANY_MIC"
echo "  BT_MONITOR = $WYBRANY_MON"
echo ""
echo "Możesz teraz uruchomić: ./nagraj-meet.sh"
