# Installing Map2Ride (and CallPages) on your iPhone — the free way

No App Store, no $99 developer account. You install the apps with a
free tool called **SideStore** that signs them with **your own Apple
ID**. The signing happens on your own computer and phone — your Apple
ID is typed only into the tools on your own devices, never into our
website, never sent to us.

This one setup installs **both** of our iPhone apps — **Map2Ride**
and **CallPages** — from a single source feed, with updates in the
same place.

*Facts in this guide verified against the tools' official
documentation on 2026-10-11. Where something could not be verified,
it says so.*

## ⚠️ First, one version warning — read this before installing anything

> **SideStore 0.6.4 (the current "stable") is BROKEN for sign-in. DO
> NOT USE it.** In September 2026 Apple changed its sign-in servers,
> and 0.6.4 and earlier can no longer sign in (you'll see an HTTP 503
> error — it is *not* your password). The SideStore project itself
> labels that release "DO NOT USE."
>
> **Install the current nightly / 0.7.0-alpha build instead** — it
> contains Apple's-server fix. On **iOS 26.4 or later the nightly is
> also required for refreshing** to work. A nightly sounds scary; here
> it is simply the project's own prescribed build right now, until a
> fixed stable ships.

## The honest trade-offs (Apple's free-signing rules, not ours)

- **The apps' signatures last 7 days.** SideStore shows a countdown.
  Before it hits 0 you "refresh" the apps — about 30 seconds, and the
  daily automation below can do it for you.
- **If the 7 days lapse, the apps won't open** until you refresh them.
  Nothing is deleted and **your data is not lost** — refresh, never
  delete, and the apps come right back with everything in them.
- **Maximum 3 apps** installed this way on one phone — and SideStore
  itself counts as one of the three. **SideStore + CallPages +
  Map2Ride = 3 of 3: the free limit is exactly full.** Installing a
  fourth sideloaded app means removing one of these first.
- **Maximum 10 app IDs** per free account per week. Our two apps use
  two; this only matters if you sideload many different apps.
