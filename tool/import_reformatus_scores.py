#!/usr/bin/env python3

import argparse
import difflib
import html
import json
import re
import statistics
import sys
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
import unicodedata
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field, replace
from functools import lru_cache
from pathlib import Path
from typing import NamedTuple

import pyphen
from PIL import Image
from PIL import ImageFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

_HYPHENATOR = pyphen.Pyphen(lang='hu_HU')

def _load_hyphen_dict() -> dict[str, list[str]]:
    """Load the custom Hungarian hyphenation dictionary extracted from LilyPond sources.

    The canonical copy is vendored at ``tool/hyphen-dict.json`` so output is
    identical on any machine; the extractor's sibling-repo output is only a
    developer fallback.
    """
    dict_path = Path(__file__).resolve().with_name('hyphen-dict.json')
    if not dict_path.exists():
        dict_path = (
            Path(__file__).resolve().parents[1]
            / '..'
            / 'convert-scripts'
            / 'hyphen-extractor'
            / 'hyphen_extractor'
            / 'out.json'
        )
    if not dict_path.exists():
        return {}
    content = dict_path.read_text(errors='replace')
    result: dict[str, list[str]] = {}
    for m in re.finditer(r'"([^"]+)"\s*:\s*"([^"]+)"', content):
        word = m.group(1)
        syllables = m.group(2).split('- ')
        result[word.lower()] = syllables
    result.update(_HYPHEN_OVERRIDES)
    return result

# Corrected entries: the extractor merged a lone adjacent vowel into a
# neighbouring syllable for one engraved occurrence, which then poisoned every
# use of the bare word. Each syllable must contain exactly one vowel.
_HYPHEN_OVERRIDES: dict[str, list[str]] = {
    'izráel': ['Iz', 'rá', 'el'],
    'papjai': ['pap', 'ja', 'i'],
    'eifordítád': ['e', 'i', 'for', 'dí', 'tád'],
    'elői': ['e', 'lő', 'i'],
    'álnokúi': ['ál', 'no', 'kú', 'i'],
    'lopótói': ['lo', 'pó', 'tó', 'i'],
    'méltatianságomban': ['mél', 'ta', 'ti', 'an', 'sá', 'gom', 'ban'],
    'idéztetei': ['i', 'déz', 'te', 'te', 'i'],
    'áinokságinkért': ['á', 'i', 'nok', 'sá', 'gin', 'kért'],
    'imádkozni': ['i', 'mád', 'koz', 'ni'],
    'fáradságinktói': ['fá', 'rad', 'sá', 'gink', 'tó', 'i'],
}

_HYPHEN_DICT: dict[str, list[str]] = _load_hyphen_dict()

BASE_URL = 'https://enekeskonyv.reformatus.hu'
SEARCH_URL = f'{BASE_URL}/digitalis-reformatus-enekeskonyv/enekek/'
SONGBOOK_PATH = Path(__file__).resolve().parents[1] / 'assets' / 'enekeskonyv.json'
MISSING_NOTES_PATH = (
    Path(__file__).resolve().parents[1] / 'docs' / 'erdelyi-missing-notes.txt'
)
SCORES_DIR = Path(__file__).resolve().parents[1] / 'assets' / 'referdelyi'
SHARED_SCORE_ALIASES = {
    '219': '407',
    '270': '89',
    '271': '152',
    '272': '337',
    '274': '135',
    '275': '65',
    '427': '407',
}

_SVG_NS = 'http://www.w3.org/2000/svg'
SVG_NAMESPACE = {'svg': _SVG_NS}
XLINK_HREF = '{http://www.w3.org/1999/xlink}href'
_USE_TAG = f'{{{_SVG_NS}}}use'
_PATH_TAG = f'{{{_SVG_NS}}}path'
_G_TAG = f'{{{_SVG_NS}}}g'
_DEFS_TAG = f'{{{_SVG_NS}}}defs'
_CLIP_PATH_TAG = f'{{{_SVG_NS}}}clipPath'
_RECT_TAG = f'{{{_SVG_NS}}}rect'
LYRIC_FONT_PATH = 'LiberationSerif-Regular.ttf'
LYRIC_FONT_SIZE = 100

ET.register_namespace('', _SVG_NS)
ET.register_namespace('xlink', 'http://www.w3.org/1999/xlink')


@dataclass(frozen=True)
class SvgLyricRow:
    y: float
    x_min: float
    x_max: float
    glyph_count: int
    glyph_xs: tuple[float, ...] = field(default_factory=tuple)
    glyph_ids: tuple[int, ...] = field(default_factory=tuple)
    # Set when a row was merged into a block from a different font subset
    # than the block's own (LilyPond occasionally sets e.g. the first
    # numbered lyric row in a separate subset).  None = block's font_id.
    font_id: str | None = None


@dataclass(frozen=True)
class SvgLyricBlock:
    font_id: str
    rows: list[SvgLyricRow]


class FontShapes(NamedTuple):
    """Glyph-shape data for one embedded font subset."""

    hyphen_id: int | None
    space_id: int | None
    ink_bounds: dict[int, tuple[float, float, float, float]]
    separator_ids: set[int]


def fetch_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={
            'User-Agent': (
                'Mozilla/5.0 (X11; Linux x86_64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/124.0.0.0 Safari/537.36'
            ),
        },
    )
    last_error = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read().decode('utf-8', 'ignore')
        except Exception as exc:  # pragma: no cover - network dependent
            last_error = exc
            if attempt == 2:
                raise
            time.sleep(attempt + 1)
    raise last_error  # pragma: no cover


def load_songbook() -> dict:
    return json.loads(SONGBOOK_PATH.read_text())


def write_songbook(songbook: dict) -> None:
    SONGBOOK_PATH.write_text(
        json.dumps(songbook, ensure_ascii=False, separators=(',', ':')),
    )


def parse_missing_song_numbers() -> list[str]:
    song_numbers = []
    for line in MISSING_NOTES_PATH.read_text().splitlines():
        if not line.strip():
            continue
        number, _title = line.split('\t', 1)
        song_numbers.append(number)
    return song_numbers


def song_numbers_for_import(
    songbook: dict,
    songs: list[str] | None,
    *,
    refresh_existing_scored: bool = False,
) -> list[str]:
    if songs:
        return songs
    if refresh_existing_scored:
        return [
            song_number
            for song_number, song in songbook['erdelyi'].items()
            if song.get('hasScore') is True
        ]
    return parse_missing_song_numbers()


def search_song_page(song_number: str) -> str | None:
    url = f'{SEARCH_URL}?{urllib.parse.urlencode({"szam": song_number})}'
    html_text = fetch_text(url)
    rows = extract_search_rows(html_text)
    for number, href, _title in rows:
        if number == song_number:
            return urllib.parse.urljoin(BASE_URL, href)
    return None


def extract_search_rows(html_text: str) -> list[tuple[str, str, str]]:
    return re.findall(
        r'<td>(\d+)</td>\s*<td>.*?<a href="(/digitalis-reformatus-enekeskonyv/enek/\d+/)">([^<]+)</a>',
        html_text,
        re.S,
    )


