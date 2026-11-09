"""Make web pages from the Markdown documentation: the program's help page,
gui-help.html, and the release's Documentation folder.

Usage:
    python tools/make_help_html.py [OUT.html] [--source docs/gui-help.md]

The Help button opens gui-help.html in the web browser. A browser shows the
tables and headings properly, and screen readers can move through it by
heading (H) and table (T, then Ctrl+Alt+arrows). The Markdown file, opened
in Notepad, would read out every "|" and "**".

The app's build (app/CMakeLists.txt) runs this next to DrumSynth.exe.
make_release.py calls write_page() for the help and for the other pages it
ships, with a map of which repository files become which pages: links to
those go to the local pages, links to anything else to the file on GitHub.

The converter needs nothing but Python, and handles only what the shipped
documents use:

    # ## ###  headings          - item    lists (nested by two spaces)
    1. item   numbered lists    | a | b | tables (first row is the header)
    **bold**  `code`  [text](url)  ```fenced code blocks```
    and paragraphs of one or more lines

Anything else (quotes, indented code, ####) stops it with an error, so a page
can't silently lose text. Keep the shipped documents within that subset.
"""
import argparse
import html
import os
import posixpath
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GITHUB = "https://github.com/dengopaiv/DrumSynth/blob/master/"

CSS = """
:root { color-scheme: light dark; --bg: #ffffff; --fg: #1a1a1a; --muted: #555555;
  --line: #c8c8c8; --head: #f0f0f0; --code: #f3f3f3; --link: #0645ad; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #1e1e1e; --fg: #e8e8e8; --muted: #b0b0b0; --line: #555555;
    --head: #2c2c2c; --code: #2a2a2a; --link: #8ab4f8; } }
body { background: var(--bg); color: var(--fg); margin: 0 auto; max-width: 52rem;
  padding: 1rem 1rem 3rem; font: 1rem/1.55 "Segoe UI", system-ui, sans-serif; }
h1 { font-size: 1.8rem; margin-top: 0.5rem; }
h2 { font-size: 1.4rem; margin-top: 2rem; border-bottom: 1px solid var(--line); }
h3 { font-size: 1.15rem; margin-top: 1.5rem; }
a { color: var(--link); }
code { background: var(--code); padding: 0 0.25em; border-radius: 3px;
  font-family: Consolas, "Cascadia Mono", monospace; }
pre { background: var(--code); padding: 0.6rem 0.8rem; overflow-x: auto; border-radius: 3px; }
pre code { padding: 0; }
table { border-collapse: collapse; margin: 1rem 0; width: 100%; }
th, td { border: 1px solid var(--line); padding: 0.35rem 0.6rem; text-align: left; vertical-align: top; }
thead th { background: var(--head); }
tbody th { font-weight: normal; }
nav { border: 1px solid var(--line); padding: 0.5rem 1rem; margin: 1rem 0; }
nav ul { margin: 0.25rem 0; }
.source { color: var(--muted); font-size: 0.9rem; }
"""


class Unsupported(Exception):
    pass


def slug(text):
    """GitHub's heading anchors: lower case, punctuation dropped, spaces to -."""
    s = re.sub(r"[^\w\s-]", "", text.lower(), flags=re.UNICODE)
    return re.sub(r"\s", "-", s.strip())


