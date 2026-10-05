#!/usr/bin/env python3
"""Validate SVG onset detection against real PDF lyric positions.

For each requested Erdélyi song number, downloads the song's score PDF
(same source the PNG import uses), extracts lyric-word xMin positions with
pdftotext -bbox, and compares them with _extract_note_onsets results.
"""

import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

PDF_CACHE = Path(tempfile.gettempdir()) / 'enekeskonyv_pdf_cache'

sys.path.insert(0, str(Path(__file__).resolve().parent))
import import_reformatus_scores as m

WORD_RE = re.compile(
    r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="[\d.]+" yMax="[\d.]+">([^<]*)</word>'
)
LYRIC_WORD = re.compile(r"[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű0-9.!?,;:’'\-]")


def pdf_lyric_onsets(pdf_path: Path) -> list[list[float]]:
    """Group lyric words into rows and return syllable onset xMins per row."""
    with tempfile.TemporaryDirectory() as td:
        bbox = Path(td) / 'p.html'
        subprocess.run(
            ['pdftotext', '-f', '1', '-l', '1', '-bbox-layout',
             str(pdf_path), str(bbox)],
            check=True,
        )
        data = bbox.read_text()
    words = []
    for mm in WORD_RE.finditer(data):
        text = mm.group(3).strip()
        if not text or text in {'-', '–'}:
            continue
        if not LYRIC_WORD.search(text):
            continue
        words.append((float(mm.group(2)), float(mm.group(1)), text))
    rows: dict[int, list[tuple[float, str]]] = {}
    for y, x, t in words:
        for key in rows:
            if abs(key - y) <= 4:
                rows[key].append((x, t))
                break
        else:
            rows[y] = [(x, t)]
    onset_rows = []
    for y in sorted(rows):
        pts = sorted(rows[y])
        # lyric rows: >=3 words, mostly under a staff (x>40), skip headers
        # containing "szöveg:"/"dallam:" credit words at top of page
        joined = ' '.join(t for _, t in pts)
        if len(pts) < 3 or 'szöveg' in joined or 'dallam' in joined:
            continue
        if joined.isupper() and len(joined) < 20:
            continue  # footer like "ZSOLTÁROK"
        onset_rows.append([x for x, _ in pts])
    return onset_rows