def normalize_title(text: str) -> str:
    text = unicodedata.normalize('NFKD', text)
    text = ''.join(char for char in text if not unicodedata.combining(char))
    text = text.lower()
    text = re.sub(r'[^a-z0-9 ]+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def title_queries(song_title: str) -> list[str]:
    parts = [song_title]
    first_clause = re.split(r'[!,:;()]', song_title)[0].strip()
    if first_clause and first_clause not in parts:
        parts.append(first_clause)
    words = song_title.split()
    if len(words) >= 4:
        parts.append(' '.join(words[:4]))
    return [part for part in parts if part]


def pick_best_search_match(
    song_number: str,
    song_title: str,
    candidates: list[tuple[str, str, str]],
) -> tuple[str, str, str] | None:
    normalized_title = normalize_title(song_title)
    title_tokens = set(normalized_title.split())
    best_match = None
    best_score = 0.0
    for candidate in candidates:
        candidate_number, _href, candidate_title = candidate
        candidate_normalized = normalize_title(candidate_title)
        candidate_tokens = set(candidate_normalized.split())
        score = difflib.SequenceMatcher(
            a=normalized_title,
            b=candidate_normalized,
        ).ratio()
        if title_tokens and candidate_tokens:
            shared_tokens = len(title_tokens & candidate_tokens)
            query_overlap = shared_tokens / len(title_tokens)
            candidate_overlap = shared_tokens / len(candidate_tokens)
            score = max(score, (query_overlap * 0.9) + (candidate_overlap * 0.1))
        if candidate_number == song_number:
            score += 0.2
        if (
            candidate_normalized.startswith(normalized_title)
            or normalized_title.startswith(candidate_normalized)
        ):
            score += 0.1
        if (
            candidate_normalized in normalized_title
            or normalized_title in candidate_normalized
        ):
            score += 0.15
        if score > best_score:
            best_score = score
            best_match = candidate
    if best_score < 0.72:
        return None
    return best_match


def _extract_svg_font_id(use_element: ET.Element) -> str | None:
    """Return the font subset id of a glyph use, e.g. '10' or 'p0-10'.

    Repaired multi-piece sources prefix each piece's ids ('p0-glyph-10-3')
    so subsets from different PDFs stay distinct; the prefix is kept in the
    font id so per-piece lyric blocks remain separate.
    """
    href = use_element.get(XLINK_HREF) or use_element.get('href')
    if href is None:
        return None
    match = re.fullmatch(r'#(p\d+-)?glyph-(\d+)-\d+', href)
    if match is None:
        return None
    return f'{match.group(1) or ""}{match.group(2)}'


def _extract_svg_glyph_index(use_element: ET.Element) -> int | None:
    href = use_element.get(XLINK_HREF) or use_element.get('href')
    if href is None:
        return None
    match = re.fullmatch(r'#(?:p\d+-)?glyph-\d+-(\d+)', href)
    if match is None:
        return None
    return int(match.group(1))


def _glyph_def_prefix(font_id: str) -> str:
    """Def id prefix for a font subset ('p0-10' -> 'p0-glyph-10-')."""
    piece = re.fullmatch(r'(p\d+)-(\d+)', font_id)
    if piece:
        return f'{piece.group(1)}-glyph-{piece.group(2)}-'
    return f'glyph-{font_id}-'


def _font_id_from_def(gid: str) -> str | None:
    """Inverse of glyph def ids ('p0-glyph-10-3' -> 'p0-10')."""
    match = re.fullmatch(r'(p\d+-)?glyph-(\d+)-\d+', gid)
    if match is None:
        return None
    return f'{match.group(1) or ""}{match.group(2)}'


def detect_svg_lyric_blocks(svg_text: str) -> tuple[SvgLyricBlock | None, SvgLyricBlock | None]:
    root = ET.fromstring(svg_text)
    font_rows: dict[str, dict[float, list[tuple[float, int]]]] = {}
    generic_rows: dict[float, list[float]] = {}

    for use_element in root.findall('.//svg:use', SVG_NAMESPACE):
        font_id = _extract_svg_font_id(use_element)
        x = use_element.get('x')
        y = use_element.get('y')
        if x is None or y is None:
            continue
        y_value = round(float(y), 3)
        x_value = float(x)
        generic_rows.setdefault(y_value, []).append(x_value)
        if font_id is None:
            continue
        glyph_idx = _extract_svg_glyph_index(use_element)
        if glyph_idx is None:
            continue
        font_rows.setdefault(font_id, {}).setdefault(y_value, []).append((x_value, glyph_idx))

    def _make_row(y_value: float, pts: list[tuple[float, int]]) -> SvgLyricRow:
        pts_sorted = sorted(pts, key=lambda p: p[0])
        xs = [p[0] for p in pts_sorted]
        ids = [p[1] for p in pts_sorted]
        return SvgLyricRow(
            y=y_value,
            x_min=xs[0],
            x_max=xs[-1],
            glyph_count=len(xs),
            glyph_xs=tuple(xs),
            glyph_ids=tuple(ids),
        )

    def _cluster_y(row_positions: dict[float, list]) -> list[tuple[float, list]]:
        """Merge y-buckets that are less than ~1 unit apart.

        LilyPond occasionally sets a short lyric fragment (e.g. a single
        syllable) on a baseline offset by a fraction of a unit from the rest
        of the row.  Keying rows by the exact y value would split such
        fragments into orphan rows that the prominence filter then drops.
        """
        clusters: list[list] = []
        for y_value in sorted(row_positions):
            pts = row_positions[y_value]
            if clusters and y_value - clusters[-1][0] <= 1.0:
                clusters[-1][1].extend(pts)
            else:
                clusters.append([y_value, list(pts)])
        return [(y_value, pts) for y_value, pts in clusters]

    blocks = []
    for font_id, row_positions in font_rows.items():
        rows = [_make_row(y_value, pts) for y_value, pts in _cluster_y(row_positions)]
        rows.sort(key=lambda row: row.y)
        # Header zone (title ~33.8, author ~41.5): never lyrics.  Dropping
        # these rows first keeps header fonts from distorting block gaps.
        rows = [row for row in rows if row.y >= 48.0]
        if len(rows) < 2:
            continue
        peak_count = max(row.glyph_count for row in rows)
        # A short but legitimate lyric row (e.g. a trailing "a-men.") can be
        # less than half the peak; keep anything at least ~30% of it.
        prominence_threshold = max(8, int(peak_count * 0.30))
        prominent_rows = [
            row for row in rows if row.glyph_count >= prominence_threshold
        ]
        if len(prominent_rows) < 2:
            continue
        if sum(row.glyph_count for row in prominent_rows) < 6:
            continue
        blocks.append(SvgLyricBlock(font_id=font_id, rows=prominent_rows))

    if not blocks:
        rows = [
            SvgLyricRow(
                y=y_value,
                x_min=min(xs),
                x_max=max(xs),
                glyph_count=len(xs),
            )
            for y_value, xs in _cluster_y(generic_rows)
        ]
        rows.sort(key=lambda row: row.y)
        if not rows:
            return None, None
        peak_count = max(row.glyph_count for row in rows)
        prominence_threshold = max(3, int(peak_count * 0.65))
        prominent_rows = [
            row for row in rows if row.glyph_count >= prominence_threshold
        ]
        if len(prominent_rows) < 2:
            return None, None
        return SvgLyricBlock(font_id='*', rows=prominent_rows), None

    def _is_prose_block(block: SvgLyricBlock) -> bool:
        """Printed verse paragraphs have uniform ~12-unit line spacing.

        Lyric rows always include at least one large staff-system gap
        (~40+ units), so a block whose gaps are all small is continuous
        prose (a second-page verse paragraph), not a lyric block.
        """
        rows = block.rows
        if len(rows) < 3:
            return False
        return all(
            rows[i + 1].y - rows[i].y < 20.0 for i in range(len(rows) - 1)
        )

    # Rows above the topmost staff line are page headers (psalm lists,
    # mottos, title continuations) — lyrics always sit below a staff.
    # Without this an early header block can win score_block election
    # while the real lyric block, starting past the eligibility window,
    # becomes "footer" and gets stripped (e.g. song 461's psalm list).
    # A degenerate detection must never empty every block, so fall back
    # to the unfiltered set rather than losing a song's lyrics.
    staff_top = _topmost_staff_line_y(svg_text)
    if staff_top is not None:
        trimmed = [
            replace(block, rows=[r for r in block.rows if r.y > staff_top])
            for block in blocks
        ]
        trimmed = [b for b in trimmed if len(b.rows) >= 2]
        if trimmed:
            blocks = trimmed

    # The score lyrics are the non-prose block with the most rows (LilyPond
    # splits fonts into arbitrary subsets, so position/font order is
    # unreliable).  Candidates must start within ~60 units of the earliest
    # block — page-2 content below the viewBox can also look lyric-shaped.
    lyric_blocks = [b for b in blocks if not _is_prose_block(b)] or blocks
    min_first_y = min(b.rows[0].y for b in lyric_blocks)
    eligible = [b for b in lyric_blocks if b.rows[0].y <= min_first_y + 60.0]
    score_block = max(
        eligible,
        key=lambda b: (len(b.rows), -b.rows[0].y),
    )

    # Merge rows from other non-prose fonts that fall inside the score
    # block's y-span, or just above its first row: the numbered first lyric
    # row occasionally lives in a different font subset (e.g. song 18).
    # Rows below the last score row are footnotes/page-2 content — never
    # lyrics.  The 48-unit floor keeps page header rows (title ~33.8,
    # author ~41.5) out even when a block starts unusually low.
    first_y = score_block.rows[0].y
    last_y = score_block.rows[-1].y
    merge_lo = max(48.0, first_y - 60.0)
    # Continuation pieces of repaired multi-page sources ('p1-','p2-'... font
    # prefixes) are always hymn content — merge them even below last_y;
    # ordinary same-piece rows below the score stay footnotes.
    score_piece = re.match(r'p\d+-', score_block.font_id or '')
    extra_rows = [
        replace(row, font_id=block.font_id)
        for block in lyric_blocks
        if block is not score_block
        for row in block.rows
        if merge_lo <= row.y <= last_y
        or (
            score_piece is not None
            and re.match(r'p\d+-', block.font_id or '') is not None
            and re.match(r'p\d+-', block.font_id).group(0)
            != score_piece.group(0)
        )
    ]
    if extra_rows:
        score_block = SvgLyricBlock(
            font_id=score_block.font_id,
            rows=sorted(score_block.rows + extra_rows, key=lambda r: r.y),
        )

    # Everything below the score (footnote, page-2 paragraphs) is stripped
    # from the output so it cannot overprint generated overflow lines.
    # font_id '*' = rows carry their own font; removal matches any font.
    footer_rows = [
        replace(row, font_id=block.font_id)
        for block in blocks
        for row in block.rows
        if row.y > last_y
    ]
    footer_block = (
        SvgLyricBlock(font_id='*', rows=footer_rows) if footer_rows else None
    )
    return score_block, footer_block


def _normalize_verse_text(verse_text: str) -> str:
    return re.sub(r'\s+', ' ', verse_text.replace('\n', ' ')).strip()


def _measure_text_factory(measure_text):
    if measure_text is not None:
        return measure_text
    font = ImageFont.truetype(LYRIC_FONT_PATH, LYRIC_FONT_SIZE)
    return lambda text: font.getlength(text)


def split_verse_text_to_rows(
    verse_text: str,
    target_widths: list[float],
    *,
    measure_text=None,
) -> list[str]:
    clean_text = _normalize_verse_text(verse_text)
    if not target_widths:
        return [clean_text] if clean_text else []
    if len(target_widths) == 1:
        return [clean_text]

    words = clean_text.split()
    if len(words) <= len(target_widths):
        rows = words + [''] * (len(target_widths) - len(words))
        return rows

    measure = _measure_text_factory(measure_text)

    @lru_cache(maxsize=None)
    def line_width(start: int, end: int) -> float:
        return measure(' '.join(words[start:end]))

    @lru_cache(maxsize=None)
    def solve(start: int, row_index: int) -> tuple[float, tuple[str, ...]]:
        rows_left = len(target_widths) - row_index
        words_left = len(words) - start
        if rows_left == 1:
            line = ' '.join(words[start:])
            width = line_width(start, len(words))
            delta = width - target_widths[row_index]
            penalty = delta * delta * (3 if delta > 0 else 1)
            return penalty, (line,)

        best_cost = float('inf')
        best_rows: tuple[str, ...] | None = None
        min_end = start + 1
        max_end = len(words) - (rows_left - 1)
        for end in range(min_end, max_end + 1):
            line = ' '.join(words[start:end])
            width = line_width(start, end)
            target = target_widths[row_index]
            delta = width - target
            penalty = delta * delta
            if delta > 0:
                penalty *= 3
            # Prefer row boundaries after punctuation (e.g. the "?" before
            # "És" in the psalm) so a new phrase starts on the next row.
            boundary_word = words[end - 1] if end <= len(words) else ''
            if boundary_word and boundary_word[-1] not in '.,;:!?':
                penalty += 1.0
            next_cost, next_rows = solve(end, row_index + 1)
            total_cost = penalty + next_cost
            if total_cost < best_cost:
                best_cost = total_cost
                best_rows = (line, *next_rows)
        assert best_rows is not None
        return best_cost, best_rows

    return list(solve(0, 0)[1])


def split_verse_text_by_note_counts(
    verse_text: str,
    note_counts: list[int],
    max_counts: list[int] | None = None,
) -> tuple[list[str], str]:
    """Split verse text into rows targeting a specific syllable count per row.

    Uses the same DP approach as split_verse_text_to_rows but optimizes for
    syllable count matching note_counts (extracted from the verse-1 SVG).
    Row 0's note count is reduced by 1 to account for the verse prefix
    (e.g. "1. ") which occupies onset[0] as its own element.

    ``max_counts`` optionally widens each row's target into the range
    ``[note_counts[i], max_counts[i]]``: counts inside the range cost
    nothing.  The extra headroom represents kern-tight syllable boundaries
    that onset detection may have missed; the DP uses them only when the
    verse text actually demands more slots.

    Returns ``(rows, leftover)``: ``leftover`` holds the tail of the verse
    that does not fit the score's note slots (in the printed book it would
    continue under a staff on the next page).
    """
    clean_text = _normalize_verse_text(verse_text)
    if not note_counts:
        return ([clean_text] if clean_text else []), ''
    if len(note_counts) == 1:
        return [clean_text], ''

    # The verse prefix ("1. ") occupies one note slot in row 0.
    # Strip the prefix from the clean text so we split just the lyric words.
    prefix = ''
    prefix_match = re.match(r'^(\d+\.\s*)', clean_text)
    if prefix_match:
        prefix = prefix_match.group(1)
        clean_text = clean_text[len(prefix):]

    # Adjust row 0 target: one onset is reserved for the prefix.
    adjusted_counts = list(note_counts)
    if prefix and adjusted_counts[0] > 1:
        adjusted_counts[0] -= 1
    adjusted_max = list(max_counts) if max_counts is not None else list(note_counts)
    if prefix and adjusted_max[0] > 1:
        adjusted_max[0] -= 1
    adjusted_max = [max(lo, hi) for lo, hi in zip(adjusted_counts, adjusted_max)]

    words = tuple(clean_text.split())
    if not words:
        return [prefix] + [''] * (len(note_counts) - 1), ''

    if len(words) <= len(adjusted_counts):
        first_row = prefix + words[0] if words else prefix
        rows = [first_row] + list(words[1:]) + [''] * (len(adjusted_counts) - len(words))
        return rows, ''

    @lru_cache(maxsize=None)
    def word_syllable_count(word: str) -> int:
        return max(1, len(_syllabify_word(word)))

    @lru_cache(maxsize=None)
    def row_syllable_count(start: int, end: int) -> int:
        return sum(word_syllable_count(words[i]) for i in range(start, end))

    @lru_cache(maxsize=None)
    def solve(
        start: int, row_index: int
    ) -> tuple[float, tuple[str, ...], tuple[str, ...]]:
        rows_left = len(adjusted_counts) - row_index

        def count_penalty(count: int, lo: int, hi: int) -> float:
            if count < lo:
                return float((lo - count) ** 2)
            if count > hi:
                return float((count - hi) ** 2) * 3.0
            return 0.0

        if rows_left == 1:
            # Last row: take only the words that fit its note slots; the rest
            # is rendered as overflow text below the staff.  Leftover is not
            # free — each leftover syllable costs more than over-filling by
            # one, so small onset-detection deficits (tight-kerned syllable
            # boundaries produce no detectable gap) are absorbed into the
            # row instead of dumping a stray fragment below the staff.
            lo = adjusted_counts[row_index]
            hi = adjusted_max[row_index]
            best_cost = float('inf')
            best_end = len(words)
            for end in range(start + 1, len(words) + 1):
                count = row_syllable_count(start, end)
                penalty = count_penalty(count, lo, hi)
                penalty += 4.0 * row_syllable_count(end, len(words))
                if penalty < best_cost:
                    best_cost = penalty
                    best_end = end
            line = ' '.join(words[start:best_end])
            return best_cost, (line,), words[best_end:]

        best_cost = float('inf')
        best_rows: tuple[str, ...] | None = None
        best_leftover: tuple[str, ...] = ()
        min_end = start + 1
        max_end = len(words) - (rows_left - 1)
        for end in range(min_end, max_end + 1):
            line = ' '.join(words[start:end])
            count = row_syllable_count(start, end)
            penalty = count_penalty(
                count, adjusted_counts[row_index], adjusted_max[row_index]
            )
            # Prefer row boundaries after punctuation so new phrases start
            # cleanly on the next row (e.g. "...tisztességemben?" / "És ...").
            boundary_word = words[end - 1] if end <= len(words) else ''
            if boundary_word and boundary_word[-1] not in '.,;:!?':
                penalty += 1.0
            next_cost, next_rows, next_leftover = solve(end, row_index + 1)
            total_cost = penalty + next_cost
            if total_cost < best_cost:
                best_cost = total_cost
                best_rows = (line, *next_rows)
                best_leftover = next_leftover
        assert best_rows is not None
        return best_cost, best_rows, best_leftover

    _cost, rows, leftover = solve(0, 0)
    result = list(rows)
    # Re-attach prefix to the first row
    result[0] = prefix + result[0]
    return result, ' '.join(leftover)


def source_svg_path(song_number: str) -> Path:
    return SCORES_DIR / f'referdelyi-{song_number.zfill(3)}-001.svg'


def generated_svg_path(song_number: str, verse_index: int) -> Path:
    return SCORES_DIR / f'referdelyi-{song_number.zfill(3)}-v{verse_index + 1:03}.svg'


def ref48_svg_path(song_number: str) -> Path:
    return (
        Path(__file__).resolve().parents[1]
        / 'assets'
        / 'ref48'
        / f'ref48-{song_number.zfill(3)}-001.svg'
    )


def _row_target_width(row: SvgLyricRow) -> float:
    if row.glyph_count <= 1:
        return max(1.0, row.x_max - row.x_min)
    advance = (row.x_max - row.x_min) / max(1, row.glyph_count - 1)
    return max(1.0, (row.x_max - row.x_min) + advance)


def _remove_svg_children(root: ET.Element, predicate) -> None:
    """Remove every descendant element for which ``predicate`` is true."""
    for parent in root.iter():
        for child in list(parent):
            if predicate(child):
                parent.remove(child)


def _use_row_y(child: ET.Element) -> float | None:
    """Rounded baseline y of a <use> element, or None when it has none."""
    if child.tag != _USE_TAG:
        return None
    y = child.get('y')
    return round(float(y), 3) if y is not None else None


def _remove_header_text(
    root: ET.Element,
    score_block: SvgLyricBlock,
) -> None:
    """Strip title/author/credit glyph rows above the first lyric row.

    These rows are page-level headers baked into the original LilyPond SVG
    (title at y~33.8, author at y~41.5, credit at y~52.6).  They are redundant
    with the app's own header and often shared across many songs from the same
    PDF page.  We identify them by high glyph density (>=8 glyphs and >15
    glyphs per 100px x-range) while preserving sparse musical notation rows
    (clefs, key/time signatures) which have 1-4 glyphs.
    """
    if not score_block.rows:
        return
    min_lyric_y = min(round(r.y, 3) for r in score_block.rows)

    # Group uses by y to find header text rows.
    rows_by_y: dict[float, list[float]] = {}
    for u in root.iter(_USE_TAG):
        y = u.get('y')
        if y is None:
            continue
        yv = round(float(y), 3)
        if yv >= min_lyric_y:
            continue
        rows_by_y.setdefault(yv, []).append(float(u.get('x', 0)))

    header_ys: set[float] = set()
    for yv, xs in rows_by_y.items():
        count = len(xs)
        x_range = max(xs) - min(xs) if len(xs) > 1 else 0.0
        density = count / max(x_range, 1.0) * 100.0
        if count >= 8 and density > 15.0:
            header_ys.add(yv)

    if not header_ys:
        return

    _remove_svg_children(
        root,
        lambda child: _use_row_y(child) in header_ys,
    )


def _remove_lyric_uses(
    root: ET.Element,
    score_block: SvgLyricBlock,
    footer_block: SvgLyricBlock | None,
) -> None:
    # Detection clusters y-buckets up to ~1 unit apart into one row keyed
    # by the first bucket's y, so a member use can sit slightly off the
    # row's key y; and one baseline can be shared by several font subsets
    # (or a same-height straggler like a page number).  Remove every use
    # within the cluster band of any detected row, regardless of font.
    row_ys = [
        row.y
        for block in (score_block, footer_block)
        if block is not None
        for row in block.rows
    ]

    def _is_lyric_use(child: ET.Element) -> bool:
        y_value = _use_row_y(child)
        return y_value is not None and any(
            abs(y_value - row_y) <= 1.0 for row_y in row_ys
        )

    _remove_svg_children(root, _is_lyric_use)


_PATH_ARG_COUNTS = {
    'M': 2, 'L': 2, 'C': 6, 'S': 4, 'Q': 4, 'T': 2, 'A': 7, 'V': 1, 'H': 1, 'Z': 0,
}
_PATH_TOKEN_RE = re.compile(
    r'[MmLlCcSsQqTtAaVvHhZz]|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?'
)


def _glyph_ink_bounds(d: str) -> tuple[float, float, float, float] | None:
    """Ink extent (min_x, max_x, min_y, max_y) of a glyph path.

    Parses the SVG path ``d`` attribute tracking absolute vs relative
    commands so coordinates are interpreted correctly.  Control points are
    included, so the bounds may slightly overestimate the true ink — which
    is the safe direction for onset-gap estimation.
    """
    tokens = _PATH_TOKEN_RE.findall(d)
    xs: list[float] = []
    ys: list[float] = []
    cur_x = 0.0
    cur_y = 0.0
    i = 0
    cmd: str | None = None
    while i < len(tokens):
        token = tokens[i]
        if token.isalpha():
            cmd = token
            i += 1
            if cmd.upper() == 'Z':
                cmd = None
            continue
        if cmd is None:
            i += 1
            continue
        c = cmd.upper()
        rel = cmd.islower()
        n_args = _PATH_ARG_COUNTS[c]
        group = tokens[i:i + n_args]
        if len(group) < n_args or any(g.isalpha() for g in group):
            i += 1
            continue
        vals = [float(v) for v in group]
        if c == 'H':
            pts = [(vals[0], cur_y)]
        elif c == 'V':
            pts = [(cur_x, vals[0])]
        elif c == 'A':
            pts = [(vals[5], vals[6])]
        else:
            pts = list(zip(vals[::2], vals[1::2]))
        for px, py in pts:
            if rel:
                px += cur_x
                py += cur_y
            xs.append(px)
            ys.append(py)
        if pts:
            if rel:
                cur_x += pts[-1][0]
                cur_y += pts[-1][1]
            else:
                cur_x, cur_y = pts[-1]
        i += n_args
    if not xs:
        return None
    return min(xs), max(xs), min(ys), max(ys)


def _extract_font_glyph_shapes(svg_text: str, font_id: str) -> FontShapes:
    """Glyph-shape data for one embedded font subset, in a single SVG parse.

    Returns the font's hyphen and space glyph indices, per-glyph ink
    extents, and the set of separator-mark glyph indices — everything the
    onset extractor needs for this subset.  The generic fallback font '*'
    yields empty data.

    - space: glyph with no paths at all
    - hyphen: small flat dash floating just above the baseline
    - separator (e.g. "/" phrase breaths): a simple mark (few segments)
      spanning most of the line height — never a syllable itself
    """
    if font_id == '*':
        return FontShapes(None, None, {}, set())
    root = ET.fromstring(svg_text)
    prefix = _glyph_def_prefix(font_id)
    hyphen_id: int | None = None
    space_id: int | None = None
    ink_bounds: dict[int, tuple[float, float, float, float]] = {}
    separator_ids: set[int] = set()
    for g in root.findall('.//svg:g', SVG_NAMESPACE):
        gid = g.get('id', '')
        if not gid.startswith(prefix):
            continue
        try:
            idx = int(gid[len(prefix):])
        except ValueError:
            continue
        paths = g.findall(_PATH_TAG)
        if not paths:
            space_id = idx
            continue
        extents = [
            extent
            for p in paths
            if (extent := _glyph_ink_bounds(p.get('d', ''))) is not None
        ]
        extent = None
        if extents:
            extent = (
                min(e[0] for e in extents),
                max(e[1] for e in extents),
                min(e[2] for e in extents),
                max(e[3] for e in extents),
            )
            ink_bounds[idx] = extent
        segments = sum(
            len(re.findall(r'[A-Za-z]', p.get('d', ''))) for p in paths
        )
        if (
            extent is not None
            and segments <= 12
            and extent[3] - extent[2] >= 5.0
        ):
            separator_ids.add(idx)
        coords = re.findall(r'[-+]?\d*\.?\d+', paths[0].get('d', ''))
        if len(coords) < 4:
            continue
        nums = list(map(float, coords))
        xs = nums[::2]
        ys = nums[1::2]
        if (
            xs
            and ys
            and max(xs) - min(xs) < 4.5
            and max(ys) - min(ys) < 1.5
            and max(ys) < -1.0
        ):
            hyphen_id = idx
    return FontShapes(hyphen_id, space_id, ink_bounds, separator_ids)


def _group_rows_by_baseline(rows: list[SvgLyricRow]) -> list[list[int]]:
    """Group row indexes sharing one baseline (±0.5 units).

    LilyPond occasionally splits one visual lyric row across font subsets
    (e.g. song 350's first row lives in both font3 and font4).  Each
    fragment row must not receive its own verse line — syllables would
    overlap.  Groups preserve row order (rows are y-sorted).
    """
    groups: list[list[int]] = []
    for i, row in enumerate(rows):
        if groups and abs(row.y - rows[groups[-1][0]].y) < 0.5:
            groups[-1].append(i)
        else:
            groups.append([i])
    return groups


def _merge_row_group(rows: list[SvgLyricRow], idxs: list[int]) -> SvgLyricRow:
    """Collapse same-baseline fragment rows into one display row."""
    members = [rows[i] for i in idxs]
    return SvgLyricRow(
        y=members[0].y,
        x_min=min(r.x_min for r in members),
        x_max=max(r.x_max for r in members),
        glyph_count=sum(r.glyph_count for r in members),
    )


def _group_has_hyphen(
    group: list[int],
    rows: list[SvgLyricRow],
    block_font_id: str,
    shapes: dict[str, FontShapes],
) -> bool:
    """Whether any member row of a baseline group carries a hyphen glyph."""
    for i in group:
        row = rows[i]
        fid = row.font_id or block_font_id
        font_shapes = shapes.get(fid)
        if font_shapes is None:
            continue
        hyphen_id = font_shapes.hyphen_id
        if hyphen_id is not None and hyphen_id in row.glyph_ids:
            return True
    return False


_PATH_LINE_SEG_RE = re.compile(
    r'([-\d.]+)\s+([-\d.]+)\s+L\s+([-\d.]+)\s+([-\d.]+)'
)


def _parse_svg_transform(transform: str) -> tuple[float, ...]:
    """Parse an SVG transform list into a 2x3 matrix (a,b,c,d,e,f)."""
    mat = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    for m in re.finditer(r'(matrix|translate|scale)\(([^)]*)\)', transform):
        vals = [float(v) for v in re.split(r'[ ,]+', m.group(2).strip()) if v]
        if m.group(1) == 'matrix':
            local = tuple(vals[:6])
        elif m.group(1) == 'translate':
            local = (1.0, 0.0, 0.0, 1.0, vals[0], vals[1] if len(vals) > 1 else 0.0)
        else:
            local = (vals[0], 0.0, 0.0, vals[1] if len(vals) > 1 else vals[0], 0.0, 0.0)
        mat = _mat_mul(mat, local)
    return mat


def _mat_mul(m1: tuple[float, ...], m2: tuple[float, ...]) -> tuple[float, ...]:
    """Compose 2x3 matrices: result applies m2 first, then m1."""
    a1, b1, c1, d1, e1, f1 = m1
    a2, b2, c2, d2, e2, f2 = m2
    return (
        a1 * a2 + c1 * b2,
        b1 * a2 + d1 * b2,
        a1 * c2 + c1 * d2,
        b1 * c2 + d1 * d2,
        a1 * e2 + c1 * f2 + e1,
        b1 * e2 + d1 * f2 + f1,
    )


def _staff_line_ys(svg_text: str) -> list[float]:
    """Y positions of staff lines (long horizontal path segments).

    Path coordinates are local — the path element or an ancestor may
    carry a transform matrix (A4 sources wrap the page in a unit-scale
    flip).  Segments are measured in effective page space; anything
    under <defs> is glyph geometry, not page content.
    """
    root = ET.fromstring(svg_text)
    ys: list[float] = []

    def _walk(e: ET.Element, mat: tuple[float, ...]) -> None:
        if e.tag == f"{{{_SVG_NS}}}defs":
            return
        transform = e.get('transform')
        if transform:
            mat = _mat_mul(mat, _parse_svg_transform(transform))
        if e.tag == f"{{{_SVG_NS}}}path":
            d = e.get('d') or ''
            for seg in _PATH_LINE_SEG_RE.finditer(d):
                x1, y1, x2, y2 = (float(v) for v in seg.groups())
                px1 = mat[0] * x1 + mat[2] * y1 + mat[4]
                py1 = mat[1] * x1 + mat[3] * y1 + mat[5]
                px2 = mat[0] * x2 + mat[2] * y2 + mat[4]
                py2 = mat[1] * x2 + mat[3] * y2 + mat[5]
                if abs(px2 - px1) > 80.0 and abs(py2 - py1) < 0.5:
                    ys.append(py1)
        else:
            for child in e:
                _walk(child, mat)

    _walk(root, (1.0, 0.0, 0.0, 1.0, 0.0, 0.0))
    return sorted(ys)


def _staff_clusters(svg_text: str) -> list[tuple[float, float]]:
    """(top, bottom) y-bounds of each staff system on the page.

    A staff is a cluster of >=4 staff lines spread over >4 units (a
    system's ~5 lines span ~17 units).  Full-width page borders also
    appear as long horizontals but stack at a single y (spread ~0),
    so they never qualify.
    """
    clusters: list[list[float]] = []
    for y in _staff_line_ys(svg_text):
        if clusters and y - clusters[-1][-1] <= 12.0:
            clusters[-1].append(y)
        else:
            clusters.append([y])
    return [
        (c[0], c[-1])
        for c in clusters
        if len(c) >= 4 and c[-1] - c[0] > 4.0
    ]


def _topmost_staff_line_y(svg_text: str) -> float | None:
    """Y of the first staff's top line, or None for staff-less pages."""
    clusters = _staff_clusters(svg_text)
    return clusters[0][0] if clusters else None


def _lyric_group_mask(
    row_groups: list[list[int]],
    rows: list[SvgLyricRow],
    block_font_id: str,
    shapes: dict[str, FontShapes],
) -> list[bool]:
    """Mask of row groups that are real lyric slots, not printed prose.

    Multi-system sources print the remaining verses as plain paragraphs
    above the first system and below the last one; those paragraphs get
    detected as lyric rows (dense glyph lines) but contain few or no
    syllable hyphens.  Two shapes identify them:

    - a contiguous run of no-hyphen rows at the block's top (verses
      printed above the first system) or bottom (verses after the last);
    - a tightly-spaced paragraph: >=3 consecutive rows ~12 units apart
      where less than half carry a hyphen.  Interior runs must be
      checked too — a stray hyphen inside a prose paragraph (e.g.
      'Lelki-testi' in song 279) must not rescue it.

    An interior no-hyphen row that is not part of a paragraph is kept:
    it can be a legitimate lyric row whose hyphens live in a
    neighbouring font subset (e.g. song 381).  A source where *no*
    group is hyphenated is a prose-only chant (e.g. song 464) whose
    rows must all be kept.
    """

    n = len(row_groups)
    hyphenated = [
        _group_has_hyphen(group, rows, block_font_id, shapes)
        for group in row_groups
    ]
    keep = [True] * n

    # Paragraph runs: maximal runs of consecutive groups spaced at most
    # ~15 units apart.  A run of >=3 rows where less than half are
    # hyphenated is prose; drop its no-hyphen members outright and its
    # hyphenated members only when sandwiched inside the run (a prose
    # line containing a real hyphen, e.g. 'Lelki-testi' in song 279).
    # A hyphenated row *starting* such a run is protected: it is more
    # likely a real lyric row that a paragraph follows closely.
    i = 0
    while i < n:
        run = [i]
        while (
            i + 1 < n
            and rows[row_groups[i + 1][0]].y - rows[row_groups[i][0]].y
            <= 15.0
        ):
            i += 1
            run.append(i)
        if len(run) >= 3 and sum(hyphenated[g] for g in run) * 2 < len(run):
            for pos, g in enumerate(run):
                if not hyphenated[g] or pos > 0:
                    keep[g] = False
        i += 1

    # Leading/trailing runs of no-hyphen rows: verses printed above the
    # first system and after the last one (plus page furniture such as
    # the szöveg/dallam credit lines).
    first_lyric = 0
    while first_lyric < n and not hyphenated[first_lyric]:
        keep[first_lyric] = False
        first_lyric += 1
    last_lyric = n - 1
    while last_lyric >= first_lyric and not hyphenated[last_lyric]:
        keep[last_lyric] = False
        last_lyric -= 1
    if not any(keep):
        return [True] * n
    return keep


def _extract_note_onsets(
    row: SvgLyricRow,
    hyphen_id: int | None,
    space_id: int | None,
    ink_bounds: dict[int, tuple[float, float, float, float]] | None = None,
    separator_ids: set[int] | None = None,
) -> list[float]:
    """Extract per-note x positions from a lyric row's glyph sequence.

    An onset starts at:
    - glyph[0] always (verse prefix such as "1.")
    - glyph[i] when glyph[i-1] is a hyphen (continuation syllable)
    - glyph[i] when glyph[i-1] is a space (first real lyric character)
    - glyph[i] when the whitespace between glyph[i-1]'s right ink edge and
      glyph[i] is larger than the within-word spacing of this row, and
      glyph[i-1] is not a hyphen.

    The whitespace residual (next origin − previous ink right edge) separates
    word/syllable boundaries from within-word kerning far more reliably than
    the raw origin-to-origin gap: wide glyphs such as "m" produce large raw
    gaps even when typeset tight, while the residual stays small.  The
    threshold is anchored at the first empty interval above the dense
    within-word residual cluster; if none exists the row has no word gaps
    (single word / all hyphen-joined) and a conservative fallback is used.

    Separator marks (e.g. "/" phrase breaths) are space-isolated glyphs that
    carry no syllable — they are skipped, but the word after them still gets
    its onset via the space-follow rule.
    """
    xs = row.glyph_xs
    ids = row.glyph_ids
    if not xs:
        return []
    separator_ids = separator_ids or set()

    def _residual(i: int) -> float:
        prev_id = ids[i - 1]
        prev_ink_r = ink_bounds.get(prev_id, (0.0, 0.0, 0.0, 0.0))[1] if ink_bounds else 0.0
        return xs[i] - (xs[i - 1] + prev_ink_r)

    # Candidate residuals for word-boundary detection: positions that are not
    # already explained by an explicit hyphen/space follower.
    candidates = sorted(
        _residual(i)
        for i in range(1, len(xs))
        if ids[i - 1] != hyphen_id and ids[i - 1] != space_id
        and ids[i] != hyphen_id and ids[i] != space_id
    )
    # The intra-word residuals form a dense pack near zero; word-boundary
    # residuals float well above it.  Anchor the split at the pack top
    # (median + 1.0) and place the threshold midway to the first candidate
    # above it.  Scanning consecutive gaps is unreliable: kern outliers
    # inside the pack produce the first >1.0 interval long before the real
    # word-boundary cluster.
    median = candidates[len(candidates) // 2] if candidates else 0.0
    pack_top = median + 1.0
    upper = [c for c in candidates if c > pack_top]
    gap_threshold = (pack_top + upper[0]) / 2 if upper else pack_top + 1.0

    onsets: list[float] = [xs[0]]
    for i in range(1, len(xs)):
        # A hyphen or space glyph is never a syllable itself; the onset is the
        # glyph that follows it.
        if ids[i] == hyphen_id or ids[i] == space_id:
            continue
        # A space-isolated separator mark (e.g. "/") carries no syllable.
        if (
            ids[i] in separator_ids
            and ids[i - 1] == space_id
            and (i + 1 == len(xs) or ids[i + 1] == space_id)
        ):
            continue
        prev_id = ids[i - 1]
        if prev_id == hyphen_id:
            onsets.append(xs[i])
        elif prev_id == space_id:
            onsets.append(xs[i])
        elif _residual(i) > gap_threshold and prev_id != hyphen_id:
            onsets.append(xs[i])
    return onsets


def _extract_notehead_positions(
    svg_text: str, text_font_ids: set[str]
) -> list[tuple[float, float]]:
    """(x, y) positions of notehead-shaped glyphs outside the text fonts.

    LilyPond noteheads (filled quarters, open halves, whole notes) are
    near-oval glyphs roughly 3-7 units wide and 1.5-5 units tall.  Stems,
    flags, rests, clefs, augmentation dots and text glyphs fail the size
    or aspect test.
    """
    root = ET.fromstring(svg_text)
    notehead_glyphs: set[str] = set()
    for g in root.findall('.//svg:g', SVG_NAMESPACE):
        gid = g.get('id', '')
        font_id = _font_id_from_def(gid)
        if font_id is None or font_id in text_font_ids:
            continue
        extents = [
            extent
            for p in g.findall(_PATH_TAG)
            if (extent := _glyph_ink_bounds(p.get('d', ''))) is not None
        ]
        if not extents:
            continue
        width = max(e[1] for e in extents) - min(e[0] for e in extents)
        height = max(e[3] for e in extents) - min(e[2] for e in extents)
        if 2.8 <= width <= 7.5 and 1.5 <= height <= 5.0 and width >= 0.8 * height:
            notehead_glyphs.add(gid)

    positions: list[tuple[float, float]] = []
    for use_element in root.findall('.//svg:use', SVG_NAMESPACE):
        href = use_element.get(XLINK_HREF) or use_element.get('href') or ''
        if href.lstrip('#') not in notehead_glyphs:
            continue
        try:
            positions.append(
                (float(use_element.get('x', '')), float(use_element.get('y', '')))
            )
        except ValueError:
            continue
    return positions


def _staff_note_clusters(
    noteheads: list[tuple[float, float]],
) -> list[tuple[float, float, list[float]]]:
    """Group notehead (x, y) positions into staff systems by vertical
    proximity.  Returns (y_min, y_max, distinct_x_positions) per system,
    sorted top to bottom.  Multi-voice noteheads at the same beat collapse
    into one x position."""
    if not noteheads:
        return []
    pts = sorted(noteheads, key=lambda p: p[1])
    clusters: list[list[tuple[float, float]]] = [[pts[0]]]
    for p in pts[1:]:
        if p[1] - clusters[-1][-1][1] <= 18.0:
            clusters[-1].append(p)
        else:
            clusters.append([p])
    out: list[tuple[float, float, list[float]]] = []
    for cluster in clusters:
        distinct: list[float] = []
        for x in sorted(p[0] for p in cluster):
            if distinct and x - distinct[-1] <= 2.0:
                distinct[-1] = (distinct[-1] + x) / 2
            else:
                distinct.append(x)
        ys = [p[1] for p in cluster]
        out.append((min(ys), max(ys), distinct))
    return out


def _find_recovery_candidates(
    row: SvgLyricRow,
    onsets: list[float],
    staff_clusters: list[tuple[float, float, list[float]]],
    hyphen_id: int | None = None,
    space_id: int | None = None,
    separator_ids: set[int] | None = None,
) -> list[tuple[float, float]]:
    """Find positions where a kern-tight syllable boundary may hide.

    LilyPond occasionally typesets adjacent lyric syllables kern-tight
    (e.g. "mennye" for "men|nye"), so the residual-gap detector merges
    them into a single onset.  The melody still shows one notehead per
    sung syllable: a notehead with no matching onset but with lyric ink
    underneath marks a *possible* hidden boundary.

    Returns ``(x, distance)`` candidates sorted by x.  They are only
    *candidates*: melisma notes inside a held word look identical, so the
    verse-splitting DP decides per row how many are actually used.
    """
    if not staff_clusters or not onsets:
        return []
    # The row's staff is the nearest system ending above the lyric line.
    staff: list[float] = []
    for _y0, y1, xs in staff_clusters:
        if y1 <= row.y - 4.0 and row.y - y1 <= 45.0:
            staff = xs
    if not staff:
        return []

    # Estimated offset between a lyric onset and its notehead (lyrics sit
    # slightly left of the notehead they are sung to).
    offsets = []
    mapped_notes: list[float] = []
    for o in onsets:
        nearest = min(staff, key=lambda n: abs(n - o))
        if abs(nearest - o) <= 6.0:
            offsets.append(o - nearest)
            mapped_notes.append(nearest)
    shift = statistics.median(offsets) if offsets else -2.5

    skip_ids = {i for i in (hyphen_id, space_id) if i is not None} | (
        separator_ids or set()
    )
    taken = list(onsets)
    candidates_out: list[tuple[float, float]] = []
    for note_x in staff:
        # Only notes flanked by mapped onsets are candidates: notes beyond
        # the first/last mapped onset are melismas or held notes at phrase
        # ends, which legitimately carry no new syllable.
        if not (
            any(mn < note_x for mn in mapped_notes)
            and any(mn > note_x for mn in mapped_notes)
        ):
            continue
        target = note_x + shift
        if any(abs(o - target) <= 5.0 for o in taken):
            continue
        near = [
            x
            for x, g in zip(row.glyph_xs, row.glyph_ids)
            if g not in skip_ids
            and abs(x - target) <= 6.0
            and all(abs(x - o) > 1.0 for o in taken)
        ]
        if not near:
            continue
        candidate = min(near, key=lambda x: abs(x - target))
        # A hidden boundary's first glyph sits in the right half of the
        # flanking onset gap — the previous syllable's glyphs occupy the
        # left half under its own note.  Mid-word glyphs stretching under
        # a held note fall left of the midpoint and are rejected.
        prev = [o for o in onsets if o < candidate]
        nxt = [o for o in onsets if o > candidate]
        if not prev or not nxt:
            continue
        midpoint = (max(prev) + min(nxt)) / 2
        if candidate < midpoint - 2.5:
            continue
        candidates_out.append((candidate, abs(candidate - target)))
        taken.append(candidate)
    return sorted(candidates_out)


def _syllabify_word(word: str) -> list[str]:
    """Split a word into syllables using the custom dictionary, falling back to pyphen."""
    stripped = word.rstrip('.,;:!?')
    if not stripped:
        return [word] if word else []
    punctuation = word[len(stripped):]
    key = stripped.lower()
    if key in _HYPHEN_DICT:
        pattern = _HYPHEN_DICT[key]
        # Apply positional pattern to preserve original casing
        combined = ''.join(pattern)
        if len(combined) == len(stripped):
            pos = 0
            syllables = []
            for i, syl in enumerate(pattern):
                syllable = stripped[pos:pos + len(syl)]
                if i == len(pattern) - 1:
                    syllable += punctuation
                syllables.append(syllable)
                pos += len(syl)
            return syllables
    hyphenated = _HYPHENATOR.inserted(stripped, hyphen='\u00ad')
    parts = hyphenated.split('\u00ad')
    if parts:
        parts[-1] += punctuation
    return parts if parts else [word]


def _syllabify_row(row_text: str) -> list[tuple[str, bool]]:
    """Syllabify a row's text string.

    Returns a list of (syllable_text, has_trailing_hyphen) pairs.
    The verse prefix (e.g. "1. ") is returned as a separate first element
    so it occupies onset[0] while the first real syllable goes to onset[1].
    """
    text = row_text.strip()
    if not text:
        return []

    prefix = ''
    rest = text
    prefix_match = re.match(r'^(\d+\.\s*)', text)
    if prefix_match:
        prefix = prefix_match.group(1)
        rest = text[len(prefix):]

    syllables: list[tuple[str, bool]] = []
    if prefix:
        syllables.append((prefix, False))

    words = rest.split(' ')
    for word in words:
        if not word:
            continue
        parts = _syllabify_word(word)
        for syl_idx, syllable in enumerate(parts):
            is_last_in_word = syl_idx == len(parts) - 1
            has_trailing_hyphen = not is_last_in_word
            syllables.append((syllable, has_trailing_hyphen))

    return syllables


# --- Syllable rendering constants (Liberation Serif) ---
_HYPHEN_CHAR_RATIO = 0.25
_MIN_SYLLABLE_FONT = 5.0
_FIXED_SYLLABLE_FONT = 7.0
# Maximum horizontal compression of a wide syllable: baked glyphs can shrink
# to (1 - this) of natural width before the font size counts as too large.
_MAX_GLYPH_COMPRESS = 0.3

# Trailing punctuation gets a tighter gap reservation when clipping syllables.
_PUNCT_SET = set('.,;:!?')

# --- Baked-glyph lyric output ---
# Lyrics are emitted as glyph outlines (<use> of <path> defs), matching the
# pure-vector style of the upstream LilyPond scores: no <text> elements, no
# runtime font dependency, and real horizontal compression instead of the
# letter-spacing flutter_svg ignores.


@lru_cache(maxsize=1)
def _lyric_ttfont() -> TTFont:
    """Liberation Serif loaded once, resolved the same way PIL resolves it."""
    return TTFont(ImageFont.truetype(LYRIC_FONT_PATH, 10).path)


def _shape_advances(text: str) -> list[tuple[str, float]]:
    """(glyph name, advance incl. kerning) per char, in font units."""
    font = _lyric_ttfont()
    cmap = font.getBestCmap()
    names = [cmap.get(ord(ch)) or 'space' for ch in text]
    metrics = font['hmtx'].metrics
    kern = font['kern'].kernTables[0].kernTable
    return [
        (
            name,
            metrics[name][0]
            + (kern.get((name, names[i + 1]), 0) if i + 1 < len(names) else 0),
        )
        for i, name in enumerate(names)
    ]


def _real_text_width(text: str, font_size: float) -> float:
    """Measure the real rendered width of *text* at *font_size* in SVG units."""
    scale = font_size / _lyric_ttfont()['head'].unitsPerEm
    return sum(advance for _, advance in _shape_advances(text)) * scale


@lru_cache(maxsize=2048)
def _glyph_path_d(glyph_name: str, scale: float) -> str:
    """SVG path d for a glyph, scaled to lyric font size, y flipped."""
    glyph_set = _lyric_ttfont().getGlyphSet()
    pen = SVGPathPen(glyph_set)
    glyph_set[glyph_name].draw(
        TransformPen(pen, (scale, 0, 0, -scale, 0, 0))
    )
    return pen.getCommands()


def _emit_baked_text(
    parent: ET.Element,
    x: float,
    y: float,
    text: str,
    font_size: float,
    used_glyphs: set[str],
    scale_x: float = 1.0,
    clip_id: str | None = None,
) -> None:
    """Emit *text* as <use>-instanced glyph outlines at (x, y).

    *used_glyphs* accumulates the def ids this render needs.  scale_x applies
    real horizontal compression (group transform), and clip_id applies a
    clip-path in the parent's coordinate space.  Every run is wrapped in a
    <g> so syllable boundaries stay explicit.
    """
    font = _lyric_ttfont()
    unit = font_size / font['head'].unitsPerEm
    glyf = font['glyf']
    outer = ET.SubElement(parent, _G_TAG)
    if clip_id is not None:
        outer.set('clip-path', f'url(#{clip_id})')
    target = outer
    if scale_x != 1.0:
        inner = ET.SubElement(target, _G_TAG)
        inner.set(
            'transform',
            f'translate({x:.3f} {y:.3f}) scale({scale_x:.4f} 1)',
        )
        target = inner
        x = y = 0.0
    cursor = x
    for name, advance in _shape_advances(text):
        if glyf[name].numberOfContours != 0:
            gid = f'lg-{name}'
            used_glyphs.add(gid)
            use = ET.SubElement(target, _USE_TAG)
            use.set(XLINK_HREF, f'#{gid}')
            use.set('x', f'{cursor:.3f}')
            use.set('y', f'{y:.3f}')
        cursor += advance * unit


def _compute_song_font_size(
    rows: list[SvgLyricRow],
    score_lines: list[str],
    note_onsets_per_row: list[list[float]] | None,
    recovery_candidates_per_row: list[list[tuple[float, float]]] | None = None,
) -> float:
    """Find the largest font size that avoids severe clipping for the song.

    Iteratively reduces from _FIXED_SYLLABLE_FONT down to _MIN_SYLLABLE_FONT.
    At each size, pre-scans every row: if any syllable's real rendered width
    exceeds its clip width by more than half of its last character's width,
    the size is too large and we try the next smaller step.
    """
    font = _FIXED_SYLLABLE_FONT
    while font > _MIN_SYLLABLE_FONT:
        if not _has_severe_clipping(
            rows, score_lines, note_onsets_per_row, font,
            recovery_candidates_per_row,
        ):
            return font
        font -= 0.5
    return _MIN_SYLLABLE_FONT


def _row_syllable_positions(
    onsets: list[float],
    recovery_candidates: list[tuple[float, float]] | None,
    n_syls: int,
) -> list[float]:
    """Per-syllable x positions for a row.

    Syllable i sits on detected onset i (sequential 1:1 mapping — trailing
    notes without syllables are melismas, which is normal in hymn
    notation).  When more syllables are assigned than detected onsets,
    notehead-verified recovery candidates are inserted first (most
    confident = closest to their notehead), then midpoints of the widest
    gaps as a last resort.
    """
    # Onset lists can arrive unordered (e.g. merged font subsets), and
    # syllable i must map to the i-th leftmost position — always sort.
    positions = sorted(onsets[:n_syls])
    if n_syls > len(positions) and recovery_candidates:
        extra = sorted(
            (
                (x, d)
                for x, d in recovery_candidates
                if all(abs(x - p) > 1.0 for p in positions)
            ),
            key=lambda t: t[1],
        )
        positions.extend(x for x, _d in extra[: n_syls - len(positions)])
        positions.sort()
    while len(positions) < n_syls:
        if len(positions) < 2:
            # Single (or no) onset: extend with a typical syllable pitch.
            positions.append((positions[-1] if positions else 0.0) + 8.0)
            continue
        gaps = [
            (positions[j + 1] - positions[j], j)
            for j in range(len(positions) - 1)
        ]
        _, best_j = max(gaps, key=lambda t: t[0])
        positions.insert(best_j + 1, (positions[best_j] + positions[best_j + 1]) / 2)
    return positions


def _has_severe_clipping(
    rows: list[SvgLyricRow],
    score_lines: list[str],
    note_onsets_per_row: list[list[float]] | None,
    font_size: float,
    recovery_candidates_per_row: list[list[tuple[float, float]]] | None = None,
) -> bool:
    """Check if any syllable would be clipped by more than half its last char."""
    for row_idx, row in enumerate(rows):
        onsets: list[float] | None = None
        if note_onsets_per_row is not None and row_idx < len(note_onsets_per_row):
            onsets = note_onsets_per_row[row_idx]
        if not onsets:
            continue

        line = score_lines[row_idx] if row_idx < len(score_lines) else ''
        syllables = _syllabify_row(line)
        if not syllables:
            continue

        n_syls = len(syllables)
        candidates = (
            recovery_candidates_per_row[row_idx]
            if recovery_candidates_per_row is not None
            and row_idx < len(recovery_candidates_per_row)
            else None
        )
        positions = _row_syllable_positions(onsets, candidates, n_syls)

        for i, (syl_text, has_hyph) in enumerate(syllables):
            next_x = positions[i + 1] if i + 1 < n_syls else None
            if next_x is None:
                continue
            gap = next_x - positions[i]
            is_word_final = not has_hyph and i < n_syls - 1
            if is_word_final:
                if syl_text and syl_text[-1] in _PUNCT_SET:
                    reserve = min(font_size * 0.15, gap * 0.15)
                else:
                    reserve = min(font_size * 0.20, gap * 0.20)
            else:
                reserve = min(font_size * 0.15, gap * 0.15)
            clip_w = max(gap - reserve, 0.0)
            nat_w = _real_text_width(syl_text, font_size)
            overflow = nat_w - clip_w
            if overflow > 0 and syl_text[-1] != ' ':
                last_char_w = _real_text_width(syl_text[-1], font_size)
                # Multi-character syllables can be compressed with negative
                # letter-spacing; compute the most overflow we can remove.
                max_compress = (
                    (len(syl_text) - 1)
                    * font_size
                    * _MAX_GLYPH_COMPRESS
                )
                if overflow - last_char_w * 0.5 > max_compress:
                    return True

    return False


def _emit_lyric_row(
    group: ET.Element,
    row: SvgLyricRow,
    syllables: list[tuple[str, bool]],
    positions: list[float],
    syl_font: float,
    clip_rects: list[tuple[str, float, float, float, float]],
    used_glyphs: set[str],
) -> None:
    """Render one lyric row: baked glyph outlines per syllable at its onset."""
    n_syls = len(syllables)
    for i, (syl_text, has_hyph) in enumerate(syllables):
        x = positions[i]
        next_x = positions[i + 1] if i + 1 < n_syls else None

        clip_w = None
        if next_x is not None:
            gap = next_x - x
            is_word_final = not has_hyph and i < n_syls - 1
            if is_word_final:
                if syl_text and syl_text[-1] in _PUNCT_SET:
                    reserve = min(syl_font * 0.15, gap * 0.15)
                else:
                    reserve = min(syl_font * 0.20, gap * 0.20)
            else:
                # Smaller gap within a hyphenated word, but always
                # enough whitespace to keep this syllable's glyphs
                # from touching the next syllable.  flutter_svg
                # ignores textLength, so wide syllables are clipped;
                # the reserved gap guarantees visible separation.
                reserve = min(syl_font * 0.15, gap * 0.15)
            clip_w = max(gap - reserve, 0.0)

        nat_w = _real_text_width(syl_text, syl_font)
        clip_id = None
        scale_x = 1.0
        if clip_w is not None:
            clip_id = f'clip{len(clip_rects)}'
            clip_rects.append((clip_id, x, row.y, clip_w, syl_font))
            if nat_w > clip_w:
                # Real horizontal compression — unlike letter-spacing this
                # actually applies in flutter_svg/vector_graphics.
                scale_x = max(clip_w / nat_w, 1.0 - _MAX_GLYPH_COMPRESS)
        _emit_baked_text(
            group, x, row.y, syl_text, syl_font, used_glyphs, scale_x, clip_id
        )
        rendered_width = nat_w * scale_x

        if has_hyph and next_x is not None:
            syl_end = x + min(
                rendered_width,
                clip_w if clip_w is not None else rendered_width,
            )
            available = next_x - syl_end
            hyphen_width = syl_font * _HYPHEN_CHAR_RATIO
            if available >= hyphen_width:
                hyphen_x = syl_end + (available - hyphen_width) / 2
                _emit_baked_text(
                    group, hyphen_x, row.y, '-', syl_font, used_glyphs
                )


def _emit_overflow_lines(
    group: ET.Element,
    rows: list[SvgLyricRow],
    leftover_line: str,
    font_size: float,
    used_glyphs: set[str],
    base_y: float | None = None,
) -> float:
    """Render leftover verse text as wrapped lines below the last staff row.

    ``base_y`` overrides the emission's first baseline — prose-only pages
    anchor the wrapped text at the top of the detected text area instead
    of below the last row.

    Returns the y coordinate of the lowest line's bottom (0.0 when nothing
    was emitted) so the caller can grow the viewBox to fit it.
    """
    spacings = [
        rows[i + 1].y - rows[i].y
        for i in range(len(rows) - 1)
        if rows[i + 1].y > rows[i].y
    ]
    row_spacing = (
        sorted(spacings)[len(spacings) // 2] if spacings else font_size * 4
    )
    x_start = min(row.x_min for row in rows)
    max_width = max(row.x_max for row in rows) - x_start
    words = leftover_line.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = ' '.join(current + [word])
        if current and _real_text_width(trial, font_size) > max_width:
            lines.append(' '.join(current))
            current = [word]
        else:
            current.append(word)
    if current:
        lines.append(' '.join(current))

    if base_y is None:
        base_y = rows[-1].y + row_spacing * 0.8
    line_step = font_size * 2.4
    last_line_bottom = 0.0
    for line_idx, line in enumerate(lines):
        _emit_baked_text(
            group,
            x_start,
            base_y + line_idx * line_step,
            line,
            font_size,
            used_glyphs,
        )
        last_line_bottom = base_y + line_idx * line_step + font_size * 1.4
    return last_line_bottom


def _view_box_parts(root: ET.Element) -> list[str] | None:
    """The four viewBox fields as strings, or None when absent/malformed."""
    view_box = root.get('viewBox')
    if not view_box:
        return None
    parts = view_box.replace(',', ' ').split()
    return parts if len(parts) == 4 else None


def _grow_view_box(root: ET.Element, needed_height: float) -> None:
    """Grow the viewBox height so overflow content stays visible.

    The width/height attributes carry the same units as the viewBox in
    LilyPond output, so the height attribute must grow with it —
    otherwise the fixed-size viewport squeezes the taller content.
    """
    parts = _view_box_parts(root)
    if parts is None:
        return
    if needed_height > float(parts[3]):
        root.set(
            'viewBox',
            f'{parts[0]} {parts[1]} {parts[2]} {needed_height:.2f}',
        )
        if root.get('height') is not None:
            root.set('height', f'{needed_height:.2f}')


def _strip_below_view_box(
    root: ET.Element, limit: float | None = None
) -> None:
    """Drop elements below the usable area.

    The viewBox itself is the outer bound — LilyPond embeds the next page's
    system in the same SVG; invisible content only bloats files.  *limit*
    (last lyric row + descender room) additionally strips revealed page
    furniture — e.g. the printed next-verse prose a grown viewBox would
    expose — while the generated-lyrics group stays exempt (overflow lines
    legitimately sit below the last score row).
    """
    parts = _view_box_parts(root)
    if parts is None:
        return
    cut = float(parts[3])
    if limit is not None:
        cut = min(cut, limit)

    def _walk(
        parent: ET.Element, off_y: float, sy: float, in_generated: bool
    ) -> None:
        # Elements positioned by ancestor transforms (e.g. compressed
        # syllables inside translate/scale groups) need their effective y.
        for child in list(parent):
            inside = in_generated or child.get('id') == 'generated-lyrics'
            cy = child.get('y')
            if (
                cy is not None
                and not inside
                and off_y + sy * float(cy) > cut
            ):
                parent.remove(child)
                continue
            if child.tag == _DEFS_TAG:
                continue
            c_off, c_sy = off_y, sy
            for tm in re.finditer(
                r'(translate|scale)\(([^)]*)\)', child.get('transform', '')
            ):
                nums = [
                    float(n)
                    for n in re.split(r'[ ,]+', tm.group(2).strip())
                    if n
                ]
                if tm.group(1) == 'translate' and len(nums) == 2:
                    c_off += c_sy * nums[1]
                elif tm.group(1) == 'scale' and nums:
                    c_sy *= nums[1] if len(nums) > 1 else nums[0]
            _walk(child, c_off, c_sy, inside)

    _walk(root, 0.0, 1.0, False)

    # The strip can empty nested <g> wrappers; drop the husks bottom-up so
    # no dead groups or defs remain.  An anonymous empty <g> renders
    # nothing; a <g> with an id is a glyph def — LilyPond emits empty ones
    # that must stay so <use> references resolve.
    def _husk(parent: ET.Element) -> None:
        for child in list(parent):
            if (
                child.tag == _G_TAG
                and len(list(child)) == 0
                and child.get('id') is None
            ):
                parent.remove(child)
                continue
            if child.tag != _DEFS_TAG:
                _husk(child)

    for _ in range(8):
        before = len(list(root.iter(_G_TAG)))
        _husk(root)
        if len(list(root.iter(_G_TAG))) == before:
            break


def _write_defs(
    root: ET.Element,
    clip_rects: list[tuple[str, float, float, float, float]],
    used_glyphs: set[str],
    font_size: float,
) -> None:
    """Write clipPath and baked-glyph path defs used by the emitted lyrics.

    Called after the below-viewBox strip, so elements that were removed no
    longer appear in the tree — their defs are skipped via the reference
    scan rather than left as orphans.
    """
    refs = {
        match.group(1)
        for el in root.iter()
        for value in el.attrib.values()
        for match in [re.search(r'url\(#([^)]+)\)', value)]
        if match
    }
    refs.update(
        href[1:]
        for u in root.iter(_USE_TAG)
        if (href := u.get(XLINK_HREF, '')).startswith('#')
    )
    clip_rects = [r for r in clip_rects if r[0] in refs]
    used_glyphs = {g for g in used_glyphs if g in refs}
    if not clip_rects and not used_glyphs:
        return
    defs = root.find(_DEFS_TAG)
    if defs is None:
        defs = ET.Element(_DEFS_TAG)
        root.insert(0, defs)
    scale = font_size / _lyric_ttfont()['head'].unitsPerEm
    for gid in sorted(used_glyphs):
        path = ET.SubElement(defs, _PATH_TAG)
        path.set('id', gid)
        path.set('d', _glyph_path_d(gid[3:], scale))
    for clip_id, cx, cy, clip_width, cfs in clip_rects:
        clip_path = ET.SubElement(defs, _CLIP_PATH_TAG)
        clip_path.set('id', clip_id)
        rect = ET.SubElement(clip_path, _RECT_TAG)
        rect.set('x', f'{cx:.3f}')
        # Start 1.2× font-size above baseline so diacritical marks on
        # accented letters (é, á, ő …) are not clipped at the top.
        rect.set('y', f'{cy - cfs * 1.2:.3f}')
        # clip_width was pre-computed: last-char offset + 0.75×font_size,
        # capped at (gap − min_gap) to preserve word-break spacing.
        rect.set('width', f'{clip_width:.3f}')
        rect.set('height', f'{cfs * 1.8:.3f}')  # 1.2 above + 0.6 below baseline


def render_verse_svg(
    svg_text: str,
    verse_text: str,
    score_block: SvgLyricBlock,
    footer_block: SvgLyricBlock | None,
    note_onsets_per_row: list[list[float]] | None = None,
    recovery_candidates_per_row: list[list[tuple[float, float]]] | None = None,
    forced_font_size: float | None = None,
    lyric_rows: list[SvgLyricRow] | None = None,
    prose_page: bool = False,
) -> str:
    # lyric_rows are the display rows text is assigned to — same as
    # score_block.rows unless same-baseline fragment rows were merged.
    # score_block stays physical so source glyph removal keeps per-font
    # precision.  prose_page marks a source with no lyric slots at all
    # (a prose-only chant like song 464): the verse is emitted as wrapped
    # text lines instead of syllable-to-onset alignment.
    if lyric_rows is None:
        lyric_rows = list(score_block.rows)
    root = ET.fromstring(svg_text)
    _remove_header_text(root, score_block)
    _remove_lyric_uses(root, score_block, footer_block)

    target_widths = [_row_target_width(row) for row in lyric_rows]
    group = ET.SubElement(root, _G_TAG)
    group.set('id', 'generated-lyrics')
    # Accumulate clipPath specs; added to <defs> before serialisation to prevent
    # textLength ink from overflowing into adjacent syllables/words.
    clip_rects: list[tuple[str, float, float, float, float]] = []  # (id, x, y, tl, fs)
    used_glyphs: set[str] = set()  # baked-glyph def ids this file needs

    # Use note-count-based split when note positions are available
    leftover_line = ''
    if prose_page:
        score_lines = []
        leftover_line = verse_text
    elif note_onsets_per_row is not None:
        note_counts = [len(onsets) for onsets in note_onsets_per_row]
        max_counts = (
            [
                len(onsets) + len(recovery_candidates_per_row[i])
                for i, onsets in enumerate(note_onsets_per_row)
            ]
            if recovery_candidates_per_row is not None
            else None
        )
        score_lines, leftover_line = split_verse_text_by_note_counts(
            verse_text, note_counts, max_counts
        )
    else:
        score_lines = split_verse_text_to_rows(verse_text, target_widths)

    # --- Determine the font size for this song ---
    # If a forced font size is provided (computed across all verses), use it.
    # Otherwise, iteratively reduce from the standard size.
    if forced_font_size is not None:
        global_font = forced_font_size
    else:
        global_font = _compute_song_font_size(
            lyric_rows, score_lines, note_onsets_per_row,
            recovery_candidates_per_row,
        )

    # --- Render all rows with the single global font size ---
    last_text_row_y: float | None = None
    for row_idx, (row, line) in enumerate(zip(lyric_rows, score_lines)):
        onsets: list[float] | None = None
        if note_onsets_per_row is not None and row_idx < len(note_onsets_per_row):
            onsets = note_onsets_per_row[row_idx]

        syllables = _syllabify_row(line) if onsets else None

        if syllables and onsets:
            candidates = (
                recovery_candidates_per_row[row_idx]
                if recovery_candidates_per_row is not None
                and row_idx < len(recovery_candidates_per_row)
                else None
            )
            # Sequential 1:1 mapping: syllable i sits on note i, starting
            # from the first note.  Trailing notes without a syllable are
            # melismas (held notes), which is normal in hymn notation.
            # Proportional spreading would push syllables off their notes.
            positions = _row_syllable_positions(onsets, candidates, len(syllables))
            _emit_lyric_row(
                group, row, syllables, positions, global_font, clip_rects,
                used_glyphs,
            )
            last_text_row_y = row.y
        else:
            # No onset data: emit the whole line at the chosen font size.
            _emit_baked_text(
                group, row.x_min, row.y, line, global_font, used_glyphs
            )
            if line.strip():
                last_text_row_y = row.y

    # Some source SVGs embed continuation systems below the cropped viewBox;
    # their lyric rows are detected as score rows.  Grow the canvas to the
    # last row that received text so those systems (and their lyrics) stay
    # visible, then strip anything printed below it — the revealed band can
    # contain the page's prose verses and other furniture.  Trailing
    # detected rows that got no text (printed verse paragraphs detected as
    # lyric rows) must not extend the canvas.
    strip_y = None
    if lyric_rows:
        parts = _view_box_parts(root)
        orig_vb = float(parts[3]) if parts else None
        bound_y = (
            last_text_row_y if last_text_row_y is not None
            else lyric_rows[-1].y
        )
        if orig_vb is not None and bound_y > orig_vb:
            strip_y = bound_y + global_font * 0.6
            _grow_view_box(root, bound_y + global_font * 1.5)

    # Verse text that did not fit the score's note slots is rendered as plain
    # lyric lines below the last row — in the printed book it would continue
    # under the next page's staff.
    if leftover_line and lyric_rows:
        last_line_bottom = _emit_overflow_lines(
            group,
            lyric_rows,
            leftover_line,
            global_font,
            used_glyphs,
            base_y=lyric_rows[0].y if prose_page else None,
        )
        # Overflow lines may extend below the original viewBox (short incipit
        # scores): grow the canvas so the text stays visible instead of being
        # silently clipped.
        if last_line_bottom:
            _grow_view_box(root, last_line_bottom)

    _strip_below_view_box(root, strip_y)
    _write_defs(root, clip_rects, used_glyphs, global_font)
    return ET.tostring(root, encoding='unicode')


_PRINTED_NUMBERS: dict[str, int] | None = None


def _printed_song_number(source_song_number: str) -> int | None:
    """The printed hymnal number shown in a source score's heading."""
    global _PRINTED_NUMBERS
    if _PRINTED_NUMBERS is None:
        p = Path(__file__).resolve().parent / 'printed_numbers.json'
        _PRINTED_NUMBERS = (
            {
                int(k): int(v)
                for k, v in json.loads(p.read_text(encoding='utf-8')).items()
            }
            if p.exists()
            else {}
        )
    return _PRINTED_NUMBERS.get(int(source_song_number))


def _strip_printed_song_number(svg_text: str, printed_number: int) -> str:
    """Drop the score heading's printed song number when it does not match
    the app's song number — the app shows its own number, and the printed
    one (e.g. '422' under Erdélyi song 491) is misleading furniture.

    In the generated sheet the number is the topmost run of digit glyphs
    sharing one font subset; a neighbouring title run uses a second font.
    """
    uses = [u for u in _ref48_uses(svg_text) if not u[4].startswith('lg-')]
    if not uses:
        return svg_text
    top_y = min(u[3] for u in uses)
    top = [u for u in uses if u[3] <= top_y + 1.0]
    groups: dict[str, list] = {}
    for u in top:
        groups.setdefault(u[4].rsplit('-', 1)[0], []).append(u)
    digits = len(str(printed_number))
    best = None
    for members in groups.values():
        members.sort(key=lambda u: u[2])
        if len(members) not in (digits, digits + 1):
            continue
        xs = [u[2] for u in members]
        if any(b - a > 20.0 for a, b in zip(xs, xs[1:])):
            continue
        if best is None or members[0][2] < best[0][2]:
            best = members
    if best is None:
        return svg_text
    for u in sorted(best, key=lambda u: u[0], reverse=True):
        svg_text = svg_text[: u[0]] + svg_text[u[1] :]
    return svg_text


def generate_score_files_from_svg_path(
    target_song_number: str,
    verse_texts: list[str],
    svg_path: Path,
    *,
    printed_number: int | None = None,
) -> list[str]:
    if not svg_path.exists():
        return []

    svg_text = svg_path.read_text()
    score_block, footer_block = detect_svg_lyric_blocks(svg_text)
    if score_block is None:
        return []

    # Compute per-row note onsets from verse-1 (source) SVG glyph positions.
    # Glyph-shape data is per font subset; merged rows carry their own
    # font_id, so shapes are resolved once per distinct row font.
    note_onsets_per_row: list[list[float]] | None = None
    recovery_candidates_per_row: list[list[tuple[float, float]]] | None = None
    if score_block.font_id != '*':
        row_fonts = [
            row.font_id or score_block.font_id for row in score_block.rows
        ]
        shapes = {
            fid: _extract_font_glyph_shapes(svg_text, fid)
            for fid in set(row_fonts)
        }
        note_onsets_per_row = [
            _extract_note_onsets(row, *shapes[fid])
            for row, fid in zip(score_block.rows, row_fonts)
        ]
        text_font_ids = set(row_fonts)
        if footer_block is not None:
            text_font_ids.update(
                row.font_id for row in footer_block.rows if row.font_id
            )
        staff_clusters = _staff_note_clusters(
            _extract_notehead_positions(svg_text, text_font_ids)
        )
        recovery_candidates_per_row = [
            _find_recovery_candidates(
                row,
                onsets,
                staff_clusters,
                shapes[fid].hyphen_id,
                shapes[fid].space_id,
                shapes[fid].separator_ids,
            )
            for row, onsets, fid in zip(
                score_block.rows, note_onsets_per_row, row_fonts
            )
        ]

    # Collapse same-baseline fragment rows into display rows: each visual
    # row gets one line and the union of its fragments' onset slots.
    # Printed verse paragraphs detected as rows (no syllable hyphens) are
    # trimmed from the top and bottom of the block — their glyph uses are
    # still removed by _remove_lyric_uses, they just receive no text.
    row_groups = _group_rows_by_baseline(score_block.rows)
    prose_page = False
    if note_onsets_per_row is not None:
        hyphenated = [
            _group_has_hyphen(
                group, score_block.rows, score_block.font_id, shapes
            )
            for group in row_groups
        ]
        # A page with no staff lines is a prose-only chant (e.g. song
        # 464) even when a stray hyphen glyph exists in its text.  So is
        # a page whose detected rows carry no syllable hyphens AND none
        # sits below a staff system — genuine lyric rows always land
        # just under a staff (e.g. song 330's unhyphenated lyric rows
        # must not be mistaken for prose).
        staff_bands = _staff_clusters(svg_text)
        prose_page = not staff_bands or (
            not any(hyphenated)
            and not any(
                bottom < row.y <= bottom + 45.0
                for row in score_block.rows
                for _top, bottom in staff_bands
            )
        )
        if not prose_page:
            keep = _lyric_group_mask(
                row_groups, score_block.rows, score_block.font_id, shapes
            )
            row_groups = [g for g, k in zip(row_groups, keep) if k]
    lyric_rows = [
        _merge_row_group(score_block.rows, group) for group in row_groups
    ]
    if note_onsets_per_row is not None:
        note_onsets_per_row = [
            sorted({x for i in group for x in note_onsets_per_row[i]})
            for group in row_groups
        ]
        if recovery_candidates_per_row is not None:
            recovery_candidates_per_row = [
                sorted(
                    {
                        c
                        for i in group
                        for c in recovery_candidates_per_row[i]
                    }
                )
                for group in row_groups
            ]

    # Compute a single font size across all verses so the entire song
    # uses one consistent size.  We take the minimum across verses.
    song_font = _FIXED_SYLLABLE_FONT
    if note_onsets_per_row is not None:
        note_counts = [len(onsets) for onsets in note_onsets_per_row]
        max_counts = (
            [
                len(onsets) + len(recovery_candidates_per_row[i])
                for i, onsets in enumerate(note_onsets_per_row)
            ]
            if recovery_candidates_per_row is not None
            else None
        )
        for verse_text in verse_texts:
            lines, _leftover = split_verse_text_by_note_counts(
                verse_text, note_counts, max_counts
            )
            verse_font = _compute_song_font_size(
                lyric_rows, lines, note_onsets_per_row, recovery_candidates_per_row
            )
            song_font = min(song_font, verse_font)

    strip_number = (
        printed_number is not None
        and printed_number != int(target_song_number)
    )
    score_files = []
    for verse_index, verse_text in enumerate(verse_texts):
        output_path = generated_svg_path(target_song_number, verse_index)
        rendered = render_verse_svg(
            svg_text,
            verse_text,
            score_block,
            footer_block,
            note_onsets_per_row=note_onsets_per_row,
            recovery_candidates_per_row=recovery_candidates_per_row,
            forced_font_size=song_font if note_onsets_per_row is not None else None,
            lyric_rows=lyric_rows,
            prose_page=prose_page,
        )
        if strip_number:
            rendered = _strip_printed_song_number(rendered, printed_number)
        output_path.write_text(rendered)
        score_files.append(f'assets/referdelyi/{output_path.name}')
    return score_files


def generate_score_files_from_source_svg(
    target_song_number: str,
    verse_texts: list[str],
    *,
    source_song_number: str | None = None,
) -> list[str]:
    source_number = source_song_number or target_song_number
    return generate_score_files_from_svg_path(
        target_song_number,
        verse_texts,
        source_svg_path(source_number),
        printed_number=_printed_song_number(source_number),
    )


def find_ref48_source_song(songbook: dict, erdelyi_song_number: str) -> str | None:
    erdelyi_song = songbook['erdelyi'][erdelyi_song_number]
    normalized_target_title = normalize_title(erdelyi_song['title'])
    matches = [
        song_number
        for song_number, song in songbook['48'].items()
        if normalize_title(song.get('title', '')) == normalized_target_title
        and ref48_svg_path(song_number).exists()
    ]
    if len(matches) == 1:
        return matches[0]
    return None


# A verse number is rendered as one <use> per digit (or a ligature) plus a
# trailing "." — which in this font subset is a tiny filled rectangle.
_REF48_DOT_D_RE = re.compile(
    r'm-?\d+(?:\.\d+)? 0v(?P<h1>-?\d+(?:\.\d+)?)h(?P<w>-?\d+(?:\.\d+)?)'
    r'v(?P<h2>-?\d+(?:\.\d+)?)z'
)

# Lyric rows hold a full line of syllabified text — a dozen or more <use>
# symbols; staff/note rows place only a handful.
_REF48_LYRIC_ROW_MIN_USES = 8

# (song, 0-based verse) -> lyric rows to keep when the ref48 sheet prints
# verse lines the Erdélyi edition dropped.  ref48-267 verse 7 appends a
# two-line doxology ('Adj mindvégig megmaradást / És idvességes kimúlást!')
# that Erdélyi 405 does not have, so its last two systems are cropped away.
_REF48_TRUNCATE_AFTER_LYRIC_ROW = {('405', 6): 3}


def _ref48_uses(content: str) -> list[tuple[int, int, float, float, str]]:
    """All <use> elements as (start, end, x, y, href); a missing x means 0."""
    out = []
    for m in re.finditer(r'<use\b[^>]*?/?>', content):
        tag = m.group(0)
        href = re.search(r'xlink:href="#([^"]+)"', tag)
        y = re.search(r'\by="(-?\d+(?:\.\d+)?)"', tag)
        if not (href and y):
            continue
        x = re.search(r'\bx="(-?\d+(?:\.\d+)?)"', tag)
        out.append(
            (m.start(), m.end(), float(x.group(1)) if x else 0.0,
             float(y.group(1)), href.group(1))
        )
    return out


def _ref48_lyric_rows(content: str) -> list[tuple[float, list]]:
    rows: dict[float, list] = {}
    for u in _ref48_uses(content):
        rows.setdefault(round(u[3], 2), []).append(u)
    return [
        (y, sorted(ms, key=lambda u: u[2]))
        for y, ms in sorted(rows.items())
        if len(ms) >= _REF48_LYRIC_ROW_MIN_USES
    ]


def _ref48_is_dot(content: str, href: str) -> bool:
    """True if the symbol renders the tiny filled rectangle used for '.'."""
    m = re.search(
        r'<symbol id="%s"[^>]*><path d="([^"]*)"' % re.escape(href), content
    )
    if not m:
        return False
    d = re.sub(r'zm0 0$', 'z', m.group(1).strip())
    r = _REF48_DOT_D_RE.fullmatch(d)
    return bool(
        r
        and abs(float(r.group('h1'))) <= 6
        and abs(float(r.group('w'))) <= 6
    )


def _ref48_number_cluster(content: str, row_uses: list) -> list | None:
    """Leading 'N.' uses of a lyric row: digits/ligature ending with '.'."""
    cluster = []
    for u in row_uses:
        cluster.append(u)
        if _ref48_is_dot(content, u[4]):
            return cluster
        if len(cluster) >= 4:
            break
    return None


def _ref48_digit_symbols(ref48_dir: Path, number: int) -> list[str] | None:
    """Glyph defs for the digits of `number`, lifted from any ref48 verse
    sheet that prints `number.` — its first lyric row begins with the digit
    uses followed by a period."""
    digits = str(number)
    for donor in sorted(ref48_dir.glob(f'ref48-*-{number:03d}.svg')):
        content = donor.read_text(encoding='utf-8')
        rows = _ref48_lyric_rows(content)
        if not rows:
            continue
        cluster = _ref48_number_cluster(content, rows[0][1])
        if cluster is None:
            continue
        defs = [
            re.search(
                r'<symbol id="%s"[^>]*>.*?</symbol>' % re.escape(u[4]),
                content,
                re.S,
            )
            for u in cluster[:-1]
        ]
        if len(defs) == len(digits) and all(defs):
            return [d.group(0) for d in defs]
    return None


def _renumber_ref48_sheet(
    content: str, printed_number: int, target_number: int, ref48_dir: Path
) -> str | None:
    """Rewrite the 'N.' verse-number heading of a ref48 verse sheet to the
    target edition's verse number, reusing digit glyphs from a donor sheet
    that prints that number."""
    if printed_number == target_number:
        return content
    digit_syms = _ref48_digit_symbols(ref48_dir, target_number)
    rows = _ref48_lyric_rows(content)
    if digit_syms is None or not rows:
        return None
    row = rows[0][1]
    cluster = _ref48_number_cluster(content, row)
    if cluster is None:
        return None
    cluster = sorted(cluster, key=lambda u: u[0])
    # The number cluster must be contiguous in the file — refuse to splice
    # across unrelated elements.
    for a, b in zip(cluster, cluster[1:]):
        if content[a[1] : b[0]].strip():
            return None
    start_x = cluster[0][2]
    spacing = (cluster[-1][2] - start_x) / max(len(cluster) - 1, 1)
    digits = str(target_number)
    parts = [
        f'<use x="{start_x + i * spacing}" xlink:href="#ref48-renum-{i}"'
        f' y="{cluster[0][3]}"/>'
        for i in range(len(digits))
    ]
    parts.append(
        f'<use x="{start_x + len(digits) * spacing}"'
        f' xlink:href="#{cluster[-1][4]}" y="{cluster[0][3]}"/>'
    )
    content = (
        content[: cluster[0][0]]
        + ''.join(parts)
        + content[cluster[-1][1] :]
    )
    injected = []
    for i, sym in enumerate(digit_syms):
        orig_id = re.search(r'id="([^"]+)"', sym).group(1)
        injected.append(
            sym.replace(f'id="{orig_id}"', f'id="ref48-renum-{i}"', 1)
        )
    # ref48 files keep <symbol>/<clipPath> defs as top-level children with
    # no <defs> wrapper — inject right after the root <svg> tag.
    svg_open = re.search(r'<svg\b[^>]*>', content)
    if svg_open is None:
        return None
    insert_at = svg_open.end()
    return (
        content[:insert_at] + ''.join(injected) + content[insert_at:]
    )


def _truncate_ref48_sheet(content: str, keep_lyric_rows: int) -> str | None:
    """Crop systems below the `keep_lyric_rows`-th lyric row by shrinking the
    viewBox (and height) to the midpoint of the gap before the next system."""
    rows = _ref48_lyric_rows(content)
    if len(rows) <= keep_lyric_rows:
        return None
    last_keep_y = rows[keep_lyric_rows - 1][0]
    below = [u[3] for u in _ref48_uses(content) if u[3] > last_keep_y + 1]
    below += [
        float(m.group('y'))
        for m in re.finditer(
            r'<path d="[mM]-?[\d.]+[ ,](?P<y>-?[\d.]+)', content
        )
        if float(m.group('y')) > last_keep_y + 1
    ]
    if not below:
        return None
    crop = (last_keep_y + min(below)) / 2
    content = re.sub(
        r'viewBox="(\d+(?:\.\d+)? \d+(?:\.\d+)? [\d.]+) [\d.]+"',
        lambda m: f'viewBox="{m.group(1)} {crop:.2f}"',
        content,
        count=1,
    )
    return re.sub(r'height="[\d.]+em"', f'height="{crop:.2f}em"', content, count=1)


def copy_ref48_verse_svgs(
    target_song_number: str, verse_texts: list[str], ref48_song_number: str
) -> list[str]:
    """Pass ref48 per-verse score renders through as generated verse files.

    ref48-{song}-00K.svg is already the complete score for verse K —
    professionally hyphenated lyrics aligned to the notation — so
    synthesizing lg- lyrics on top of the ref48 symbol dialect is both
    unnecessary and broken.  The sheets are reused with two repairs: the
    printed 'N.' heading is rewritten when the target edition's verse number
    differs, and trailing ref48-only systems (e.g. a doxology) are cropped.
    """
    # ref48-{song}-NNN.svg is the render of printed verse NNN; verses that
    # were never digitized leave gaps in the sequence (e.g. ref48-263 has
    # 001-005,009,010,015,018-022 for the book's 13 kept verses).  Map the
    # available files to the song's verses in order.
    ref48_files = sorted(
        ref48_svg_path(ref48_song_number).parent.glob(
            f'ref48-{ref48_song_number.zfill(3)}-*.svg'
        )
    )
    score_files = []
    for verse_index, src in enumerate(ref48_files[: len(verse_texts)]):
        dst = generated_svg_path(target_song_number, verse_index)
        content = src.read_text(encoding='utf-8')
        printed_number = int(src.stem.rsplit('-', 1)[1])
        fixed = _renumber_ref48_sheet(
            content, printed_number, verse_index + 1, src.parent
        )
        if fixed is None:
            print(
                f'WARNING: could not renumber {src.name}'
                f' to verse {verse_index + 1}'
            )
        else:
            content = fixed
        keep_rows = _REF48_TRUNCATE_AFTER_LYRIC_ROW.get(
            (target_song_number, verse_index)
        )
        if keep_rows is not None:
            truncated = _truncate_ref48_sheet(content, keep_rows)
            if truncated is None:
                print(
                    f'WARNING: could not truncate {src.name}'
                    f' after {keep_rows} lyric rows'
                )
            else:
                content = truncated
        dst.write_text(content, encoding='utf-8')
        score_files.append(f'assets/referdelyi/{dst.name}')
    return score_files


def apply_generated_verse_svgs(songbook: dict) -> None:
    for song_number, song in songbook['erdelyi'].items():
        if song.get('hasScore') is not True:
            continue
        score_files = generate_score_files_from_source_svg(
            song_number,
            song.get('texts', []),
        )
        if not score_files:
            ref48_song_number = find_ref48_source_song(songbook, song_number)
            if ref48_song_number is not None:
                score_files = copy_ref48_verse_svgs(
                    song_number,
                    song.get('texts', []),
                    ref48_song_number,
                )
        if score_files:
            song['hasScore'] = True
            song['scoreFiles'] = score_files

    for target_song_number, source_song_number in SHARED_SCORE_ALIASES.items():
        target_song = songbook['erdelyi'].get(target_song_number)
        if target_song is None:
            continue
        score_files = generate_score_files_from_source_svg(
            target_song_number,
            target_song.get('texts', []),
            source_song_number=source_song_number,
        )
        if score_files:
            target_song['hasScore'] = True
            target_song['scoreFiles'] = score_files


def fallback_search_song_page(song_number: str, song_title: str) -> str | None:
    all_candidates = []
    seen = set()
    for query in title_queries(song_title):
        url = f'{SEARCH_URL}?{urllib.parse.urlencode({"q": query})}'
        rows = extract_search_rows(fetch_text(url))
        for row in rows:
            if row not in seen:
                seen.add(row)
                all_candidates.append(row)
    best_match = pick_best_search_match(song_number, song_title, all_candidates)
    if best_match is None:
        return None
    return urllib.parse.urljoin(BASE_URL, best_match[1])


def get_pdf_links(song_page_url: str) -> list[str]:
    html_text = fetch_text(song_page_url)
    hrefs = re.findall(r'href="(/documents/[^"]+\.pdf)"', html_text)
    return [urllib.parse.urljoin(BASE_URL, href) for href in hrefs]


def _extract_float_attr(tag: str, attr: str) -> float:
    match = re.search(rf'{attr}="(-?[0-9.]+)"', tag)
    if match is None:
        raise ValueError(f'Missing {attr} attribute in bbox HTML.')
    return float(match.group(1))


def extract_words_from_bbox_html(bbox_html: str) -> tuple[float, float, list[dict]]:
    page_match = re.search(r'(<page\b[^>]*>)(.*?)</page>', bbox_html, re.S)
    if page_match is None:
        raise ValueError('Could not find page element in bbox HTML.')
    page_tag = page_match.group(1)
    page_html = page_match.group(2)
    page_width = _extract_float_attr(page_tag, 'width')
    page_height = _extract_float_attr(page_tag, 'height')
    words = []
    for match in re.finditer(r'(<word\b[^>]*>)(.*?)</word>', page_html, re.S):
        word_tag = match.group(1)
        text = re.sub(r'<[^>]+>', '', match.group(2)).strip()
        if not text:
            continue
        words.append(
            {
                'text': html.unescape(text),
                'x_min': _extract_float_attr(word_tag, 'xMin'),
                'y_min': _extract_float_attr(word_tag, 'yMin'),
                'x_max': _extract_float_attr(word_tag, 'xMax'),
                'y_max': _extract_float_attr(word_tag, 'yMax'),
            },
        )
    return page_width, page_height, words


def compute_crop_bottom(page_height: float, words: list[dict]) -> float:
    second_verse_y = min(
        (
            word['y_min']
            for word in words
            if re.fullmatch(r'2\.', word['text'])
            and word['y_min'] > page_height * 0.3
        ),
        default=None,
    )
    if second_verse_y is not None:
        return max(second_verse_y - 8.0, page_height * 0.4)

    content_words = [
        word
        for word in words
        if word['y_min'] < page_height * 0.88
        and not (
            word['y_min'] > page_height * 0.85
            and (
                word['text'].isdigit()
                or re.fullmatch(r'[A-ZÁÉÍÓÖŐÚÜŰ]+', word['text'])
            )
        )
    ]
    if not content_words:
        return page_height

    content_bottom = max(word['y_max'] for word in content_words)
    return min(content_bottom + 16.0, page_height)


def compute_mask_boxes(
    *,
    page_width: float,
    page_height: float,
    words: list[dict],
    crop_bottom: float,
    image_width: int,
    image_height: int,
    padding: float = 2.0,
) -> list[tuple[int, int, int, int]]:
    scale_x = image_width / page_width
    scale_y = image_height / page_height
    x_padding = padding * scale_x
    y_padding = padding * scale_y
    boxes = []
    for word in words:
        if not should_mask_word(word['text']):
            continue
        if word['y_min'] >= crop_bottom:
            continue
        left = max(0, int((word['x_min'] * scale_x) - x_padding))
        top = max(0, int((word['y_min'] * scale_y) - y_padding))
        right = min(image_width, int((word['x_max'] * scale_x) + x_padding))
        bottom = min(image_height, int((word['y_max'] * scale_y) + y_padding))
        if left < right and top < bottom:
            boxes.append((left, top, right, bottom))
    return boxes


def should_mask_word(text: str) -> bool:
    categories = [
        unicodedata.category(char)
        for char in text.strip()
        if not char.isspace()
    ]
    if not categories:
        return False
    if any(category[0] in {'L', 'M', 'N'} for category in categories):
        return True
    return all(category[0] == 'P' for category in categories)


def convert_pdf_to_clean_png(pdf_path: Path, output_path: Path) -> None:
    with tempfile.TemporaryDirectory() as tmp_dir_name:
        tmp_dir = Path(tmp_dir_name)
        bbox_path = tmp_dir / 'page.bbox.html'
        png_base = tmp_dir / 'page'

        subprocess.run(
            ['pdftotext', '-bbox-layout', str(pdf_path), str(bbox_path)],
            check=True,
        )
        subprocess.run(
            [
                'pdftocairo',
                '-png',
                '-transp',
                '-singlefile',
                str(pdf_path),
                str(png_base),
            ],
            check=True,
        )

        png_candidates = sorted(tmp_dir.glob('page*.png'))
        png_path = png_base.with_suffix('.png')
        if not png_candidates and png_path.exists():
            png_candidates = [png_path]
        if not png_candidates:
            raise FileNotFoundError(f'No PNG generated for {pdf_path}')
        png_path = png_candidates[0]

        page_width, page_height, words = extract_words_from_bbox_html(
            bbox_path.read_text(),
        )
        crop_bottom = compute_crop_bottom(page_height, words)
        image = Image.open(png_path).convert('RGBA')
        for box in compute_mask_boxes(
            page_width=page_width,
            page_height=page_height,
            words=words,
            crop_bottom=crop_bottom,
            image_width=image.width,
            image_height=image.height,
        ):
            image.paste((0, 0, 0, 0), box)

        crop_height = max(1, round((crop_bottom / page_height) * image.height))
        image.crop((0, 0, image.width, crop_height)).save(
            output_path,
            format='PNG',
        )


def import_song_score(songbook: dict, song_number: str) -> bool:
    song_page_url = search_song_page(song_number)
    song_title = songbook['erdelyi'][song_number]['title']
    if song_page_url is None:
        song_page_url = fallback_search_song_page(song_number, song_title)
    if song_page_url is None:
        return False

    pdf_links = get_pdf_links(song_page_url)
    if not pdf_links:
        return False

    output_path = SCORES_DIR / f'referdelyi-{song_number.zfill(3)}-001.png'
    with tempfile.TemporaryDirectory() as tmp_dir_name:
        tmp_pdf = Path(tmp_dir_name) / 'score.pdf'
        with urllib.request.urlopen(pdf_links[0], timeout=30) as response:
            tmp_pdf.write_bytes(response.read())

        convert_pdf_to_clean_png(tmp_pdf, output_path)

    song = songbook['erdelyi'][song_number]
    song['hasScore'] = True
    song['scoreFiles'] = [f'assets/referdelyi/{output_path.name}']
    return True


def apply_shared_score_aliases(songbook: dict) -> None:
    erdelyi = songbook['erdelyi']
    for song_number, source_number in SHARED_SCORE_ALIASES.items():
        source_song = erdelyi.get(source_number)
        target_song = erdelyi.get(song_number)
        if source_song is None or target_song is None:
            continue
        if isinstance(target_song.get('scoreFiles'), list) and target_song['scoreFiles']:
            continue
        if source_song.get('hasScore') is not True:
            continue
        target_song['hasScore'] = True
        if source_song.get('scoreFiles') is not None:
            target_verse_count = len(target_song.get('texts', []))
            target_song['scoreFiles'] = list(source_song['scoreFiles'][:target_verse_count])


def refresh_song_scores(
    songbook: dict,
    song_numbers: list[str],
    *,
    importer=import_song_score,
) -> tuple[list[str], list[str]]:
    imported = []
    failed = []
    for song_number in song_numbers:
        try:
            success = importer(songbook, song_number)
        except Exception as exc:
            print(f'Failed {song_number}: {exc}', file=sys.stderr)
            success = False
        if success:
            imported.append(song_number)
        else:
            failed.append(song_number)
    return imported, failed


def refresh_missing_notes_file(songbook: dict) -> list[str]:
    missing = []
    for song_number, song in songbook['erdelyi'].items():
        if song.get('hasScore') is False:
            missing.append(f'{song_number}\t{song["title"]}')
    MISSING_NOTES_PATH.write_text('\n'.join(missing) + ('\n' if missing else ''))
    return missing


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--songs',
        nargs='*',
        help='Explicit Erdélyi song numbers to refresh.',
    )
    parser.add_argument(
        '--refresh-existing-scored',
        action='store_true',
        help='Refresh every Erdélyi song that already has a score.',
    )
    parser.add_argument(
        '--rebuild-generated-verse-svgs',
        action='store_true',
        help='Rebuild verse-specific Erdélyi SVGs from the checked-in source SVGs.',
    )
    args = parser.parse_args()

    songbook = load_songbook()
    imported = []
    failed = []
    if not args.rebuild_generated_verse_svgs:
        song_numbers = song_numbers_for_import(
            songbook,
            args.songs,
            refresh_existing_scored=args.refresh_existing_scored,
        )
        imported, failed = refresh_song_scores(songbook, song_numbers)

    apply_generated_verse_svgs(songbook)
    apply_shared_score_aliases(songbook)
    write_songbook(songbook)
    missing = refresh_missing_notes_file(songbook)

    print(f'Imported {len(imported)} songs.')
    if failed:
        print(f'Failed: {", ".join(failed)}')
    print(f'Remaining missing notes: {len(missing)}')
    return 0 if not failed else 1


if __name__ == '__main__':
    raise SystemExit(main())