- **Each person needs their own Apple ID + tool.** This channel is
  perfect for you and a few testers; it is not a way to ship to
  hundreds of customers (that's what the App Store is for).

## What you need

1. Your iPhone (both apps need iOS 17 or newer).
2. An Apple ID for signing. **Use a dedicated second Apple ID, not
   your main iCloud account** — create a free one just for
   sideloading. It does **not** need to be the account signed into the
   iPhone. A separate account means a sign-in lockout or a revoked
   certificate can never touch your real account.
3. A computer (Windows, Mac, or Linux) and a USB cable — **one time
   only**, for setup.
4. A Wi-Fi network (SideStore installs and refreshes over Wi-Fi, not
   cellular).

## One-time setup — SideStore via iloader (~15–30 minutes)

**iloader** is the small official installer that puts SideStore on
your phone from the computer. After this setup, the computer is out
of the picture.

1. **On the iPhone:** open the App Store and install **LocalDevVPN**
   (it's free; it's the local VPN SideStore uses to install apps
   on-device). Open it once so it's ready.
2. **On the computer:** download **iloader** — only from its official
   GitHub repo (github.com/nab138/iloader) or iloader.app. (Windows:
   if iloader asks for Apple's iTunes drivers, install them as its
   instructions direct.)
3. Connect the iPhone to the computer by USB, unlock it, and tap
   **Trust** if the phone asks.
4. Open iloader, sign in with your **dedicated secondary Apple ID**
   (approve the 2-factor prompt on your device if Apple asks), select
   your iPhone, and choose **Install SideStore** — picking the
   **nightly / 0.7.0 build**, not 0.6.4 (see the warning above).
   iloader also places the pairing file SideStore needs.
5. **On the iPhone:** Settings → General → VPN & Device Management →
   under *Developer App*, tap the entry named for your Apple ID →
   **Trust** (on iOS 18+ this reads "Allow & Restart"). Enter your
   passcode if asked.
6. Settings → Privacy & Security → **Developer Mode** → turn it **On**.
   The phone restarts; after it does, confirm **Turn On**.
7. Open **LocalDevVPN** and tap **Connect** (allow the VPN
   configuration if prompted). Keep it connected whenever you install
   or refresh apps.
8. Open **SideStore** and sign in with the **same secondary Apple ID**
   you used in iloader.
9. In SideStore → **My Apps**, tap the **"7 DAYS"** counter next to
   SideStore itself to refresh it once (if it asks to create or revoke
   a signing certificate, tap Yes / Refresh Now). **Do this before
   installing any app** — this first refresh fixes SideStore's own
   registration, and installing first can make apps disappear.
   Setup is done.

## Installing the apps — add the source once, both apps appear

1. Make sure you're on Wi-Fi and **LocalDevVPN shows Connected**.
2. In **SideStore**, open **Sources**, tap **+** (Add Source), and
   paste this URL:

   ```
   https://raw.githubusercontent.com/vasilyespana/maps2uber-ios/main/apps.json
   ```

3. The source lists **Map2Ride** and **CallPages Merchant**. Tap
   **GET** / install on each — SideStore signs them with your free
   certificate and they appear on your Home Screen like normal apps.
4. **Updating later:** new versions show up in the same source;
   install the update over the top — **never delete the old app
   first**, updating keeps all your data.

*Prefer files?* Each app's IPA is also attached to its GitHub
Releases (Map2Ride: this repo's Releases, `v…` tags; CallPages: the
callpages repo's Releases, `ios-v…` tags). Download the IPA to Files,
then SideStore → My Apps → **+** → pick the file.

## Your weekly routine (under a minute)

- Before the counter in My Apps reaches 0: connect LocalDevVPN, open
  SideStore → My Apps → **Refresh All** — this refreshes SideStore
  *and both apps* in one pass. Done.
- **Make it automatic (recommended):** in the Shortcuts app, create a
  Personal Automation that runs **once a day** (for example, when the
  phone starts charging at night) with these actions: *LocalDevVPN →
  Connect* → *SideStore → Refresh All Apps* → *LocalDevVPN →
  Disconnect*, set to run immediately without asking. Then all that's
  left is glancing at the counters once in a while.
- SideStore also *tries* to refresh in the background by itself —
  treat that as a bonus, not a guarantee. The automation above is the
  reliable pattern.
- **If an app has already expired:** don't delete it. Wi-Fi +
  LocalDevVPN + **Refresh All** brings it back, data intact.

## Alternates (work fine, but the computer stays involved)

- **AltStore Classic** — the source feed above is in the standard
  AltStore source format, so it works there too (Browse → Sources →
  add the same URL). Install AltServer from **altstore.io** on your
  computer (on Windows, iTunes/iCloud must come directly from Apple,
  not the Microsoft Store), install AltStore to the phone over USB,
  then add the source. The catch: refreshing needs **AltServer
  running on your computer on the same Wi-Fi** (or the phone plugged
  in) — if the computer is asleep or away that week, the apps expire.
  Also use a current AltServer (1.7.6+): the same September 2026
  Apple change broke sign-in in older builds. *(One detail still
  unverified: whether current macOS AltServer still needs its Mail
  plug-in for wireless refresh — check AltStore's FAQ if you take
  this path.)*
- **Sideloadly** — from **sideloadly.io** only. The simplest first
  install of all: connect the phone by USB, drag the IPA into
  Sideloadly, enter your Apple ID, click **Start**, then do the Trust
  and Developer Mode steps on the phone. The catch is the same as
  AltStore's: its auto-refresh helper only works when your computer
  is on and the phone is reachable by Wi-Fi/USB, so a week away from
  the computer means expired apps until you re-run it.
- **AltStore PAL is not an option here** — it exists only in the EU,
  Japan, and Brazil, and it cannot install IPA files at all.

## Troubleshooting

- **Sign-in fails with "503"** → you're on SideStore 0.6.4 or an old
  AltServer. Update to the nightly / 0.7.0 build (or AltServer
  1.7.6+). It was never your password.
- **"App is no longer available" / app won't open** → the 7 days ran
  out. Refresh (SideStore: Refresh All on Wi-Fi with LocalDevVPN
  connected). Data is intact.
- **Refresh suddenly fails** → check Wi-Fi and that LocalDevVPN is
  connected first. On iOS 26.4+, confirm you're on the nightly build.
- **Pairing file errors** → the pairing file can expire after an iOS
  update or a phone reset (occasionally at random). Reconnect the
  phone to the computer by USB and run iloader again to place a fresh
  one, then refresh.
- **"Maximum number of apps"** → you already have 3 sideloaded apps
  (SideStore counts, and Map2Ride + CallPages fill the other two).
  Remove one inside SideStore, then install.
- **Untrusted Developer** → do the Trust step: Settings → General →
  VPN & Device Management.
- **Apple ID got locked** → this can happen (a temporary lock, cleared
  by Apple's password/verification flow). It's one more reason to use
  the dedicated secondary account, so your main account is never
  involved.

## Safety rules (non-negotiable)

- **Official sources only.** SideStore: **sidestore.io** and
  **docs.sidestore.io**; the app itself from the project's GitHub
  releases. iloader: its official GitHub repo or **iloader.app** —
  anywhere else is not official. AltStore: altstore.io. Sideloadly:
  **sideloadly.io** (lookalike sites such as "sideloadly.me" are NOT
  official). The app files: only the source feed above or the apps'
  own GitHub Releases pages.
- **Never upload a `.p12` file anywhere.** Any site or service that
  asks you to upload your signing certificate (`.p12`) or profile is
  asking for the keys to sign anything as you. No legitimate step in
  this guide ever needs it.
- **Ignore paid "lifetime certificate" offers** — and "free
  certificate" files, Telegram/Discord certificates, and online
  IPA-signing websites. Shared certificates get revoked in bulk, and
  "lifetime" certificates are a known scam pattern.
- Enter your Apple ID **only** inside SideStore / iloader / AltStore /
  Sideloadly on your own devices — never on a web page, never in chat,
  never send it to us. We never need it and will never ask.

---

*Currency note: the setup sequence, the 0.6.4 sign-in breakage and
nightly fix, the 3-app / 10-App-ID / 7-day limits, and the
pairing-file behavior above were verified against Apple's and the
projects' official documentation on 2026-10-11. Two things remain
genuinely unverified: (1) whether a fixed **stable** (non-nightly)
SideStore release has shipped since that date — check the project's
releases page and prefer a fixed stable if one exists; (2) whether
AltStore Classic's computer-free 2.3 version has reached general
public release — it was patron/RC-stage at verification time, so this
guide does not rely on it.*
