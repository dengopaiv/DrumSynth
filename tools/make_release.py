"""Build, test and package a DrumSynth release for Windows (64-bit).

Usage:
    python tools/make_release.py [--skip-tests] [--out dist]

Steps:
  1. Build the C17 engine's renderer (tools/renderers, x64) and the GUI (app/,
     Release, with vcpkg's wxWidgets: VCPKG_ROOT must be set).
  2. Test, unless --skip-tests:
       - tools/check_reference.py: every render byte for byte against the
         original DLL's checksums (docs/reference/checksums.csv);
       - app/tests preset_roundtrip: load and re-save all presets as the GUI.
  3. Assemble dist/DrumSynth-<version>-win64/:
       DrumSynth.exe and the DLLs it needs (wxWidgets and its image
       libraries, the Visual C++ runtime, Tolk and NVDA's controller client
       when the build found them), gui-help.md, README.txt, the licences
       (licenses/ for third-party code), and the presets as kit folders in
       Kits/ (DrumSyn.ini points the program there): the DrumSynth 2.0
       library (bin/library.zip) merged with the drumsynths/ collection.
  4. Zip it as dist/DrumSynth-<version>-win64.zip and write its SHA-256.

The version is app/CMakeLists.txt's project VERSION. Release notes are
docs/release-notes.md.
"""
import argparse
import glob
import hashlib
import os
import re
import shutil
import subprocess
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dslib  # noqa: E402

REPO = dslib.REPO
VCPKG = os.environ.get("VCPKG_ROOT", r"C:\GIT\environment\vcpkg")
TRIPLET_SHARE = os.path.join(VCPKG, "installed", "x64-windows", "share")
TOLK_DIR = r"C:\GIT\environment\tolk"

# DLLs the build folder may hold that are not shipped: the System Access API
# (SAAPI64.dll) that Tolk can use has no redistribution licence we know of.
EXCLUDE_DLLS = {"saapi64.dll"}

# Third-party licence texts: (file in licenses/, source path, what it covers)
def third_party():
    items = [
        ("wxWidgets.txt", os.path.join(TRIPLET_SHARE, "wxwidgets", "copyright"), "wxbase*.dll, wxmsw*.dll"),
        ("libjpeg-turbo.txt", os.path.join(TRIPLET_SHARE, "libjpeg-turbo", "copyright"), "jpeg62.dll"),
        ("liblzma.txt", os.path.join(TRIPLET_SHARE, "liblzma", "copyright"), "liblzma.dll"),
        ("libpng.txt", os.path.join(TRIPLET_SHARE, "libpng", "copyright"), "libpng16.dll"),
        ("libwebp.txt", os.path.join(TRIPLET_SHARE, "libwebp", "copyright"), "libwebp*.dll, libsharpyuv.dll"),
        ("pcre2.txt", os.path.join(TRIPLET_SHARE, "pcre2", "copyright"), "pcre2-16.dll"),
        ("libtiff.txt", os.path.join(TRIPLET_SHARE, "tiff", "copyright"), "tiff.dll"),
        ("zlib.txt", os.path.join(TRIPLET_SHARE, "zlib", "copyright"), "z.dll"),
        ("Tolk-LGPL-3.0.txt", os.path.join(TOLK_DIR, "LICENSE.txt"), "Tolk.dll"),
        ("NVDA-controller-client-LGPL-2.1.txt", os.path.join(TOLK_DIR, "LICENSE-NVDA.txt"),
         "nvdaControllerClient64.dll"),
    ]
    return items


def run(cmd, **kw):
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=True, **kw)


def version():
    text = open(os.path.join(REPO, "app", "CMakeLists.txt"), encoding="utf-8").read()
    return re.search(r"project\(DrumSynthApp VERSION (\d+\.\d+\.\d+)", text).group(1)


def build():
    toolchain = os.path.join(VCPKG, "scripts", "buildsystems", "vcpkg.cmake")
    run(["cmake", "-S", "tools/renderers", "-B", "build/renderers-x64", "-A", "x64"], cwd=REPO)
    run(["cmake", "--build", "build/renderers-x64", "--config", "Release"], cwd=REPO)
    run(["cmake", "-S", "app", "-B", "build/app", "-A", "x64", f"-DCMAKE_TOOLCHAIN_FILE={toolchain}"], cwd=REPO)
    run(["cmake", "--build", "build/app", "--config", "Release"], cwd=REPO)