def main() -> int:
    songs = []
    for arg in sys.argv[1:]:
        if '-' in arg:
            lo, hi = arg.split('-', 1)
            songs.extend(str(i) for i in range(int(lo), int(hi) + 1))
        else:
            songs.append(arg)
    if not songs:
        songs = ['4']
    total_ok = total_bad = 0
    for song_number in songs:
        svg_path = m.source_svg_path(song_number)
        if not svg_path.exists():
            print(f'{song_number}: no source svg')
            continue
        page_url = m.search_song_page(song_number)
        if page_url is None:
            print(f'{song_number}: no site page')
            continue
        links = m.get_pdf_links(page_url)
        if not links:
            print(f'{song_number}: no pdf links')
            continue
        svg_text = svg_path.read_text()
        score_block, footer_block = m.detect_svg_lyric_blocks(svg_text)
        if score_block is None or score_block.font_id == '*':
            # No lyric block, or the generic fallback that carries no glyph
            # shapes — the generator skips these pages; so does validation.
            print(f'{song_number}: no lyric block in svg')
            continue
        row_fonts = [
            r.font_id or score_block.font_id for r in score_block.rows
        ]
        shapes = {
            fid: m._extract_font_glyph_shapes(svg_text, fid)
            for fid in set(row_fonts)
        }
        detected = [
            m._extract_note_onsets(r, *shapes[fid])
            for r, fid in zip(score_block.rows, row_fonts)
        ]
        text_font_ids = set(row_fonts)
        if footer_block is not None:
            text_font_ids.update(
                r.font_id for r in footer_block.rows if r.font_id
            )
        clusters = m._staff_note_clusters(
            m._extract_notehead_positions(svg_text, text_font_ids)
        )
        candidates = [
            m._find_recovery_candidates(
                r,
                o,
                clusters,
                shapes[fid].hyphen_id,
                shapes[fid].space_id,
                shapes[fid].separator_ids,
            )
            for r, o, fid in zip(score_block.rows, detected, row_fonts)
        ]
        # Same-baseline fragment rows (one visual row split across font
        # subsets) are merged for emission, and printed-verse paragraphs
        # (no syllable hyphens) are trimmed — mirror both here so the
        # validation matches rendered positions.  A prose-only page has
        # no aligned lyric rows at all.
        row_groups = m._group_rows_by_baseline(score_block.rows)
        hyphenated = [
            m._group_has_hyphen(g, score_block.rows, score_block.font_id, shapes)
            for g in row_groups
        ]
        staff_bands = m._staff_clusters(svg_text)
        prose_page = not staff_bands or (
            not any(hyphenated)
            and not any(
                bottom < r.y <= bottom + 45.0
                for r in score_block.rows
                for _top, bottom in staff_bands
            )
        )
        if prose_page:
            print(f'{song_number}: PROSE (no lyric rows)')
            continue
        keep = m._lyric_group_mask(
            row_groups, score_block.rows, score_block.font_id, shapes
        )
        row_groups = [g for g, k in zip(row_groups, keep) if k]
        detected = [
            sorted({x for i in g for x in detected[i]})
            for g in row_groups
        ]
        candidates = [
            sorted({c for i in g for c in candidates[i]})
            for g in row_groups
        ]
        best = None
        for link_idx, link in enumerate(links[:2]):
            try:
                PDF_CACHE.mkdir(exist_ok=True)
                cached = PDF_CACHE / f'{song_number}_{link_idx}.pdf'
                if not cached.exists():
                    with urllib.request.urlopen(link, timeout=30) as r:
                        cached.write_bytes(r.read())
                truth = pdf_lyric_onsets(cached)
            except Exception as exc:
                print(f'{song_number}: pdf fetch failed {exc}')
                continue
            # Align SVG rows to PDF rows by first-onset x (the SVG may be a
            # cropped prefix of the PDF page).
            aligned = []
            j = 0
            for d in detected:
                found = None
                if d:
                    while j < len(truth):
                        if truth[j] and abs(truth[j][0] - d[0]) <= 3.0:
                            found = truth[j]
                            j += 1
                            break
                        j += 1
                aligned.append(found)
            # The DP may use recovery candidates on top of detected onsets,
            # so the true count must fall inside [detected, detected+cands].
            score = sum(
                1
                for t, d, c in zip(aligned, detected, candidates)
                if t is not None and len(d) <= len(t) <= len(d) + len(c)
            )
            if best is None or score > best[0]:
                best = (score, aligned, link)
            if best is not None and score == len(detected):
                break
        if best is None:
            print(f'{song_number}: no pdf matched row count {len(detected)}')
            continue
        score, truth, link = best
        row_reports = []
        for i, (t, d) in enumerate(zip(truth, detected)):
            cands = candidates[i]
            if t is None:
                row_reports.append(f'    row {i}: no pdf row match')
                continue
            if not (len(d) <= len(t) <= len(d) + len(cands)):
                row_reports.append(
                    f'    row {i}: detected {len(d)}+{len(cands)} vs pdf {len(t)}'
                )
                continue
            unmatched = sum(
                1 for a in d if not any(abs(a - b) <= 2.0 for b in t)
            )
            if unmatched:
                row_reports.append(
                    f'    row {i}: {unmatched} detected onset(s) off pdf'
                )
        status = 'OK' if score == len(detected) and not row_reports else 'DIFF'
        print(f'{song_number}: {status} ({score}/{len(detected)} rows)')
        for r in row_reports:
            print(r)
        if status == 'OK':
            total_ok += 1
        else:
            total_bad += 1
    print(f'== {total_ok} ok, {total_bad} diff')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
