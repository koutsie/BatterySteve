#!/bin/bash

RELEASE_DIR="/dev/shm"
RELEASE_FILE="$RELEASE_DIR/BatterySteve.7z"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$PROJECT_DIR/SCRIPT.LUA"
BUILD_DIR="$PROJECT_DIR/Resources"
BUILD_FILE="$BUILD_DIR/builds.txt"

echo "SHIP IT..."

mkdir -p "$BUILD_DIR"
if [ ! -f "$BUILD_FILE" ]; then
    echo "0" > "$BUILD_FILE"
    echo "" >> "$BUILD_FILE"
fi

BUILD_NUM=$(sed -n '1p' "$BUILD_FILE")
BUILD_NUM=$((BUILD_NUM + 1))
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")

printf "%s\n%s\n" "$BUILD_NUM" "$BUILD_DATE" > "$BUILD_FILE"

echo "BUILD NUMBER: $BUILD_NUM"
echo "BUILD DATE: $BUILD_DATE"

if [ -f "$SCRIPT_FILE" ]; then
    awk -v b="$BUILD_NUM" -v d="$BUILD_DATE" '
    BEGIN { vdone=0; ddone=0 }
    {
      if (!vdone && match($0, /^[ \t]*BSV[ \t]*=[ \t]*"([^"]*)"/, m)) {

        ver = m[1]
        sub(/-b[0-9]+$/, "", ver)

        rep = "BSV=\"" ver "-b" b "\""
        sub(/^[ \t]*BSV[ \t]*=[ \t]*"[^"]*"/, rep)
        vdone=1
      }

      if (!ddone && match($0, /^[ \t]*BSVDATE[ \t]*=[ \t]*"[^"]*"/)) {
        rep = "BSVDATE=\"" d "\""
        sub(/^[ \t]*BSVDATE[ \t]*=[ \t]*"[^"]*"/, rep)
        ddone=1
      }

      print
    }' "$SCRIPT_FILE" > "$SCRIPT_FILE.tmp" && mv "$SCRIPT_FILE.tmp" "$SCRIPT_FILE"
else
    echo "SCRIPT.LUA NOT FOUND!"
    exit 1
fi

if [ -f "$RELEASE_FILE" ]; then
    echo "NUKE IT"
    rm "$RELEASE_FILE"
fi

cd "$PROJECT_DIR" || exit 1

echo "YEET THE LOGS"
rm -rf logs/*

echo "COMPRESS IT (7Z *ULTRA MEGA SUPER DUPER* MODE)"

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