def test(tmp):
    run([sys.executable, os.path.join(REPO, "tools", "check_reference.py")], cwd=REPO)
    # load and re-save every preset as the GUI does
    presets, _ = dslib.load_presets()
    folder = os.path.join(tmp, "roundtrip")
    os.makedirs(folder, exist_ok=True)
    paths = []
    for i, p in enumerate(presets):
        path = os.path.join(folder, f"{i:04d}.ds")
        with open(path, "wb") as f:
            f.write(p.data)
        paths.append(path)
    listfile = os.path.join(tmp, "roundtrip.txt")
    with open(listfile, "w", encoding="ascii") as f:
        f.write("\n".join(paths) + "\n")
    exe = os.path.join(REPO, "build", "app", "Release", "preset_roundtrip.exe")
    r = subprocess.run([exe, listfile], capture_output=True, text=True)
    print(r.stderr.strip())
    if r.returncode != 0:
        sys.exit("preset_roundtrip failed")


def zip_name(info):
    # names in bin/library.zip are cp1252 bytes read as cp437 (tools/dslib.py)
    if info.flag_bits & 0x800:
        return info.filename
    try:
        return info.filename.encode("cp437").decode("cp1252")
    except UnicodeError:
        return info.filename


def add_presets(dest):
    """The kit folders: library.zip, then drumsynths/ merged in. A file that
    exists with other content gets " (2)" added to its name. Loose files at
    the top of drumsynths/ go into the kit "Extras". Returns counts."""
    added = same = renamed = 0

    def put(rel, data):
        nonlocal added, same, renamed
        parts = rel.replace("\\", "/").split("/")
        if len(parts) == 1:
            parts = ["Extras"] + parts
        target = os.path.join(dest, *parts)
        if os.path.exists(target):
            if open(target, "rb").read() == data:
                same += 1
                return
            base, ext = os.path.splitext(target)
            target = base + " (2)" + ext
            renamed += 1
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "wb") as f:
            f.write(data)
        added += 1

    with zipfile.ZipFile(os.path.join(REPO, "bin", "library.zip")) as z:
        for info in z.infolist():
            name = zip_name(info)
            if info.is_dir() or not name.lower().endswith((".ds", ".wav")):
                continue
            put(name, z.read(info))
    tracked = subprocess.run(["git", "-C", REPO, "ls-files", "-z", "drumsynths"], capture_output=True,
                             check=True).stdout.decode("utf-8").split("\0")
    for rel in tracked:
        if not rel.lower().endswith((".ds", ".wav")):
            continue
        with open(os.path.join(REPO, rel), "rb") as f:
            put(os.path.relpath(rel, "drumsynths"), f.read())
    return added, same, renamed


README = """DrumSynth {version}, accessible edition
==========================================

A recreation of DrumSynth 2.0 by Paul Kellett (2000), usable with the keyboard
and a screen reader (NVDA, Narrator). Its sound engine gives exactly the
output of the original, byte for byte.

Running it
----------
Start DrumSynth.exe. No installation is needed. The Kits folder holds
{kits} kits of sounds: the DrumSynth 2.0 library and later presets. Kit, Set
location chooses another folder of kits; the choice is kept in DrumSyn.ini.

Press F1 to F12 to play the first sounds of a kit, Enter or F5 to play the
sound being edited. All keys and controls are described in gui-help.md (the
Help button opens it).

Spoken messages: with NVDA running, messages such as "Saved" are spoken
through Tolk (Tolk.dll and nvdaControllerClient64.dll); otherwise they go out
as UI Automation notifications and appear in the status bar.

Requirements: Windows 10 or 11, 64-bit.

Licence
-------
DrumSynth is released under the MIT licence or the GNU GPL, version 2 or
(at your option) any later version: "MIT License.txt", gpl-2.0.txt,
readme.license. Third-party components and their licences are listed in
licenses/THIRD-PARTY.txt. Source code: https://github.com/dengopaiv/DrumSynth
(commit {commit}).
"""


