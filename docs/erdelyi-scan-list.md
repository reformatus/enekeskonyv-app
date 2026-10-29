# Erdélyi — physical-book verification results

145 photos of the printed Erdélyi hymnbook were compared against the app
(docs/images_tmp, 2026-10-29). App numbering matches the printed numbering
exactly (incl. H/-appendix entries). Three outcomes:

## RESOLVED — printed "Dallama a N." melody pointers now baked as aliases

These songs print only prose + a melody pointer in the book. The app now
generates their sheets from the pointed-to score (SHARED_SCORE_ALIASES):

- 160 → 208 · 163 → 35 · 164 → 75 · 178 → 278 · 180 → 75 · 183 → 79
- 188 → 201 (print: "201b. ének") · 193 → 208 · 206 → 353 · 207 → 208
- 219 → 407 · 229 → 208 · 241 → 194 · 266 → 75 · 268 → 204
- 270 → 42 (FIXED: was aliased to 89 — that is H/270's wedding hymn, a
  different song; regular print-270 points to psalm 42)
- 271 → 152 ("152a, 152b") · 272 → 337 · 274 → 135 · 275 → 65
- 280 → 66 · 281 → 81 · 288 → 42 · 289 → 134 · 304 → 303 · 324 → 38
- 343 → 337 · 349 → 89 · 351 → 403 · 357 → 150 · 359 → 407 · 383 → 379
- 396 → 375 · 420 → 415 · 427 → 407 · 431 → 38 · 432 → 42

Also confirmed by photo (already aliased or already correct):
161, 179, 220, 228, 263, 269, 352, 358, 426 print pointers too, but the
app's digitized source already carries a real staff with the correct
underlay for these — left as-is. 406's score is likewise correct (its
printed melody IS psalm-90's, matching the book's pointer to 90).

## VERIFIED — flagged issues confirmed correct in the book

- 485 — printed underlay pairs verse lines 1+3 under phrase 1 and 2+4
  under phrase 2, exactly as now baked (row 1 ends with a repeat sign).
- 334 — printed score carries 52 underlay slots; the app verse has 62
  syllables (refrain written out). The tail-line leftover is faithful.
- 504 — own score confirmed (Draskóczy László, p. 696).
- 59 — printed score underlays the app's verse text verbatim; the
  divergent source underlay noted earlier is edition-internal only.
- 309 — the book splits the song into 309a + 309b, both with own scores;
  the app carries a single 309 sheet (documented difference).
- 502 — printed underlay is bilingual HU+LA (dona nobis pacem); app
  carries the Hungarian rows.

## CANNOT FIX FROM PHOTOS — book has an own printed score but the
## digitized source has no -001.svg (needs engraving/vectorization)

177 · 226 · 262 · 276 · 283 · 329 · 335 · 338 · 377 · 405 · 437 · 439 ·
441 · 444 · 445 · 446 · 448 · 451 · 452 · 453 · 454 · 455 · 457 · 462 ·
464 · 466 · 468 · 469 · 472 · 478 · 479 · 483 · 484 · 488 · 489 · 490 ·
492 · 493 · 494 · 495 · 496 · 498 · 499 · 500 · 501 · 502 · 503

Notes:
- 484 is special: the digitized -001.svg is a prose page, but the book
  (p. 679) prints an own score — needs engraving, not an override.
- 177/283/335/338/405 currently fall back to 1948-hymnal sheets; the
  book's own melodies exist (Herman Miklós 1554; Debrecen 1774; Erfurt
  1521; Kodály Psalmus Hungaricus; B. Monoetius 1565) but are not in the
  digital source.
- 231/308/309/326/387/412/428/473 have digital app scores; the book
  confirms own scores exist. Residual underlay/verse-length differences
  are edition differences — tails render as overflow lines, acceptable.
- 308's book score is the Wittenberg-1523 Agnus Dei.

## Photo gaps (not blocking — no flagged song lacked needed evidence)

- Song 360's page (pp. 523–543 span) not photographed; the app already
  has a valid source for 360.
- Pages for 471, 475–477, 480–482, 487 not photographed; none flagged.
- Minor crops: p. 308 bottom (188 v-tail), p. 333 bottom (208's staff
  top), p. 480 left edge (328 verses), p. 635 right (448 v1). All
  flagged content still legible elsewhere or non-critical.

No retakes needed for the flagged set.
