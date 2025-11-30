#!/bin/bash

RELEASE_DIR="/dev/shm"
RELEASE_FILE="$RELEASE_DIR/BatterySteve.7z"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "SHIP IT..."

if [ -f "$RELEASE_FILE" ]; then
    echo "NUKE IT"
    rm "$RELEASE_FILE"
fi

cd "$PROJECT_DIR" || exit 1

echo "YEE THE LOGS"
rm -rf logs/*

echo "COMPRESS IT (7z ULTRA MODE)"

7z a "$RELEASE_FILE" \
   -t7z \
   -m0=lzma2 \
   -mx=9 \
   -mfb=273 \
   -md=256m \
   -ms=on \
   -mlc=4 \
   -x!buildrel.sh \
   -x!.git/* \
   -x!.gitignore \
   images/ \
   modules/ \
   audio/ \
   logs/ \
   3d/ \
   EBOOT.PBP \
   SCRIPT.LUA \
   onefont.pgf \
   config.ini

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$RELEASE_FILE" | cut -f1)
    echo "RELEASE: $RELEASE_FILE ($SIZE)"
else
    echo "FUCK"
    exit 1
fi
