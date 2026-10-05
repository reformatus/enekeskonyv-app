# Református Énekeskönyv (21/48)

<p align="center">
<a href='https://play.google.com/store/apps/details?id=com.github.reformatus.enekeskonyv'><img style='height: 83px' alt='Szerezd meg: Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/hu_badge_web_generic.png'/></a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://apps.apple.com/us/app/reform%C3%A1tus-%C3%A9nekesk%C3%B6nyv-21-48/id1661694803" style="width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/hu-hu?size=250x83&amp;releaseDate=1672272000" alt="Download on the App Store" style="width: 250px; height: 83px;"></a>
</p>

[![Codemagic build status](https://api.codemagic.io/apps/6527e63278135eff64eca3a7/6527e63278135eff64eca3a6/status_badge.svg)](https://codemagic.io/apps/6527e63278135eff64eca3a7/6527e63278135eff64eca3a6/latest_build)

A 21-es (kék) és 48-as (fekete) református énekeskönyv:
- minden ének minden verséhez kottával (kikapcsolható),
- ugrás énekre,
- keresés az énekversek szövegében,
- világos/sötét mód, külön az alkalmazásra és a kottára,
- teljesen offline működés

## Complete Local Build

The Flutter app lives in this repository. The sister repositories under the
organization are used for content and conversion work:
- `reformatus/enekeskonyv`: source text/docs for the legacy books
- `reformatus/convert-scripts`: import and score-splitting utilities

They are useful when regenerating content, but they are not required to compile
the Flutter app itself.

One important exception: the repo does not currently track the legacy
`assets/ref21/*.svg` and `assets/ref48/*.svg` score packs. Without them, the app
still builds, but the old songbooks will fall back to verse text instead of
showing scores.

To restore the official legacy score assets into a local checkout, run:

```bash
tool/restore_official_scores.sh /path/to/com.github.reformatus.enekeskonyv.apk
```

Or, if the official app is installed on a connected Android device:

```bash
tool/restore_official_scores.sh
```

The same applies to the generated Erdélyi verse scores: the repo tracks the
`assets/referdelyi/*-001.svg` source sheets, while the per-verse
`assets/referdelyi/*-v*.svg` files are generated and intentionally untracked
(they are large and reproducible). Without them the app still builds, but
Erdélyi songs fall back to verse text. To generate them on a fresh checkout:

```bash
python3 tool/import_reformatus_scores.py --rebuild-generated-verse-svgs
```

(needs `fontTools` and `pyphen`; see `tool/README.md`).

[Adatvédelmi irányelvek](PRIVACY.md)

<sup><sub>A Google Play és a Google Play-logó a Google LLC védjegyei.<br />Apple logo® and App Store® are trademarks of Apple Inc., registered in the U.S. and other countries.</sub></sup>