class Converter:
    def __init__(self, link=None):
        # link(href) -> href: where a link in the Markdown should point
        self.link = link or (lambda h: h)

    def inline(self, text):
        """**bold**, `code` and [text](url); everything else escaped."""
        out = []
        pos = 0
        pattern = re.compile(r"`([^`]+)`|\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)\s]+)\)")
        for m in pattern.finditer(text):
            out.append(html.escape(text[pos:m.start()], quote=False))
            if m.group(1) is not None:
                out.append("<code>" + html.escape(m.group(1), quote=False) + "</code>")
            elif m.group(2) is not None:
                out.append("<strong>" + self.inline(m.group(2)) + "</strong>")
            else:
                href = self.link(m.group(4))
                out.append(f'<a href="{html.escape(href)}">{self.inline(m.group(3))}</a>')
            pos = m.end()
        out.append(html.escape(text[pos:], quote=False))
        s = "".join(out)
        if "**" in s or "`" in s:
            raise Unsupported(f"unmatched ** or ` in: {text}")
        return s

    @staticmethod
    def table_cells(line):
        line = line.strip()
        if not (line.startswith("|") and line.endswith("|")):
            raise Unsupported(f"table row must start and end with |: {line}")
        return [c.strip().replace("\\|", "|") for c in re.split(r"(?<!\\)\|", line[1:-1])]

    def convert(self, md):
        """The <body> content and the title, from the Markdown text."""
        lines = md.replace("\r\n", "\n").split("\n")
        body = []
        toc = []
        title = None
        i = 0
        n = len(lines)

        def is_block_start(s):
            return (s.startswith("#") or s.startswith("|") or s.startswith("```") or re.match(r"\s*- ", s)
                    or re.match(r"\d+\. ", s) or not s.strip())

        while i < n:
            line = lines[i]
            if not line.strip():
                i += 1
                continue
            if line.startswith("```"):
                code = []
                i += 1
                while i < n and not lines[i].startswith("```"):
                    code.append(lines[i])
                    i += 1
                if i == n:
                    raise Unsupported("a ``` code block isn't closed")
                i += 1
                body.append("<pre><code>" + html.escape("\n".join(code), quote=False) + "</code></pre>")
                continue
            if line.startswith(">") or line.startswith("    "):
                raise Unsupported(f"line {i + 1}: quotes and indented code blocks aren't supported")
            m = re.match(r"(#{1,6}) (.+)", line)
            if m:
                level = len(m.group(1))
                if level > 3:
                    raise Unsupported(f"line {i + 1}: only #, ## and ### headings are supported")
                text = m.group(2).strip()
                if level == 1:
                    if title is not None:
                        raise Unsupported(f"line {i + 1}: only one # heading")
                    title = re.sub(r"[`*]", "", text)
                    body.append(f"<h1>{self.inline(text)}</h1>")
                else:
                    hid = slug(text)
                    body.append(f'<h{level} id="{hid}">{self.inline(text)}</h{level}>')
                    if level == 2:
                        toc.append((hid, text))
                i += 1
                continue
            if line.startswith("|"):
                rows = []
                while i < n and lines[i].startswith("|"):
                    rows.append(self.table_cells(lines[i]))
                    i += 1
                if len(rows) < 2 or not all(re.fullmatch(r":?-{3,}:?", c) for c in rows[1]):
                    raise Unsupported("a table needs a header row and a |---| row")
                head, data = rows[0], rows[2:]
                out = ["<table>", "<thead><tr>"]
                out += [f'<th scope="col">{self.inline(c)}</th>' for c in head]
                out.append("</tr></thead>")
                out.append("<tbody>")
                for r in data:
                    if len(r) != len(head):
                        raise Unsupported(f"table row has {len(r)} cells, header {len(head)}: {r}")
                    # the first cell names the row, so screen readers say it when
                    # moving along the row
                    cells = [f'<th scope="row">{self.inline(r[0])}</th>']
                    cells += [f"<td>{self.inline(c)}</td>" for c in r[1:]]
                    out.append("<tr>" + "".join(cells) + "</tr>")
                out.append("</tbody></table>")
                body.append("\n".join(out))
                continue
            if re.match(r"\s*- ", line) or re.match(r"\d+\. ", line):
                items = []  # (indent, ordered, text)
                while i < n and (m := re.match(r"(\s*)(- |\d+\. )(.*)", lines[i])):
                    items.append((len(m.group(1)), m.group(2) != "- ", m.group(3)))
                    i += 1
                body.append(self.render_list(items))
                continue
            para = [line.strip()]
            i += 1
            while i < n and not is_block_start(lines[i]):
                para.append(lines[i].strip())
                i += 1
            body.append(f"<p>{self.inline(' '.join(para))}</p>")

        if title is None:
            raise Unsupported("the page needs a # title")
        if len(toc) >= 3:
            nav = ['<nav aria-label="Contents"><strong>Contents</strong><ul>']
            nav += [f'<li><a href="#{hid}">{self.inline(t)}</a></li>' for hid, t in toc]
            nav.append("</ul></nav>")
            # after the title and the paragraphs before the first ## heading
            first = next(k for k, b in enumerate(body) if b.startswith("<h2"))
            body.insert(first, "\n".join(nav))
        return title, "\n".join(body)

    def render_list(self, items):
        """Nested <ul>/<ol> from (indent, ordered, text) items."""
        out = []
        stack = []  # (indent, tag)

        def open_list(indent, ordered):
            tag = "ol" if ordered else "ul"
            out.append(f"<{tag}>")
            stack.append((indent, tag))

        for indent, ordered, text in items:
            if not stack:
                open_list(indent, ordered)
            elif indent > stack[-1][0]:
                out[-1] = out[-1][: -len("</li>")]  # the sublist goes inside the previous item
                open_list(indent, ordered)
            else:
                while stack and indent < stack[-1][0]:
                    out.append(f"</{stack.pop()[1]}></li>")
                if not stack or indent != stack[-1][0]:
                    raise Unsupported(f"list indentation doesn't line up: {text}")
            out.append(f"<li>{self.inline(text)}</li>")
        while stack:
            out.append(f"</{stack.pop()[1]}>")
            if stack:
                out.append("</li>")
        return "\n".join(out)


