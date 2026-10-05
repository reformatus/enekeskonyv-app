#!/usr/bin/env python3
"""Repair wrong referdelyi-*-001.svg source sheets.

The original import took pdf_links[0] of the number-matched site page and
cropped only at a global "2." marker. That produced wrong sources because
the app songbook numbering is a reordered edition: the site's (and the
printed book's) numbers are printed numbers from tool/printed_numbers.json,
not app song numbers.

This tool resolves each song's printed number, opens that number's site
page, anchors the region on the printed-number heading inside the linked
PDFs, extracts the matching SVG elements, stacks multi-page pieces, and
rewrites the -001.svg source. The printed first lyric row is similarity-
checked against the songbook verse text and reported for triage.

Usage:
    python3 tool/repair_score_sources.py 132 195 404 ...
    python3 tool/repair_score_sources.py --audit   # report only, no writes

Requires poppler-utils (pdftotext, pdftocairo) and network access to
enekeskonyv.reformatus.hu.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import import_reformatus_scores as m

SVG_NS = 'http://www.w3.org/2000/svg'
XLINK = 'http://www.w3.org/1999/xlink'
ET.register_namespace('', SVG_NS)
ET.register_namespace('xlink', XLINK)
NS = f'{{{SVG_NS}}}'
HREF = f'{{{XLINK}}}href'

PDF_CACHE = Path('/tmp/repair_pdfs')
PIECE_GAP = 12.0


def normalize(text: str) -> str:
    text = re.sub(r'[^a-záéíóöőúüű0-9]', '', text.lower())
    return text


def fetch_pdf(url: str) -> Path:
    PDF_CACHE.mkdir(exist_ok=True)
    path = PDF_CACHE / url.rsplit('/', 1)[-1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return path


def pdf_words(pdf_path: Path) -> tuple[float, float, list[dict]]:
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / 'b.html'
        subprocess.run(
            ['pdftotext', '-bbox-layout', str(pdf_path), str(out)],
            check=True, capture_output=True,
        )
        return m.extract_words_from_bbox_html(out.read_text(encoding='utf-8'))


def pdf_to_svg(pdf_path: Path) -> Path:
    out = pdf_path.with_suffix('.svg')
    if not out.exists():
        subprocess.run(
            ['pdftocairo', '-svg', str(pdf_path), str(out)],
            check=True, capture_output=True,
        )
    return out


def group_rows(words: list[dict]) -> list[tuple[float, list[dict]]]:
    rows: list[tuple[float, list[dict]]] = []
    for w in sorted(words, key=lambda w: w['y_min']):
        for i, (y, ws) in enumerate(rows):
            if abs(y - w['y_min']) < 2.5:
                ws.append(w)
                break
        else:
            rows.append((w['y_min'], [w]))
    return [(y, sorted(ws, key=lambda w: w['x_min'])) for y, ws in rows]


def find_headings(words: list[dict], page_height: float) -> list[float]:
    return sorted(
        w['y_min']
        for w in words
        if re.fullmatch(r'\d{1,3}', w['text'])
        and w['y_max'] - w['y_min'] > 14
        and w['y_min'] < page_height * 0.92
    )


def row_text(ws: list[dict]) -> str:
    return ' '.join(w['text'] for w in ws)


def find_v1_row(rows, json_line1: str):
    jn = normalize(json_line1)
    best = (0.0, None)
    for y, ws in rows:
        pn = normalize(row_text(ws))
        pn = re.sub(r'^\d+', '', pn)
        if len(pn) < 6:
            continue
        ratio = difflib.SequenceMatcher(None, pn, jn[: len(pn)]).ratio()
        if ratio > best[0]:
            best = (ratio, y)
    return best


def standalone_marker_ys(rows) -> list[float]:
    """Y positions of standalone verse-number rows ('2.', '3.'...) at the
    left margin — verse 2+ is printed as prose, verse 1 is the syllabified
    lyric row itself, so only markers >= 2 bound a region."""
    ys = []
    for y, ws in rows:
        if (
            ws
            and re.fullmatch(r'\d+\.', ws[0]['text'])
            and int(ws[0]['text'][:-1]) >= 2
            and ws[0]['x_min'] < 65
        ):
            ys.append(y)
    return ys


def _is_private_use(t: str) -> bool:
    return len(t) == 1 and 0xE000 <= ord(t) <= 0xF8FF


def _is_furniture_word(w: dict) -> bool:
    t = w['text']
    if _is_private_use(t):
        return False  # music glyph, not text
    return t.isdigit() or re.fullmatch(r'[A-ZÁÉÍÓÖŐÚÜŰ]+', t) is not None


def _furniture_rows(rows, page_height: float):
    """Rows of page furniture near the page bottom — section title plus
    page number, e.g. 'ZSOLTÁROK  264' or 'I stentisztelet 596'."""
    for y, ws in rows:
        if y < page_height * 0.85:
            continue
        text_ws = [w for w in ws if not _is_private_use(w['text'])]
        if not text_ws or looks_like_lyrics(ws):
            continue
        if any(re.fullmatch(r'\d{2,3}', w['text']) for w in text_ws):
            yield y, ws


def furniture_ys(rows, page_height: float) -> list[float]:
    return [y for y, _ws in _furniture_rows(rows, page_height)]


def furniture_boxes(rows, page_height: float) -> list[tuple]:
    """Word boxes of furniture text near the page bottom."""
    return [
        (w['x_min'], w['y_min'], w['x_max'], w['y_max'])
        for _y, ws in _furniture_rows(rows, page_height)
        for w in ws
        if not _is_private_use(w['text'])
    ]


def first_boundary_on_page(words, page_height):
    """Return (cut_y, ended): first real boundary (next heading or verse
    marker) or the page bottom / furniture top."""
    rows = group_rows(words)
    cands = find_headings(words, page_height) + standalone_marker_ys(rows)
    furn = furniture_ys(rows, page_height)
    cut = min(cands + furn + [page_height])
    ended = bool(cands) and min(cands) <= cut
    return cut, ended


def looks_like_lyrics(ws) -> bool:
    """A syllabified lyric row: contains standalone '-' separators or
    hyphenated fragments (as opposed to verse-2+ prose rows)."""
    text_ws = [w for w in ws if not _is_private_use(w['text'])]
    return any(w['text'] == '-' for w in text_ws)


def continuation_is_ours(words, page_height, cut: float, json_line1: str) -> bool:
    """Whether the page-top region [0, cut) belongs to the song's melody —
    i.e. it holds lyric rows, not verse-prose or a new song."""
    rows = group_rows(words)
    jn = normalize(json_line1)
    for y, ws in rows:
        if y >= cut:
            break
        text = row_text(ws)
        if not text.strip():
            continue
        if looks_like_lyrics(ws):
            return True
        pn = normalize(re.sub(r'^\d+\.', '', text))
        if len(pn) >= 8 and any(
            difflib.SequenceMatcher(None, pn[i : i + 20], jn[j : j + 20]).ratio() > 0.8
            for i in range(0, max(1, len(pn) - 20), 8)
            for j in range(0, max(1, len(jn) - 20), 8)
        ):
            return True
    return False


def clip_rects(root) -> dict[str, tuple[float, float]]:
    rects = {}
    for cp in root.iter(f'{NS}clipPath'):
        cid = cp.get('id')
        ys = [
            float(v)
            for p in cp.iter(f'{NS}path')
            for v in re.findall(r'[-\d.]+', p.get('d', ''))[1::2]
        ]
        if cid and ys:
            rects[cid] = (min(ys), max(ys))
    return rects


def element_y_range(el, rects) -> tuple[float, float] | None:
    cp = el.get('clip-path', '')
    mref = re.match(r'url\(#([^)]+)\)', cp)
    if mref and mref.group(1) in rects:
        return rects[mref.group(1)]
    ys = [float(u.get('y', '0')) for u in el.iter(f'{NS}use')]
    if ys:
        return min(ys) - 6.0, max(ys)
    # path with transform: use translate-y of matrix
    tr = el.get('transform', '')
    mm = re.match(r'matrix\(([^)]*)\)', tr)
    if mm:
        vals = [float(v) for v in mm.group(1).replace(',', ' ').split()]
        return vals[5] - 10.0, vals[5] + 10.0
    nums = [float(v) for v in re.findall(r'[-\d.]+', el.get('d', ''))]
    if len(nums) >= 2:
        pys = nums[1::2]
        return min(pys), max(pys)
    return None


def rewrite_refs(el, prefix: str):
    for e in el.iter():
        if e.get('id'):
            e.set('id', prefix + e.get('id'))
        href = e.get(HREF)
        if href and href.startswith('#'):
            e.set(HREF, '#' + prefix + href[1:])
        for attr in ('clip-path', 'fill', 'filter', 'mask'):
            v = e.get(attr, '')
            if 'url(#' in v:
                e.set(attr, re.sub(r'url\(#', f'url(#{prefix}', v))


def _inside_furniture(uses, boxes) -> bool:
    """True if every use position lands inside some furniture word box."""
    if not uses or not boxes:
        return False
    for x, y in uses:
        if not any(
            bx0 - 1.5 <= x <= bx1 + 1.5 and by0 - 2 <= y <= by1 + 3.5
            for bx0, by0, bx1, by1 in boxes
        ):
            return False
    return True


_PATH_ARITY = {
    'M': 2, 'L': 2, 'C': 6, 'S': 4, 'Q': 4, 'T': 2,
    'A': 7, 'V': 1, 'H': 1, 'Z': 0,
}
_PATH_YPOS = {
    'M': (1,), 'L': (1,), 'C': (1, 3, 5), 'S': (1, 3), 'Q': (1, 3),
    'T': (1,), 'A': (6,), 'V': (0,),
}
_PATH_TOKEN = re.compile(
    r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?'
)


def _shift_path_d(d: str, dy: float) -> str:
    """Shift the y coordinates of absolute path commands by dy. Relative
    (lowercase) commands and non-coordinate params (arc rotation/flags,
    H x-values) are left untouched."""
    out, run, cmd = [], [], ''

    def flush():
        if not run:
            return
        arity = _PATH_ARITY.get(cmd.upper(), 0)
        ys = set() if cmd.islower() else set(_PATH_YPOS.get(cmd.upper(), ()))
        for idx, v in enumerate(run):
            pos = idx % arity if arity else 0
            out.append(f'{float(v) + dy:g}' if arity and pos in ys else v)
        run.clear()

    for p in _PATH_TOKEN.findall(d):
        if p.isalpha():
            flush()
            cmd = p
            out.append(p)
        else:
            run.append(p)
    flush()
    return ' '.join(out)


def _shift_y(el, dy: float) -> None:
    """Add dy to every absolute y coordinate an element carries, so stitched
    pieces keep a flat coordinate space the generator understands."""
    for node in el.iter():
        if node.tag == f'{NS}use' and node.get('y') is not None:
            node.set('y', f'{float(node.get("y")) + dy:.3f}')
        # An untransformed path carries absolute page coordinates in d —
        # shift them too, or it renders at its original position (off the
        # rebased region). A path with transform positions via the matrix.
        if node.tag == f'{NS}path' and not node.get('transform'):
            d = node.get('d')
            if d:
                node.set('d', _shift_path_d(d, dy))
        tr = node.get('transform', '')
        if tr:
            def _mat(mm):
                v = [float(x) for x in mm.group(1).replace(',', ' ').split()]
                v[5] += dy
                return 'matrix(' + ','.join(f'{x:g}' for x in v) + ')'

            node.set(
                'transform',
                re.sub(r'matrix\(([^)]*)\)', _mat, tr),
            )


def _shift_clip_paths(defs_parent, dy: float) -> None:
    """Clip rects are stored in absolute page coordinates — shift them with
    their piece (glyph defs are font-relative and must not move)."""
    for cp in defs_parent.iter(f'{NS}clipPath'):
        for p in cp.iter(f'{NS}path'):
            d = p.get('d', '')
            if d:
                p.set('d', _shift_path_d(d, dy))


def extract_piece(svg_path: Path, top: float, bottom: float, prefix: str,
                  dy: float, furn_boxes):
    """Return (defs_elements, content_elements) for elements whose center y is
    in [top, bottom), coordinates rebased so region top lands at dy."""
    root = ET.parse(svg_path).getroot()
    rects = clip_rects(root)
    defs = ET.Element(f'{NS}defs')
    content = []

    def top_level(node):
        # Some pdftocairo versions wrap page content in a single
        # <g id="surface…"> — treat its children as top level so the
        # region/furniture filters see elements, not the wrapper.
        for el in node:
            if el.tag == f'{NS}g' and (el.get('id') or '').startswith('surface'):
                yield from el
            else:
                yield el

    for el in top_level(root):
        if el.tag == f'{NS}defs':
            for d in el:
                rewrite_refs(d, prefix)
                defs.append(d)
            continue
        yr = element_y_range(el, rects)
        if yr is None:
            continue
        cy = (yr[0] + yr[1]) / 2
        if not (top - 1.0 <= cy < bottom - 1.0):
            continue
        uses = [
            (float(u.get('x', '0')), float(u.get('y', '0')))
            for u in el.iter(f'{NS}use')
        ]
        if _inside_furniture(uses, furn_boxes):
            continue
        rewrite_refs(el, prefix)
        _shift_y(el, dy - top)
        content.append(el)
    _shift_clip_paths(defs, dy - top)
    return list(defs), content


PRINTED_NUMBERS = json.loads(
    (Path(__file__).resolve().parent / 'printed_numbers.json').read_text()
)


def heading_y(words, page_height: float, number: int) -> float | None:
    ys = [
        w['y_min']
        for w in words
        if w['text'] == str(number)
        and w['y_max'] - w['y_min'] > 14
        and w['y_min'] < page_height * 0.92
    ]
    return min(ys) if ys else None


def first_boundary_below(words, page_height, y: float):
    """First real boundary strictly below y: next heading, verse-prose
    marker, or furniture row. Returns (cut_y, ended)."""
    rows = group_rows(words)
    cands = [h for h in find_headings(words, page_height) if h > y + 2]
    cands += [my for my in standalone_marker_ys(rows) if my > y + 2]
    furn = [fy for fy in furniture_ys(rows, page_height) if fy > y + 2]
    cut = min(cands + furn + [page_height])
    ended = bool(cands) and min(cands) <= cut
    return cut, ended


def repair_song(song: dict, song_number: str, audit_only: bool,
                source_path: Path) -> str:
    printed = PRINTED_NUMBERS.get(song_number)
    if printed is None:
        return f'{song_number}\tNO-PRINTED-NUM'
    page = m.search_song_page(str(printed))
    links = m.get_pdf_links(page) if page else []
    head_nums = [printed]
    if not links:
        # the numbered index misses some songs — fall back to title search;
        # those sheets use the site's own numbering, so accept that too
        title = re.sub(r'^\d+\.\s*', '', song['texts'][0].split('\n')[0])
        query = re.split(r'[,;:!?()]', title)[0].strip()
        url = f'{m.SEARCH_URL}?{urllib.parse.urlencode({"q": query})}'
        rows = m.extract_search_rows(m.fetch_text(url))
        tn = m.normalize_title(query)
        cand = [
            (num, href)
            for num, href, t in rows
            if m.normalize_title(t).startswith(tn)
        ]
        for num, href in cand or [(r[0], r[1]) for r in rows]:
            page = urllib.parse.urljoin(m.BASE_URL, href)
            links = m.get_pdf_links(page)
            if links:
                if num.isdigit():
                    head_nums.append(int(num))
                break
    if not links:
        return f'{song_number}\tNO-SITE-PAGE (printed {printed})'

    pieces = []  # (pdf_path, top, bottom, furn_boxes)
    vscore = 0.0
    started = False
    for url in links:
        pdf = fetch_pdf(url)
        pw, ph, words = pdf_words(pdf)
        rows = group_rows(words)
        fboxes = furniture_boxes(rows, ph)
        if not started:
            hy = min(
                (
                    h
                    for n in head_nums
                    if (h := heading_y(words, ph, n)) is not None
                ),
                default=None,
            )
            if hy is None:
                # D-sheets carry no printed number heading; accept the page
                # only if the first lyric row itself matches the song text
                sim0, y0 = find_v1_row(rows, song['texts'][0].split('\n')[0])
                if sim0 >= 0.7 and y0 is not None and y0 < ph * 0.3:
                    top = max(0.0, y0 - 30.0)
                    bottom, ended = first_boundary_below(words, ph, y0)
                    vscore = sim0
                    pieces.append((pdf, top, bottom, fboxes))
                    started = True
                    if ended:
                        break
                continue  # heading not on this pdf
            top = hy - 3.0
            bottom, ended = first_boundary_below(words, ph, hy)
            vscore, _vy = find_v1_row(
                [(ry, ws) for ry, ws in rows if top <= ry < bottom],
                song['texts'][0].split('\n')[0],
            )
            pieces.append((pdf, top, bottom, fboxes))
            started = True
            if ended:
                break
        else:
            b, ended = first_boundary_on_page(words, ph)
            if not continuation_is_ours(
                words, ph, b, song['texts'][0].split('\n')[0]
            ):
                break  # verse-prose continuation or a new song — we are done
            pieces.append((pdf, 0.0, b, fboxes))
            if ended:
                break

    if not pieces:
        return f'{song_number}\tNO-HEADING (printed {printed})'

    if audit_only:
        desc = '+'.join(
            f'{p.name}[{t:.0f}-{b:.0f}]' for p, t, b, _f in pieces
        )
        return (
            f'{song_number}\tFIXABLE\tprinted={printed}\t{desc}'
            f'\tlyric={vscore:.2f}'
        )

    total_h = sum(b - t for _, t, b, _f in pieces) + PIECE_GAP * (
        len(pieces) - 1
    )
    out = ET.Element(
        f'{NS}svg',
        {
            'width': '340.157',
            'height': f'{total_h:.3f}',
            'viewBox': f'0 0 340.157 {total_h:.3f}',
        },
    )
    defs_el = ET.SubElement(out, f'{NS}defs')
    dy = 0.0
    for i, (pdf, top, bottom, fboxes) in enumerate(pieces):
        svg_path = pdf_to_svg(pdf)
        defs, content = extract_piece(
            svg_path, top, bottom, f'p{i}-', dy, fboxes
        )
        for d in defs:
            defs_el.append(d)
        for el in content:
            out.append(el)
        dy += (bottom - top) + PIECE_GAP
    source_path.write_text(
        ET.tostring(out, encoding='utf-8', xml_declaration=True).decode(),
        encoding='utf-8',
    )
    return f'{song_number}\tREPAIRED\t{len(pieces)} piece(s)'


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('songs', nargs='*')
    ap.add_argument('--audit', action='store_true')
    args = ap.parse_args()

    songbook = m.load_songbook()
    erdelyi = songbook['erdelyi']
    songs = args.songs
    if args.audit and not songs:
        # Bare --audit sweeps every printed-number mapping.
        songs = sorted(PRINTED_NUMBERS, key=int)
    for n in songs:
        n = n.lstrip('0') or '0'
        song = erdelyi.get(n)
        if song is None:
            print(f'{n}\tnot in songbook')
            continue
        src = m.source_svg_path(n)
        print(repair_song(song, n, args.audit, src))
    return 0


if __name__ == '__main__':
    sys.exit(main())
