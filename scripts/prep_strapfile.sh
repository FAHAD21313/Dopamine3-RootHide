#!/usr/bin/env bash
# prep_strapfile.sh — roothide bootstrap patcher (Task 1.5b, G35/G36)
# Takes a pristine Procursus bootstrap tar.zst and produces a roothide-compatible
# strapfile: relative @loader_path/.jbroot rpaths + libvroot injection.
#
# Usage: ./prep_strapfile.sh <bootstrap.tar.zst> <output.tar.zst> [roothide_tar.zst]
#   roothide_tar.zst: optional source for libvroot/libvrootapi binaries
#
# NOTE: full Mach-O rpath rewriting requires install_name_tool on macOS with
# an iOS-cross binary context, or a ChOma-based patcher on Linux. This script
# orchestrates the pipeline; the Mach-O rewriting itself runs on the build Mac.

set -euo pipefail

IN="$1"
OUT="$2"
RH="${3:-}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "[1/5] decompress $IN"
unzstd -c "$IN" > "$WORK/bootstrap.tar"

echo "[2/5] extract"
mkdir "$WORK/root"
tar -xf "$WORK/bootstrap.tar" -C "$WORK/root"

echo "[3/5] stage libvroot trio from roothide strapfile (G36)"
if [ -n "$RH" ] && [ -f "$RH" ]; then
    mkdir "$WORK/rh"
    unzstd -c "$RH" | tar -x -C "$WORK/rh" \
        ./usr/lib/libvroot.dylib ./usr/lib/libvrootapi.dylib 2>/dev/null || \
    (unzstd -c "$RH" > "$WORK/rh.tar" && tar -xf "$WORK/rh.tar" -C "$WORK/rh" ./usr/lib/libvroot.dylib ./usr/lib/libvrootapi.dylib)
    mkdir -p "$WORK/root/usr/lib"
    cp -a "$WORK/rh/usr/lib/libvroot.dylib" "$WORK/rh/usr/lib/libvrootapi.dylib" "$WORK/root/usr/lib/" 2>/dev/null || true
else
    echo "  WARN: no roothide tar given; libvroot must be staged separately (G36)"
fi

echo "[4/5] rewrite Mach-O load commands (macOS step)"
# On the build Mac, run the companion python patcher:
#   python3 patch_macho_rpaths.py "$WORK/root"
# It rewrites /var/jb LC_RPATHs to @loader_path/.jbroot and adds
# LC_LOAD_DYLIB -> @loader_path/.jbroot/usr/lib/libvrootapi.dylib
# for every Mach-O that references /var/jb. See patch_macho_rpaths.py.
if [ "$(uname)" = "Darwin" ]; then
    python3 "$(dirname "$0")/patch_macho_rpaths.py" "$WORK/root"
else
    echo "  SKIP (not macOS) — run patch_macho_rpaths.py on the build Mac"
fi

echo "[5/5] repack + compress -> $OUT"
tar -cf "$WORK/out.tar" -C "$WORK/root" .
zstd -q -19 -f "$WORK/out.tar" -o "$OUT"
echo "done: $OUT ($(du -h "$OUT" | cut -f1))"
