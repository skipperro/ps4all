#!/bin/sh
set -e

WINEPREFIX="${WINEPREFIX:-/home/ubuntu/.wine}"
# Written last, so an interrupted setup is retried on the next start
MARKER="$WINEPREFIX/.setup_done"

if [ -f "$MARKER" ]; then
    echo "Wineprefix already set up"
    exit 0
fi

# Create wineprefix
wineboot -u
wineserver -w
winetricks --self-update
winetricks -f -q vcrun2022
winetricks -f -q corefonts
winetricks -f -q allcodecs
winetricks -f -q physx
winetricks -f -q dxvk
winetricks -f -q dxvk_nvapi0061
winetricks -f -q vkd3d

# Install nvidia libraries
/home/ubuntu/nvidia/setup_nvlibs.sh install

touch "$MARKER"

