# How Windows reads a `.ds` file

The original engine reads every value with `GetPrivateProfileStringA` and `GetPrivateProfileIntA`, so their rules decide what a preset means. Microsoft's documentation does not give them in full. These were found by experiment on Windows 11, 2026-11-08: `python tools/probes/ini_rules.py` writes small files and prints what Windows returns.

The engine's own parser follows these rules (`engine/src/ds_ini.c`). `tools/probes/ini_probe.c` checks it against the 64-bit and the 32-bit Windows functions on every preset and on about 200 generated files, about 91,000 queries each way, with no differences ([probes.md](probes.md)).

## Lines

- A line ends at LF **or CR**. CRLF, LF-only and CR-only files read the same.
- White space is **every character from 0x01 to 0x20**: not only space and tab, but also every control character. It is ignored at both ends of every line, name and value. Bytes 0x7F and 0x80–0xFF are not white space in strings.
- A line starting with `;`, after white space, is a comment. `#` and `//` are not special.
- A line without `=` is ignored. A line `a` followed by `a=1` gives `1`.
- Keys before the first section cannot be read, not even with the section name `""`.

## Sections

- A line starting with `[` starts a section. Its name is the text up to the **first** `]`, or to the end of the line if there is none, without white space at its ends:
  - `[ T ]`, `[T ] x`, `[T]]`, `[T]x]`, `[T` and `[\tT\t]` all give `T`;
  - `[[T]]` gives `[T`.
- An empty name, `[]` or `[ ]`, can be read with the section name `""`.
- Only the first section with a name is searched. In `[T] a=1` … `[T] b=3`, `b` is not found.

## Keys and values

- The key name is the text before the first `=`, without white space at its ends. Spaces inside a name count: `a b` is not `a  b`.
- Names are compared without regard to case.
- The names asked for are used without **spaces** at their ends, but other white space counts: `" Test "` finds `[Test]`, `"Test\t"` doesn't.
- The first key with the name wins.
- The value is the text after the `=`, without white space at its ends. `a==2` gives `=2`.
- A value of two or more characters enclosed in matching quotes, `"…"` or `'…'`, is returned without them. Spaces inside are kept: ` "  s  " ` gives `  s  `. A single `"` or an unmatched quote stays.
- At most `size − 1` characters are copied, after the quotes are removed. The return value is the number copied.
- A missing key gives the default value, without trailing spaces. Leading spaces are kept.

## `GetPrivateProfileIntA`

- It reads the value as above, with a 256-character buffer: numbers longer than 255 characters are cut.
- An empty value, or one of only white space, gives the default. A missing key also gives the default.
- Otherwise it skips every character that is at most `' '` **as a signed `char`**. That includes all bytes 0x80–0xFF: `"\x80-5"` gives −5.
- Then it reads an optional `+` or `-`, and an optional prefix `0x`, `0o` or `0b` (**lower case only**: `0X10` gives 0).
- Then digits of that base, letters in either case (`0xAB` and `0xab` are both 171), up to the first other character: `12abc` gives 12, `1.9` gives 1.
- The value wraps modulo 2³²: `4294967296` gives 0, `-5` gives 4294967291, which is −5 as an `int`.
- Quotes are removed first, so `"5"` gives 5.

## Not reproduced

- **Files containing NUL bytes.** Windows seems to guess an encoding: one file with a NUL had all its keys read as missing, another had the NUL treated as white space.
- **Files starting with a UTF-8 byte order mark.** Windows doesn't skip it, so the first section is lost. The engine does the same, but this hasn't been checked for UTF-16 files.

No preset has either.