def page(title, content, source_name):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>{CSS}</style>
</head>
<body>
<main>
{content}
</main>
<p class="source">Made from {html.escape(source_name)} by tools/make_help_html.py.</p>
</body>
</html>
"""


def repo_linker(source_rel, pages, out_rel):
    """A link function for the page made from source_rel (a repository path,
    with /) at out_rel (a path in the output folder). pages maps repository
    paths to output paths. Links to a mapped file go to its page, relative to
    this one; other relative links go to the file on GitHub. Links to GitHub
    that name a mapped file go to its page too."""
    def link(href):
        if href.startswith("#"):
            return href
        target, _, anchor = href.partition("#")
        if target.startswith(GITHUB):
            repo_path = target[len(GITHUB):]
        elif re.match(r"[a-z]+:", target):
            return href
        else:
            repo_path = posixpath.normpath(posixpath.join(posixpath.dirname(source_rel), target))
        if repo_path in pages:
            rel = posixpath.relpath(pages[repo_path], posixpath.dirname(out_rel) or ".")
            return rel + ("#" + anchor if anchor else "")
        if target.startswith(GITHUB):
            return href
        return GITHUB + repo_path + ("#" + anchor if anchor else "")
    return link


def write_page(source, out, link=None, source_name=None):
    """Convert one Markdown file to a page. Writes only when the result
    changed, so builds don't touch the file needlessly. Raises Unsupported."""
    with open(source, encoding="utf-8") as f:
        md = f.read()
    title, content = Converter(link).convert(md)
    text = page(title, content, source_name or os.path.basename(source))
    try:
        with open(out, encoding="utf-8", newline="") as f:
            if f.read() == text:
                return False
    except OSError:
        pass
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out", nargs="?", default="gui-help.html")
    ap.add_argument("--source", default=os.path.join(REPO, "docs", "gui-help.md"))
    args = ap.parse_args()
    try:
        if write_page(args.source, args.out):
            print(f"{args.out} written")
    except Unsupported as e:
        sys.exit(f"{args.source}: {e}")


if __name__ == "__main__":
    main()
