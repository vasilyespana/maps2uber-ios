# Maps2Uber for iOS

Native iOS port of [Maps2Uber](https://maps2uber.vasilyespana.workers.dev/) — share a Google Maps pin, get Uber deep links.

**What it does:** paste a Google Maps link → the app resolves it via the worker's `/api/resolve` endpoint → produces one Uber deep link to the exact spot **plus 10 probe links on a 100 m circle** to compare fares / detect zone boundaries.

## 💰 Why 100 meters can save you real money

Uber doesn't price your ride by the exact meter — it prices by **zones**. Two pickup points just 100 meters apart can fall on different sides of a zone boundary, and the fare can jump significantly. Real proof from Condado, San Juan: **$9.32 vs $11.37** for the same ride — **$2.05 (22%) saved** with a one-minute walk.

## Install (free, no Apple Developer account needed)

Apple's App Store requires a $99/year developer membership, so Maps2Uber for iOS is distributed free through these channels:

1. **AltStore** (recommended) — add the Maps2Uber source in AltStore, then install with one tap. AltStore signs the app with your free Apple ID.
2. **TrollStore** — download the IPA from [GitHub Releases](../../releases) and open it in TrollStore (no revokes, no PC needed on supported iOS versions).
3. **Sideloadly** — download the IPA from [GitHub Releases](../../releases) and sideload with your free Apple ID.

## Build

Push a `v*` tag and GitHub Actions builds an unsigned IPA on macOS automatically (`ios-build.yml`). Built with XcodeGen from `project.yml` — no checked-in `.xcodeproj`.

## Source of truth

GitHub releases are the source of truth. Every release publishes the IPA used by all distribution channels.
