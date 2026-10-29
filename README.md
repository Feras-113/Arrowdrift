# Arrowdrift

A polished arrow-escape puzzle for Android, built with Flutter.
Tap an arrow to slide it off the board — if something blocks it, you lose a heart. Clear the board to win.

* **5,100 levels**, four tiers (Easy 1–1000 · Medium 1001–2500 · Hard 2501–4000 · Expert 4001–5100)
* **Every level is solvable** – levels are generated backwards from a solution and re-verified by an independent solver (Python at generation time, Dart in `flutter test`)
* **Helpers:** Hint, Undo, Skip (earn via rewarded ads or coins)
* **AdMob:** adaptive banner, interstitial (paced), rewarded, plus Google UMP consent
* Progress, coins, themes saved locally · English + Arabic (RTL) · 4 themes · sound + haptics

## Quick start

```bash
flutter pub get
flutter test            # engine + all 5,100 levels + UI flow
flutter run             # uses Google TEST ads
```

## Level generation

```bash
python3 tool/gen_levels.py      # rewrites assets/levels/*.json (deterministic)
```
The shipped levels are committed; `flutter test` re-verifies all 5,100 of them on every CI run.

## Before you publish (checklist)

1. **Application id** – change `com.arrowdrift.game` in `android/app/build.gradle.kts` (`namespace` + `applicationId`) and move `MainActivity.kt` to match. It cannot be changed after the first upload.
2. **AdMob** – create your app + 3 ad units (banner, interstitial, rewarded) in the AdMob console, then build with:
   ```bash
   flutter build appbundle --release \
     --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/1111111111 \
     --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/2222222222 \
     --dart-define=ADMOB_REWARDED_ID=ca-app-pub-XXXX/3333333333 \
     -PADMOB_APP_ID=ca-app-pub-XXXX~YYYYYYYYYY
   ```
   (Without these the game uses Google's **test** ads — never click real ads yourself.)
3. **Signing** – create a keystore and `android/key.properties`:
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=C:/path/to/upload-keystore.jks
   ```
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   (both files are git-ignored – never commit them).
4. **Version** – bump `version:` in `pubspec.yaml` for every upload.
5. **Play Console** – privacy policy URL (host `PRIVACY_POLICY.md`, e.g. GitHub Pages), Data safety form (advertising ID via AdMob), "Contains ads", content rating, listing text in `store/LISTING.md`, icon + feature graphic in `store/`.
6. Closed testing: new personal developer accounts must run a closed test (12+ testers, 14 days) before production access.

## Project layout

```
lib/game/        pure game logic (board, tiers, level loader)
lib/services/    progress (persistence), ads (AdMob + UMP), sound/haptics
lib/ui/          screens, dialogs, board painter, widgets
assets/levels/   52 chunked JSON files, 100 levels each
tool/            level generator, icon generator, screenshot harness
```

## License / trademarks
Arrowdrift is an original game. It is not affiliated with any other title.
