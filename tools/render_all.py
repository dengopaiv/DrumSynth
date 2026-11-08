"""Render every unique preset with one renderer, for compare_wavs.py.

Usage:
    python tools/render_all.py RENDERER [--out DIR] [--collections PATH ...]

RENDERER is one of:
    ref       original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit),
              at the Windows default x87 precision (53 bits): the reference
    ref-fpu24 the same DLL with x87 precision set to 24 bits (diagnostic)
    src       original drumsynth.c compiled with today's MSVC (32-bit)
    new       modern engine src/DrumSynth.Core (64-bit)
    new-x86   modern engine src/DrumSynth.Core (32-bit)
    c17       the C17 rewrite, engine/ (64-bit), reading presets with its own
              parser
    c17-libm  diagnostic: the C17 rewrite with today's C library math
    c17-winapi the C17 rewrite reading presets with the Windows profile
              functions, like the original
    original  no rendering: collects the WAVs the original program saved next
              to their presets
    custom    any renderer with the same command line, given with --exe
              (needs --name), for experiments

Build the renderers first (see tools/renderers/CMakeLists.txt).

Output, under DIR (default: renders/ in the repository, not tracked by git):
    presets/NNNN.ds        the unique presets, numbered (ASCII paths for the
                           original engine's ANSI file functions)
    RENDERER/NNNN.wav      the renders
    RENDERER/manifest.csv  id, key, md5 and features of every preset
    RENDERER/info.txt      what rendered it, from which commit, when
    RENDERER/failures.csv  presets the renderer reported an error for

By default every preset is rendered in a process of its own, so every render
starts like the first sound after DrumSynth starts: the original engine keeps
its envelope tables in global variables, and one render can change the next
one (docs/findings.md).

Options:
    --name NAME       write to DIR/NAME instead of DIR/RENDERER
    --batch           render all presets in one process instead (to study the
                      carry-over between renders)
    --order reverse   render the presets in reverse order (with --batch: checks
                      whether a render depends on the one before it)
    --raw-stack       do not zero the stack before each render; the original
                      engine reads an uninitialized variable (docs/findings.md)
    --jobs N          render N presets at once (default: number of processors)
    --timeout S       stop a render after S seconds and count it as failed
                      (default 120): some inputs make the original loop forever
"""
import argparse
import concurrent.futures
import csv
import datetime
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dslib  # noqa: E402

REPO = dslib.REPO
X86 = os.path.join(REPO, "build", "renderers-x86", "Release")
X64 = os.path.join(REPO, "build", "renderers-x64", "Release")

RENDERERS = {
    "ref": ([os.path.join(X86, "ref_render.exe"), "--dll", os.path.join(REPO, "bin", "ds2wav.dll")],
            "original ds2wav.dll from DrumSynth 2.0 (bin/ds2wav.dll, 32-bit binary from 2000)"),
    "ref-fpu24": ([os.path.join(X86, "ref_render.exe"), "--dll", os.path.join(REPO, "bin", "ds2wav.dll"),
                   "--fpu", "24"],
                  "original ds2wav.dll with the x87 unit set to 24-bit (float) precision; "
                  "a diagnostic, not how the original program ran"),
    "src": ([os.path.join(X86, "src_render.exe")],
            "original drumsynth.c (repository root) compiled with today's MSVC, 32-bit"),
    "new": ([os.path.join(X64, "new_render.exe")],
            "modern engine src/DrumSynth.Core compiled with today's MSVC, 64-bit"),
    "new-x86": ([os.path.join(X86, "new_render.exe")],
                "modern engine src/DrumSynth.Core compiled with today's MSVC, 32-bit"),
    "c17": ([os.path.join(X64, "c17_render.exe")],
            "C17 rewrite engine/ (64-bit), its own .ds parser"),
    "c17-winapi": ([os.path.join(X64, "c17_render.exe"), "--dll", "winapi"],
                   "C17 rewrite engine/ (64-bit), reading .ds files with the Windows profile functions"),
    "c17-libm": ([os.path.join(X64, "c17_libm_render.exe")],
                 "diagnostic: the C17 rewrite with today's C library for sin, cos, pow, exp, fmod and "
                 "text-to-float instead of the original's x87 sequences and VC6 routines"),
    "original": (None, "WAVs saved by the original DrumSynth program next to their presets"),
    "custom": ([], "a renderer given with --exe, for experiments"),
}


