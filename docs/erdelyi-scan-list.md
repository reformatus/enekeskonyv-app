# Erdélyi — pages to check in the physical songbook

Every song needing a look at the real book, numeric order.
Legend after the list explains each tag.

- 059 — TEXT-DIVERGE
- 160 — PROSE-PAGE
- 163 — NO-SCORE
- 164 — NO-SCORE
- 177 — REF48-FALLBACK
- 178 — NO-SCORE
- 180 — NO-SCORE
- 183 — REF48-FALLBACK
- 188 — NO-SCORE
- 193 — PROSE-PAGE
- 206 — REF48-FALLBACK (v4/v6 wording variants — confirm)
- 207 — PROSE-PAGE
- 219 — SHARED-MELODY (uses 407's sheet)
- 226 — NO-SCORE
- 229 — PROSE-PAGE
- 231 — TEXT-LONGER
- 241 — NO-SCORE
- 262 — NO-SCORE
- 266 — NO-SCORE
- 268 — NO-SCORE
- 270 — SHARED-MELODY (uses 089's sheet)
- 271 — SHARED-MELODY (uses 152's sheet)
- 272 — SHARED-MELODY (uses 337's sheet)
- 274 — SHARED-MELODY (uses 135's sheet)
- 275 — SHARED-MELODY (uses 065's sheet)
- 276 — NO-SCORE
- 280 — REF48-FALLBACK
- 281 — NO-SCORE
- 283 — REF48-FALLBACK
- 288 — REF48-FALLBACK
- 289 — NO-SCORE
- 304 — REF48-FALLBACK
- 308 — TEXT-LONGER
- 309 — TEXT-LONGER
- 324 — REF48-FALLBACK
- 326 — TEXT-LONGER
- 328 — REF48-FALLBACK
- 329 — NO-SCORE
- 334 — TEXT-LONGER (~10 syllables unprinted)
- 335 — REF48-FALLBACK
- 338 — REF48-FALLBACK (renumbered in 1948 book)
- 343 — PROSE-PAGE
- 349 — REF48-FALLBACK
- 351 — NO-SCORE
- 357 — REF48-FALLBACK
- 359 — NO-SCORE
- 377 — NO-SCORE
- 383 — REF48-FALLBACK
- 387 — TEXT-LONGER
- 396 — REF48-FALLBACK
- 405 — REF48-FALLBACK (v7 cropped — confirm full text)
- 406 — WRONG-SCORE (underlay is a different hymn)
- 412 — TEXT-LONGER
- 420 — NO-SCORE
- 427 — SHARED-MELODY (uses 407's sheet)
- 428 — TEXT-LONGER
- 431 — NO-SCORE
- 432 — NO-SCORE
- 437 — NO-SCORE
- 439 — NO-SCORE
- 441 — NO-SCORE
- 444 — NO-SCORE
- 445 — NO-SCORE
- 446 — NO-SCORE
- 448 — NO-SCORE
- 451 — NO-SCORE
- 452 — NO-SCORE
- 453 — NO-SCORE
- 454 — NO-SCORE
- 455 — NO-SCORE
- 457 — NO-SCORE
- 462 — NO-SCORE
- 464 — NO-SCORE
- 466 — NO-SCORE
- 468 — NO-SCORE
- 469 — NO-SCORE
- 472 — NO-SCORE
- 473 — TEXT-LONGER
- 478 — NO-SCORE
- 479 — NO-SCORE
- 483 — NO-SCORE
- 484 — PROSE-PAGE
- 485 — VERIFY-FIX (confirm v2/v3 line pairing matches print)
- 488 — NO-SCORE
- 489 — NO-SCORE
- 490 — NO-SCORE
- 492 — NO-SCORE
- 493 — NO-SCORE
- 494 — NO-SCORE
- 495 — NO-SCORE
- 496 — NO-SCORE
- 498 — NO-SCORE
- 499 — NO-SCORE
- 500 — NO-SCORE
- 501 — NO-SCORE
- 502 — NO-SCORE
- 503 — NO-SCORE
- 504 — GENERIC-BLOCK

**Total: 98 songs** (56 no-score + 16 ref48 + 7 shared + 6 prose + 12 text issues + 1 generic)

## Tags

- **NO-SCORE** — no score in the app at all. Scan the page so a score can be added.
- **REF48-FALLBACK** — no Erdélyi scan existed; the app falls back to the 1948
  hymnal's sheet (possibly renumbered/cropped). Scan the Erdélyi page to replace it.
- **SHARED-MELODY** — app shows another song's sheet. Confirm the print really
  says "az alábbi dallamra / a N. ének dallamára" pointing at that melody.
- **PROSE-PAGE** — app detects the page as pure text (no staff/notation).
  Confirm the physical page really has no melody.
- **TEXT-LONGER** — the app's verse text has more syllables than the printed
  underlay provides slots for; the tail renders as an extra italic line.
  Check whether the print uses a shorter edition / different translation /
  repeated refrain.
- **TEXT-DIVERGE** — print seems to underlay a different translation/variant
  (only ~2 lines match). Confirm which text belongs to the printed melody.
- **WRONG-SCORE** — printed underlay is a different hymn ("Te-ben-ned bí-zom,
  én Is-te-nem") than the Erdélyi verse ("Tebenned bízni, Ó, áldott Istenség").
  Likely a wrong source page — verify.
- **GENERIC-BLOCK** — 504's text sits in a generic block the analyzer can't
  confidently classify. Check whether the page has a melody at all.
- **VERIFY-FIX** — already fixed; scan only to confirm the fix matches print.

## Global note (not per-song)

Many scores bake the `:/:` verse-repeat marker literally into the lyrics
(~120 songs, e.g. 358). That's a code-side wart fixable without the book —
the print carries repeats in the notation itself.
