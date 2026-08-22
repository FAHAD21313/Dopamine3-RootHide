#!/usr/bin/env python3
"""
patch_macho_rpaths.py — roothide bootstrap Mach-O patcher (G35)
Rewrites every /var/jb reference inside a bootstrap tree:
  - LC_RPATH  "/var/jb/usr/lib"        -> "@loader_path/.jbroot/usr/lib"
  - LC_LOAD_DYLIB referencing /var/jb -> @loader_path/.jbroot/... (same relative form)

Run this on the build Mac (needs install_name_tool from Xcode CLT).
Based on the transformation observed in roothide strapfiles: 362 binaries
carry @loader_path/.jbroot rpaths instead of absolute /var/jb paths.

Usage: python3 patch_macho_rpaths.py <bootstrap_root_dir>
"""
import os, sys, subprocess, struct

MAGIC64 = 0xfeedfacf
LC_RPATH = 0x1c | 0x80000000
LC_LOAD_DYLIB = 0xc

def is_macho(path):
    try:
        with open(path, "rb") as f:
            return struct.unpack("<I", f.read(4))[0] in (MAGIC64, 0xcafebabe, 0xbebafeca)
    except OSError:
        return False

def tool(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode == 0

def patch_binary(path):
    changed = False
    # collect current rpaths
    out = subprocess.run(["otool", "-l", path], capture_output=True, text=True).stdout
    rpaths = []
    lines = out.splitlines()
    for i, line in enumerate(lines):
        if "LC_RPATH" in line and i + 2 < len(lines) and "path" in lines[i+2]:
            rp = lines[i+2].split("path")[1].strip().split(" ")[0]
            if rp.startswith("/var/jb"):
                rpaths.append(rp)
    for rp in rpaths:
        new = rp.replace("/var/jb", "@loader_path/.jbroot", 1)
        if tool(["install_name_tool", "-delete_rpath", rp, path]):
            tool(["install_name_tool", "-add_rpath", new, path])
            changed = True
    # dylibs that point into /var/jb directly
    out = subprocess.run(["otool", "-L", path], capture_output=True, text=True).stdout
    for line in out.splitlines()[1:]:
        lib = line.strip().split(" ")[0]
        if lib.startswith("/var/jb"):
            new = lib.replace("/var/jb", "@loader_path/.jbroot", 1)
            if tool(["install_name_tool", "-change", lib, new, path]):
                changed = True
    return changed

def main(root):
    patched = scanned = 0
    for dirpath, _, files in os.walk(root):
        for name in files:
            p = os.path.join(dirpath, name)
            if not is_macho(p):
                continue
            scanned += 1
            try:
                if patch_binary(p):
                    patched += 1
                    print(f"  patched: {os.path.relpath(p, root)}")
            except Exception as e:
                print(f"  ERROR {p}: {e}", file=sys.stderr)
    print(f"scanned={scanned} patched={patched}")

if __name__ == "__main__":
    main(sys.argv[1])