def package(ver, out):
    name = f"DrumSynth-{ver}-win64"
    dest = os.path.join(out, name)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(os.path.join(dest, "licenses"))
    rel = os.path.join(REPO, "build", "app", "Release")
    shutil.copy2(os.path.join(rel, "DrumSynth.exe"), dest)
    shipped = []
    for dll in sorted(glob.glob(os.path.join(rel, "*.dll"))):
        if os.path.basename(dll).lower() in EXCLUDE_DLLS:
            continue
        shutil.copy2(dll, dest)
        shipped.append(os.path.basename(dll))
    # the Visual C++ runtime, app-local
    crt = sorted(glob.glob(r"C:\Program Files\Microsoft Visual Studio\*\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT"))
    if not crt:
        sys.exit("Visual C++ runtime redistributable folder not found")
    for dll in ("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll"):
        shutil.copy2(os.path.join(crt[-1], dll), dest)
        shipped.append(dll)
    shutil.copy2(os.path.join(REPO, "docs", "gui-help.md"), dest)
    for lic in ("MIT License.txt", "gpl-2.0.txt", "readme.license"):
        shutil.copy2(os.path.join(REPO, lic), dest)

    notices = ["Third-party components shipped with DrumSynth", "",
               "Each is used unmodified as a separate DLL. Their licence texts are in this folder.", ""]
    for fname, src, covers in third_party():
        dll_glob = [c.strip() for c in covers.split(",")]
        present = any(glob.fnmatch.fnmatch(d.lower(), g.lower()) for d in shipped for g in dll_glob)
        if not present:
            continue
        if not os.path.exists(src):
            sys.exit(f"licence text missing: {src}")
        shutil.copy2(src, os.path.join(dest, "licenses", fname))
        notices.append(f"{covers}: {fname}")
    notices += ["vcruntime140.dll, vcruntime140_1.dll, msvcp140.dll: the Microsoft Visual C++ runtime, "
                "redistributed under the Visual Studio licence's distributable code terms.", "",
                "Tolk (https://github.com/dkager/tolk) and NVDA's controller client are LGPL "
                "libraries; their source is available from their projects, and they can be replaced by "
                "other builds of the same DLLs."]
    with open(os.path.join(dest, "licenses", "THIRD-PARTY.txt"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(notices) + "\n")

    kitdir = os.path.join(dest, "Kits")
    added, same, renamed = add_presets(kitdir)
    kits = len([d for d in os.listdir(kitdir) if os.path.isdir(os.path.join(kitdir, d))])
    # the program's settings: kits in the Kits folder (relative to the program)
    with open(os.path.join(dest, "DrumSyn.ini"), "w", encoding="ascii", newline="\r\n") as f:
        f.write("[Files]\nPath=Kits\nSaveWAVs=1\n")
    commit = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"], capture_output=True,
                            text=True).stdout.strip()
    with open(os.path.join(dest, "README.txt"), "w", encoding="utf-8", newline="\r\n") as f:
        f.write(README.format(version=ver, kits=kits, commit=commit))

    zpath = os.path.join(out, name + ".zip")
    if os.path.exists(zpath):
        os.remove(zpath)
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for root, _, files in os.walk(dest):
            for fn in sorted(files):
                full = os.path.join(root, fn)
                z.write(full, os.path.join(name, os.path.relpath(full, dest)))
    digest = hashlib.sha256(open(zpath, "rb").read()).hexdigest()
    with open(zpath + ".sha256", "w", encoding="ascii", newline="\n") as f:
        f.write(f"{digest}  {os.path.basename(zpath)}\n")
    print(f"{zpath}: {os.path.getsize(zpath) / 1e6:.1f} MB, sha256 {digest}")
    print(f"presets: {added} files written ({renamed} renamed), {same} duplicates skipped, {kits} kits")
    print("shipped DLLs:", ", ".join(shipped))
    return zpath


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--skip-tests", action="store_true")
    ap.add_argument("--skip-build", action="store_true")
    ap.add_argument("--out", default=os.path.join(REPO, "dist"))
    args = ap.parse_args()
    ver = version()
    print("DrumSynth", ver)
    if not args.skip_build:
        build()
    if not args.skip_tests:
        tmp = os.path.join(args.out, "_test")
        os.makedirs(tmp, exist_ok=True)
        test(tmp)
        shutil.rmtree(tmp, ignore_errors=True)
    package(ver, args.out)


if __name__ == "__main__":
    main()
