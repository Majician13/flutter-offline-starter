# Footings

**Your app's foundation, poured and ready.**

A Flutter starter kit for an **offline-first** app: a bundled read-only
database copied on first launch, a separate writable user database,
favorites, word-start search, and categories. Everything works with no
account, no network, and no backend.

This is the **lite** version. The paid full version adds Google Drive
backup/restore (with export/import), on-device OCR scan-to-create, and
instruction photos. See [SETUP.md](SETUP.md) for how to rename the
package, swap in your own seed data, and build.

## What's included

- **Two databases, by design.** `assets/starter.db` is the bundled
  seed database: copied into the app's documents folder on first
  launch and opened read-only. `user_data.db` is the writable
  database for the user's own content. When you ship a newer seed,
  the app re-copies it — and nothing the user built is ever wiped by
  the update. That separation is the whole point; keep it.
- **Generic item model** (`lib/item.dart`): title, category,
  description, details, plus a `source` flag (`bundled` / `user`).
  Shape it into your own domain by renaming fields and adding
  columns to both databases.
- **Home screen** (`lib/main.dart`): live search, a category
  shortcut row, a favorites-only toggle, category browsing, and an
  add button. Seed items and the user's own items appear in one
  list, the user's first and badged "My item".
- **Item detail page** (`lib/item_detail.dart`): title, category
  chip, details card, "More in this category", favorite star, and —
  for the user's own items — edit and delete.
- **Add/edit form** (`lib/item_form.dart`): title, a searchable
  category picker (seed categories plus the user's own, with a "New
  category…" escape hatch), description, details.
- **Word-start search** (`lib/db_helper.dart`): the one search rule
  for the whole app — a keyword may start a word, it may not hide
  inside one ("drill" matches "drilling", "ill" matches nothing in
  "drill"). Pinned down by unit tests in `test/widget_test.dart`.
- **Plum/gold theme** (`lib/theme.dart`): light and dark, following
  the system brightness, with a stable color per category.

## The seed data

`assets/starter.db` ships with 12 demo items in 3 everyday
categories (Kitchen, Garage, Garden) — plain household items, there
to show the shape. Replace them with your own data; see SETUP.md.

## Project layout

```
lib/
  main.dart              Home screen (search, categories, favorites)
  item.dart              The generic Item model
  db_helper.dart         Bundled seed database (read-only)
  user_db_helper.dart    User database (favorites + own items)
  item_detail.dart       Detail page
  item_form.dart         Add/edit form + category picker
  category_items_page.dart  One category's full item list
  theme.dart             Palette, themes, category chips
assets/
  starter.db             Bundled seed database (12 demo items)
```

## How to run

```sh
flutter pub get
flutter run
```

Requires Flutter 3.5+ and Dart 3.5+. Android only needs the SDK;
iOS needs Xcode. See [SETUP.md](SETUP.md) for the full setup.

## What's in the paid full version

- **Google Drive backup/restore** — silent auto-backup to the
  app-data folder, plus manual export/import through the share
  sheet, with a backup manifest.
- **On-device OCR scan-to-create** — photograph a printed sheet
  and turn it into a new item, with a review screen and
  title-deduplication.
- **Instruction photos** — camera and gallery capture, stored per
  item and included in backup.

## License

MIT — see [LICENSE](LICENSE).
