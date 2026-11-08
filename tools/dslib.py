"""Shared helpers for the DrumSynth tools: preset collections, .ds parsing, WAV reading.

A collection is a folder or a .zip of .ds files. Presets that appear in more
than one collection (same bytes, ignoring CR) are counted once, under the
first collection that has them.
"""
import hashlib
import os
import struct
import zipfile
from dataclasses import dataclass, field

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# bin/library.zip is the collection distributed with DrumSynth 2.0;
# drumsynths/ is a later, larger collection (86 presets exist only there).
DEFAULT_COLLECTIONS = [
    os.path.join(REPO, "bin", "library.zip"),
    os.path.join(REPO, "drumsynths"),
]


@dataclass
class Preset:
    key: str                 # "<collection>/<path inside it>", unique
    collection: str
    rel: str
    data: bytes
    md5: str
    original_wav: bytes | None = None   # WAV saved next to it by the original program
    ini: dict = field(default_factory=dict)


def _md5(data):
    return hashlib.md5(data.replace(b"\r", b"")).hexdigest()


def _zip_name(info):
    # Names without the UTF-8 flag are in the Windows code page; Python
    # decoded them as cp437.
    if info.flag_bits & 0x800:
        return info.filename
    try:
        return info.filename.encode("cp437").decode("cp1252")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return info.filename


def _iter_collection(root):
    """Yield (relative path, .ds bytes, original wav bytes or None)."""
    if root.lower().endswith(".zip"):
        with zipfile.ZipFile(root) as z:
            infos = {_zip_name(i): i for i in z.infolist() if not i.is_dir()}
            lower = {n.lower(): n for n in infos}
            for name in sorted(infos):
                if not name.lower().endswith(".ds"):
                    continue
                wav = lower.get(name[:-3].lower() + ".wav")
                yield name, z.read(infos[name]), (z.read(infos[wav]) if wav else None)
        return
    for d, dirs, files in os.walk(root):
        dirs.sort()
        lower = {f.lower(): f for f in files}
        for f in sorted(files):
            if not f.lower().endswith(".ds"):
                continue
            path = os.path.join(d, f)
            wav = lower.get(f[:-3].lower() + ".wav")
            with open(path, "rb") as fh:
                data = fh.read()
            wav_data = None
            if wav:
                with open(os.path.join(d, wav), "rb") as fh:
                    wav_data = fh.read()
            yield os.path.relpath(path, root).replace(os.sep, "/"), data, wav_data


def collection_name(root):
    base = os.path.basename(os.path.normpath(root))
    return base[:-4] if base.lower().endswith(".zip") else base


def load_presets(roots=None):
    """Unique presets from the collections, in a stable order.
    Returns (presets, number of duplicates skipped)."""
    seen = {}
    presets = []
    duplicates = 0
    for root in roots or DEFAULT_COLLECTIONS:
        name = collection_name(root)
        for rel, data, wav in _iter_collection(root):
            digest = _md5(data)
            if digest in seen:
                duplicates += 1
                kept = seen[digest]
                if wav and not kept.original_wav:   # keep an original render found with a copy
                    kept.original_wav = wav
                continue
            p = Preset(f"{name}/{rel}", name, rel, data, digest, wav, parse_ds(data))
            seen[digest] = p
            presets.append(p)
    return presets, duplicates


def parse_ds(data):
    """.ds bytes -> {section: {key: value}}, section and key names lower-case.
    Like GetPrivateProfileString, the first occurrence of a key wins."""
    ini = {}
    section = ""
    for line in data.decode("latin-1").splitlines():
        line = line.strip()
        if line.startswith("[") and "]" in line:
            section = line[1:line.index("]")].strip().lower()
            ini.setdefault(section, {})
        elif "=" in line:
            k, v = line.split("=", 1)
            ini.setdefault(section, {}).setdefault(k.strip().lower(), v.strip())
    return ini


def get_num(ini, section, key, default=0.0):
    try:
        return float(ini.get(section, {}).get(key, ""))
    except ValueError:
        return default


def has_key(ini, section, key):
    return key in ini.get(section, {})


OVERTONE_METHODS = {0: "Add", 1: "FM", 2: "RM", 3: "808 Cymbal"}


def features(ini):
    """Names of the DrumSynth features a preset uses, for grouping results."""
    on = lambda s: get_num(ini, s, "on") == 1
    f = []
    if on("tone"):
        f.append("tone")
        if get_num(ini, "tone", "droop") > 0:
            f.append("tone droop")
    if on("noise"):
        f.append("noise")
        if get_num(ini, "noise", "slope") != 0:
            f.append("noise slope")
        if not has_key(ini, "noise", "level"):
            f.append("noise level key missing")
    if on("overtones"):
        method = int(get_num(ini, "overtones", "method", 2))
        f.append(f"overtones {OVERTONE_METHODS.get(method, method)}")
        if get_num(ini, "overtones", "track1") == 1 or get_num(ini, "overtones", "track2") == 1:
            f.append("overtone tracking")
    if on("noiseband"):
        f.append("noise band 1")
    if on("noiseband2"):
        f.append("noise band 2")
        if not has_key(ini, "noiseband2", "f") or not has_key(ini, "noiseband2", "df"):
            f.append("noise band 2 F/dF key missing")
    if on("distortion"):
        f.append("distortion")
        if get_num(ini, "distortion", "bits") > 0:
            f.append("bit reduction")
        if get_num(ini, "distortion", "rate") > 0:
            f.append("downsampling")
    if get_num(ini, "general", "filter") == 1:
        f.append("filter")
    elif get_num(ini, "overtones", "filter") == 1 and on("overtones"):
        f.append("filter (overtones only)")
    if get_num(ini, "general", "highpass") == 1 and any(x.startswith("filter") for x in f):
        f.append("high-pass")
    if get_num(ini, "general", "stretch", 100) != 100:
        f.append("stretch")
    if get_num(ini, "general", "tuning") != 0:
        f.append("tuning")
    version = ini.get("general", {}).get("version", "")
    if not version.startswith("DrumSynth v2"):
        f.append(f"version {version or 'missing'}")
    return f


def read_wav(path_or_bytes):
    """16-bit PCM WAV -> (sample rate, channels, samples as list-like int16 bytes).
    Returns (rate, channels, data_bytes, info_text)."""
    if isinstance(path_or_bytes, (bytes, bytearray)):
        d = bytes(path_or_bytes)
    else:
        with open(path_or_bytes, "rb") as fh:
            d = fh.read()
    if d[:4] != b"RIFF" or d[8:12] != b"WAVE":
        raise ValueError("not a RIFF WAVE file")
    i, rate, channels, bits, data, info = 12, None, None, None, None, ""
    while i + 8 <= len(d):
        cid = d[i:i + 4]
        n = struct.unpack("<I", d[i + 4:i + 8])[0]
        body = d[i + 8:i + 8 + n]
        if cid == b"fmt ":
            _, channels, rate, _, _, bits = struct.unpack("<HHIIHH", body[:16])
        elif cid == b"data":
            data = body
        elif cid == b"LIST":
            info = body.replace(b"\0", b" ").decode("latin-1").strip()
        i += 8 + n + (n & 1)
    if data is None or bits != 16:
        raise ValueError("no 16-bit PCM data")
    return rate, channels, data, info
