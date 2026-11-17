# Setup — Footings

## Prerequisites

- **Flutter 3.5+** (this kit was built and verified with Flutter
  3.50.0, Dart 3.14.0). Install from
  <https://docs.flutter.dev/get-started/install>.
- **Android:** Android SDK with platform 36 and build-tools 36
  (`sdkmanager "platforms;android-36" "build-tools;36.0.0"`), plus
  a JDK 17 for Gradle builds.
- **iOS:** Xcode on a Mac. The iOS project is the standard
  `flutter create` output — no extra setup.
- No accounts or credentials are needed to run the lite kit.

## Run it

```sh
flutter pub get
flutter run
```

Or build a debug APK:

```sh
flutter build apk --debug
```

## Rename the package

The kit ships as `com.example.offline_starter` with the display
name "Footings". Both are placeholders — rename them before
you ship anything:

1. **Android:** in `android/app/build.gradle.kts`, change
   `namespace` and `applicationId` to your own reverse-domain id
   (e.g. `com.yourname.yourapp`). In
   `android/app/src/main/AndroidManifest.xml`, change
   `android:label` to your display name.
2. **iOS:** in `ios/Runner/Info.plist`, change
   `CFBundleDisplayName` (and `CFBundleName` if you want the
   bundle name to match). Set the bundle identifier in Xcode or in
   `ios/Runner.xcodeproj/project.pbxproj`
   (`PRODUCT_BUNDLE_IDENTIFIER`).
3. **Dart:** in `pubspec.yaml`, change `name:` to your package
   name, then update the imports (`package:offline_starter/...`)
   across `lib/` and `test/`.

## Swap in your own seed data

The bundled database is `assets/starter.db`, table `items`:

```sql
CREATE TABLE items (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT,
  description TEXT,
  details TEXT
);
```

Build your own with Python:

```python
import sqlite3
c = sqlite3.connect('starter.db')
c.execute('''CREATE TABLE items (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT,
  description TEXT,
  details TEXT
)''')
c.executemany(
    'INSERT INTO items VALUES (?,?,?,?,?)',
    [(1, 'First item', 'Category', 'A sentence.', 'Extra notes.'), ...])
c.commit()
```

Then drop it in as `assets/starter.db` (the path is declared in
`pubspec.yaml` under `flutter: assets:`) and bump
`kBundledDbVersion` in `lib/db_helper.dart` — the app re-copies the
bundled database whenever that number increases, so existing users
get your new seed without losing their own items. Keep the table
name `items` and the column names, or update the queries in
`lib/db_helper.dart` to match.

## Shape the model into your domain

- Rename `Item`'s fields in `lib/item.dart` (and the matching
  columns in both databases) to fit your data.
- Add columns the same way in both places: the seed table in
  `assets/starter.db`, and `user_items` in
  `lib/user_db_helper.dart` (bump `kUserDbVersion` and add the
  column in `onUpgrade` — never in `onCreate` alone, or existing
  installs won't get it).
- Categories are free text, not an enum: the category picker merges
  seed categories with the user's own, so new categories appear
  without code changes.

## Known quirks

- **compileSdk 36.** The Android build uses
  `flutter.compileSdkVersion` (36 with Flutter 3.50). If you add a
  plugin that hardcodes an older compileSdk in its own build file,
  prefer a plugin version that follows `flutter.compileSdkVersion`.
- **Java 17.** Gradle needs a JDK 17. If your build fails with a
  "major version" error, check `java -version` — older JDKs are the
  usual cause.
- **First launch copies the seed database.** If you change
  `assets/starter.db` during development and the app still shows
  old data, the copy in the app's documents folder is stale: bump
  `kBundledDbVersion` in `lib/db_helper.dart`, or uninstall the
  app to clear its documents folder.
- **The seed database is read-only at runtime.** The app opens it
  with `readOnly: true`. If you need to edit seed rows in code,
  edit the asset and bump the version — never write to the opened
  database.
