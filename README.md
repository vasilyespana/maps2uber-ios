# Map2Ride for iOS

Native iOS port of [Map2Ride](https://maps2uber.vasilyespana.workers.dev/) (formerly Maps2Uber) — paste a Google Maps link, get ride links to that exact spot. Independent app; not affiliated with or sponsored by any ride provider.

**What it does:** paste a Google Maps link → the app resolves it via the worker's `/api/resolve` endpoint → you get a link to the exact spot in your chosen ride provider **plus 10 probe links on a 100 m circle** to compare fares / detect zone boundaries. Every probe row carries **two** links — your main provider and a second provider you pick in Settings (defaults: Uber + Lyft) — so price comparison is one tap. Map pins keep a single tap to the main provider.

**Providers:** Uber, Lyft, Bolt, FreeNow, Grab, Gett, DiDi (Waymo, Zoox and Baidu Apollo Go are listed as "coming soon" — they publish no destination deep linking yet). Same catalog, same link formats as the Android app.

## 💰 Why 100 meters can save you real money

Ride providers don't price by the exact meter — they price by **zones**. Two pickup points just 100 meters apart can fall on different sides of a zone boundary, and the fare can jump significantly. Real proof from Condado, San Juan: **$9.32 vs $11.37** for the same ride — **$2.05 (22%) saved** with a one-minute walk.

## Install (free, no Apple Developer account needed)

Apple's App Store requires a $99/year developer membership, so Map2Ride for iOS is distributed free through the sideloading channel — full step-by-step in **[INSTALL-FREE.md](INSTALL-FREE.md)**:

1. **SideStore source (recommended)** — install SideStore once (see the guide), add this source, and both Map2Ride and CallPages appear with one-tap installs and updates:
   `https://raw.githubusercontent.com/vasilyespana/maps2uber-ios/main/apps.json`
2. **Direct IPA** — download the IPA from [GitHub Releases](../../releases) and install it with SideStore / AltStore / Sideloadly.

## Build

Built with XcodeGen from `project.yml` — no checked-in `.xcodeproj`. GitHub Actions (`ios-build.yml`, macOS) runs unit tests and produces the unsigned IPA on every PR and push to `main`; pushing a `v*` tag also attaches the IPA to a GitHub Release.

## Source of truth

GitHub releases are the source of truth. Every release publishes the IPA used by all distribution channels, and `apps.json` (the SideStore/AltStore source feed) points at those release files.
