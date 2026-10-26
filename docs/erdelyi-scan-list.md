# Erdélyi songbook — pages to compare against the physical hymnbook

Generated: 2026-10-26, branch `feature/erdelyi-glyph-lyrics-lean`.

The app's score images are rebuilt from the 1948 printed hymnbook scans.
For the songs below the imported source cannot be verified against the
Erdélyi verse text automatically — each entry says exactly what to look
at in the physical book and what to report back.

Legend for "what to scan":
- **underlay** = the syllabified lyric line printed under the staff
- **verse block** = the numbered verse paragraphs printed below the score

## A. Suspected wrong or mismatched score source

These three need the most careful check — the printed sheet may be a
different hymn/translation than the Erdélyi text.

### 406 — Tebenned bízni, Ó, áldott Istenség!
- **Suspect:** wrong score. The imported sheet (printed no. 71) carries
  the underlay "Te-ben-ned bí-zom, én Is-te-nem…" — a *different hymn's
  first line*, not this song's verse.
- **Scan:** the printed page for Erdélyi 406. Confirm its incipit is
  "Tebenned bízni, Ó, áldott Istenség!" and the melody matches, or that
  406 shares a melody with another song and the sheet's own underlay
  belongs to that other song.

### 485 — Íme, lészen a kései korban
- **Suspect:** the sheet's dash/dot underlay has fewer note slots than
  the Erdélyi verse — the last line "Aki vágyik az Úrra, betérhet."
  never gets notes and renders as overflow. The printed underlay's line
  order may also differ from the app verse.
- **Scan:** the printed 485 page — compare every sung underlay line
  word-by-word against the app verse, note whether the final line is
  printed under notation at all, and check for a repeat sign that would
  cover it.

### 59 — Szabadíts meg engem, Úr Isten
- **Suspect:** different translation/variant. Printed underlay (no. 140)
  reads "A gonosz, csalárd embertől; / Őrizz erőszaktevők ellen, /
  Ments meg a vakmerő néptől!" — the Erdélyi verse instead continues
  "És tarts meg ellenségim ellen!…". ~2 lines per verse don't fit.
- **Scan:** printed 59. Check whether the physical underlay matches
  "És tarts meg ellenségim ellen! / Mentsd meg azoktól életem…" or the
  variant shown above.

## B. Underlay shorter than the verse text (extra tail words)

The app's verse has more sung syllables than the printed sheet has note
slots; the surplus is rendered as a small tail line under the last
staff. Scan the printed page and check whether the physical underlay
really ends where our detection says — or whether a printed lyric row /
repeat sign was missed.

| Song | Missing tail (verse 1) | What to check |
|------|------------------------|----------------|
| 231  | "intnek." (v2), "várja." (v4) | last sung line vs underlay end |
| 308  | "Add ránk békességed!" | litany structure — the third "Istennek Báránya" invocation may be printed once and meant to repeat |
| 309  | "mint megterhelt gálya." (every verse loses ~5 words) | whether the underlay's last line covers the full printed verse or the Erdélyi verse is longer |
| 326  | "lehet." (v5) | tail of verse 5 |
| 334  | "hálát az ég nagy Istenének." (all verses) | refrain line — printed once at the end vs repeated per verse in the book |
| 387  | several lines per verse | whether the physical underlay matches "Dicsértessél, Atya Isten…" throughout |
| 412  | "szánk.", "ez életen.", "volt." | underlay end of each verse |
| 428  | "imádkozni!" | final word vs printed underlay |
| 473  | "kell.", "vár." | tail words |

## C. Text-only pages (no staff notation — verified intentional)

These sheets are prose/reference pages — the app renders the verse as
text, which is correct. Scan only to confirm the physical page really
has no 5-line staff (i.e. nothing was lost in scanning):

- **160** — "Szent Isten, noha néked" (melody reference page)
- **193** — "Dicsőség az Istennek"
- **207** — "Ez esztendőt áldással"
- **229** — "E húsvét ünnepében örvendjünk, keresztyének"
- **343** — "Mi Atyánk, ó, kegyes Isten" (prose prayer)
- **484** — "Fenn a mennyben az Úr minden győztesnek ád" (prose, references printed 626)

## D. ref48-fallback sheets surgically corrected

These songs had no Erdélyi scan; their sheets come from the ref48
hymnal. Automated surgery was applied — verify against the physical
Erdélyi book that the correction is faithful:

- **338** — verses 6–13: ref48 sheet printed sparse verse numbers
  (9, 10, 15, 18–22); they were rewritten to 6.–13. Check the book's
  actual verse numbering.
- **405 v7** — ref48 sheet appends a 2-line doxology ("Adj mindvégig
  megmaradást / És idvességes kimúlást!") the Erdélyi edition lacks;
  it was cropped. Check whether the book's 405 v7 ends at "i-géd-ből."
- **206 v4/v6** — ref48 text has edition-level word variants
  (e.g. "országunkra" vs "szolgáidra"); same verse and melody were
  kept. Scan if exact Erdélyi wording matters.

## E. Verified-fixed defects (no scan needed, phone-verified)

- **471** — orphaned "csupán." now sits under its note; the
  "A Golgotán:" refrain label row is restored.
- **485** — no longer renders as overlapping prose; lyrics align to the
  dash/dot notation (but see A.485 for the line-order question).
- Printed-number strip: 273 sheets no longer show the misleading 1948
  number (e.g. 491≠422, 414≠222, 353≠196, 484≠626, 151≠202, 358≠206).