def git(*args):
    try:
        return subprocess.run(["git", "-C", REPO, *args], capture_output=True, text=True,
                              check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("renderer", choices=RENDERERS)
    ap.add_argument("--out", default=os.path.join(REPO, "renders"))
    ap.add_argument("--collections", nargs="+", default=None)
    ap.add_argument("--name", help="output folder name (default: the renderer's name)")
    ap.add_argument("--order", choices=["natural", "reverse"], default="natural",
                    help="render order; reverse is for checking that a render does not "
                         "depend on the presets rendered before it")
    ap.add_argument("--batch", action="store_true",
                    help="render all presets in one process, so each render sees the global "
                         "state left by the previous one (default: one process per preset)")
    ap.add_argument("--raw-stack", action="store_true",
                    help="do not zero the stack before each render (see renderer_main.c)")
    ap.add_argument("--timeout", type=float, default=120,
                    help="seconds before a render is stopped and counted as failed (default 120); "
                         "some inputs make the original DLL loop forever")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 1,
                    help="presets rendered at the same time, each in its own process "
                         "(default: the number of processors; ignored with --batch)")
    ap.add_argument("--exe", nargs="+", help="custom renderer: program and its options")
    ap.add_argument("--description", help="custom renderer: what it is, for the reports")
    args = ap.parse_args()
    name = args.name or args.renderer

    command, description = RENDERERS[args.renderer]
    if args.renderer == "custom":
        if not args.exe or not args.name:
            sys.exit("custom needs --exe PROGRAM [OPTIONS] and --name")
        command, description = args.exe, args.description or " ".join(args.exe)
    if command and not os.path.exists(command[0]):
        sys.exit(f"{command[0]} not found; build tools/renderers first")

    presets, duplicates = dslib.load_presets(args.collections)
    out = os.path.abspath(args.out)
    preset_dir = os.path.join(out, "presets")
    target = os.path.join(out, name)
    if os.path.isdir(target):
        shutil.rmtree(target)
    os.makedirs(preset_dir, exist_ok=True)
    os.makedirs(target)

    ids = [f"{i:04d}" for i in range(1, len(presets) + 1)]
    with open(os.path.join(target, "manifest.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "key", "md5", "features"])
        for pid, p in zip(ids, presets):
            w.writerow([pid, p.key, p.md5, "; ".join(dslib.features(p.ini))])

    failures = []
    started = datetime.datetime.now()
    if command is None:
        rendered = 0
        for pid, p in zip(ids, presets):
            if p.original_wav:
                with open(os.path.join(target, pid + ".wav"), "wb") as f:
                    f.write(p.original_wav)
                rendered += 1
    else:
        for pid, p in zip(ids, presets):
            path = os.path.join(preset_dir, pid + ".ds")
            with open(path, "wb") as f:
                f.write(p.data)
        extra = ["--no-clear-stack"] if args.raw_stack else []
        order = ids if args.order == "natural" else ids[::-1]
        codes = {}
        if args.batch:
            # One process renders everything: each render sees the global
            # state the previous one left behind (docs/findings.md).
            list_path = os.path.join(target, "render.list")
            with open(list_path, "w", encoding="ascii", newline="\n") as f:
                for pid in order:
                    f.write(f"{os.path.join(preset_dir, pid + '.ds')}\t{os.path.join(target, pid + '.wav')}\n")
            result = subprocess.run(command + extra + [list_path], capture_output=True, text=True)
            os.remove(list_path)
            if result.returncode not in (0, 1):
                sys.stderr.write(result.stderr)
                sys.exit(f"renderer failed to start (exit code {result.returncode})")
            outputs = [result.stdout]
        else:
            # One process per preset: every render starts like the first
            # sound after the program starts, with all global tables zero.
            # The processes are independent, so --jobs runs several at once.
            # A render that takes longer than --timeout is stopped and counted
            # as failed: some inputs make the original DLL loop forever
            # (docs/findings.md, section 9).
            def one(pid):
                cmd = command + extra + [os.path.join(preset_dir, pid + ".ds"), os.path.join(target, pid + ".wav")]
                try:
                    return pid, subprocess.run(cmd, capture_output=True, text=True, timeout=args.timeout)
                except subprocess.TimeoutExpired:
                    timeouts.append(pid)
                    return pid, subprocess.CompletedProcess(cmd, 1, f"timeout\t{pid}.ds\n", "")
            timeouts = []
            outputs = []
            notes = []
            with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
                for pid, result in pool.map(one, order):
                    if result.returncode not in (0, 1):
                        sys.stderr.write(result.stderr)
                        sys.exit(f"renderer failed on {pid} (exit code {result.returncode})")
                    outputs.append(result.stdout)
                    notes += [ln for ln in result.stderr.splitlines() if ln.startswith("notes ")]
            if notes or timeouts:
                # the C17 engine's notes (DS_NOTE_*), and renders that never ended
                with open(os.path.join(target, "notes.csv"), "w", newline="", encoding="utf-8") as f:
                    w = csv.writer(f)
                    w.writerow(["id", "note"])
                    for ln in notes:
                        flags, _, path = ln[6:].partition("\t")
                        w.writerow([os.path.splitext(os.path.basename(path))[0], "flags " + flags])
                    for pid in timeouts:
                        w.writerow([pid, f"timeout after {args.timeout:g} s"])
        for out_text in outputs:
            for line in out_text.splitlines():
                code, _, path = line.partition("\t")
                codes[os.path.splitext(os.path.basename(path))[0]] = int(code) if code.lstrip("-").isdigit() else code
        by_id = dict(zip(ids, presets))
        for pid in ids:
            code = codes.get(pid)
            if code != 0 or not os.path.exists(os.path.join(target, pid + ".wav")):
                failures.append((pid, by_id[pid].key, "no result" if code is None else code))
        rendered = len(ids) - len(failures)

    with open(os.path.join(target, "failures.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "key", "result code"])
        w.writerows(failures)

    seconds = (datetime.datetime.now() - started).total_seconds()
    dirty = " (with uncommitted changes)" if git("status", "--porcelain", "--", "src", "drumsynth.c", "engine") else ""
    with open(os.path.join(target, "info.txt"), "w", encoding="utf-8") as f:
        f.write(f"renderer: {args.renderer}\n")
        f.write(f"mode: {'batch (one process for all presets)' if args.batch else 'fresh (one process per preset)'}\n")
        f.write(f"order: {args.order}\n")
        f.write(f"stack cleared before each render: {'no' if args.raw_stack else 'yes'}\n")
        f.write(f"description: {description}\n")
        f.write(f"commit: {git('rev-parse', '--short', 'HEAD')}{dirty}\n")
        f.write(f"date: {started:%Y-%m-%d %H:%M}\n")
        f.write(f"cpu: {dslib.cpu_name()}\n")
        f.write(f"presets: {len(presets)} unique ({duplicates} duplicates skipped)\n")
        f.write(f"rendered: {rendered}\n")
        f.write(f"failed: {len(failures)}\n")

    print(f"{name}: {len(presets)} presets, {rendered} WAVs, {len(failures)} failed, {seconds:.1f} s")
    for pid, key, code in failures[:20]:
        print(f"  failed {pid} {key}: {code}")


if __name__ == "__main__":
    main()
