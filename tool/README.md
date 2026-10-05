# Score asset pipeline

`import_reformatus_scores.py` turns the LilyPond-engraved source SVGs
(`assets/referdelyi/referdelyi-<song>-001.svg`, ref48 fallback under
`assets/ref48/`) into per-verse score assets
(`referdelyi-<song>-v<verse>.svg`) consumed by the song page.

For each verse the generator:

- detects lyric rows and note onsets in the source SVG (`detect_svg_lyric_blocks`,
  `_extract_note_onsets`, notehead-based recovery candidates),
- splits the verse text across rows with a DP that matches syllable counts
  to onset counts (`split_verse_text_by_note_counts`),
- bakes the lyrics as reusable glyph `<path>` definitions plus `<use>`
  references — no runtime font dependency — under a `generated-lyrics`
  group, with per-syllable `<clipPath>` bounds and `scale()`-based
  horizontal compression,
- removes the original verse-1 source lyrics, header furniture, and any
  revealed prose/page-2 content; grows the viewBox when real systems sit
  below the original crop.

Detection guards: lyric blocks must sit below the topmost staff line
(page headers like psalm lists never win block selection); rows that are
printed verse paragraphs (uniform ~12-unit spacing, no syllable hyphens)
are masked out; staff-less pages (e.g. prose chants) emit wrapped verse
text instead of syllable alignment.

`validate_onsets.py` cross-checks detected onset positions against the
publisher PDF text (`pdftotext -bbox-layout`).

## Generated assets are not tracked

Per-verse files (`referdelyi-*-v*.svg`) are gitignored — regenerate them
locally (needed for scores to display on a fresh checkout):

```bash
python3 tool/import_reformatus_scores.py --rebuild-generated-verse-svgs
```

requires `fontTools` and `pyphen` (`pip install fonttools pyphen`). The
syllabifier uses the publisher-extracted hyphenation dictionary vendored at
`tool/hyphen-dict.json` (a few extraction merges are patched via
`_HYPHEN_OVERRIDES`); pyphen is the fallback for unlisted words.

Songs without an erdelyi
source sheet fall back to matching ref48 scores; that pack is untracked
too (see `restore_official_scores.sh`). ref48 `ref48-<song>-NNN.svg`
files are already complete per-verse renders, so they pass through as
the verse assets unchanged (`copy_ref48_verse_svgs`), and the resulting
files for those sixteen songs stay committed so they always render.

`repair_score_sources.py` re-imports the erdelyi source sheets from the
publisher PDFs, anchoring each song's region on its printed-number
heading (`tool/printed_numbers.json` maps app numbers to printed
numbers) instead of trusting the site's URL numbering, and stitches
page-spanning scores into one `-001.svg`.

Run tests: `python3 -m unittest tool.import_reformatus_scores_test`.
