#!/bin/bash
# Usuń wirtualne urządzenia po nagraniu

pactl unload-module module-loopback 2>/dev/null
pactl unload-module module-null-sink 2>/dev/null

echo "Wirtualne urządzenia usunięte."
