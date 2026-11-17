/// db_helper.dart — Loads the bundled seed database and serves queries.
///
/// On first launch the prebuilt database is copied out of the app
/// bundle (assets/starter.db) into the app's documents folder, and
/// re-copied whenever [kBundledDbVersion] increases (ship a newer
/// seed database by bumping that number and replacing the asset).
///
/// The seed database is opened READ-ONLY. User data (favorites and
/// the user's own items) lives in a separate writable database
/// ([UserDatabaseHelper]) so a seed update can never wipe a user's
/// own content. That separation is the whole point of the two-database
/// design — keep it when you shape this kit into your own app.
library;

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'item.dart';

/// Word-start match — the ONE search rule for the whole app.
///
/// True when [keyword] starts a word in [text]: the keyword may
/// continue a word ("drill" matches "drilling") but may not hide
/// inside one ("ill" matches nothing in "drill"). Used by
/// [DatabaseHelper.search] and by the home screen's filters, so the
/// rule can't drift apart again. An empty keyword matches everything
/// (the callers' "no query means no filtering" behaviour); a null
/// field never matches.
bool matchesWordStart(String? text, String keyword) {
  final trimmed = keyword.trim();
  if (trimmed.isEmpty) return true;
  if (text == null) return false;
  return RegExp(r'\b' + RegExp.escape(trimmed), caseSensitive: false)
      .hasMatch(text);
}

/// Bump this when shipping an updated bundled database.
const int kBundledDbVersion = 1;

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const String _dbName = 'starter.db';
  static const String _table = 'items';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    final versionPath = p.join(dir.path, 'starter.version');
    final dbFile = File(dbPath);
    final versionFile = File(versionPath);

    int storedVersion = 0;
    if (await versionFile.exists()) {
      storedVersion =
          int.tryParse((await versionFile.readAsString()).trim()) ?? 0;
    }

    if (!await dbFile.exists() || storedVersion < kBundledDbVersion) {
      // Copy (or refresh) the bundled database.
      final data = await rootBundle.load('assets/$_dbName');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await dbFile.writeAsBytes(bytes, flush: true);
      await versionFile.writeAsString('$kBundledDbVersion', flush: true);
    }

    return openDatabase(dbPath, readOnly: true);
  }

  Future<int> countItems() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return result.first['c'] as int;
  }

  /// All bundled items, ordered by category, then title.
  Future<List<Item>> getAll() async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'category COLLATE NOCASE, title COLLATE NOCASE',
    );
    return rows.map((m) => Item.fromMap(m, source: 'bundled')).toList();
  }

  /// Keyword search across title, category, description, and details.
  ///
  /// The SQL LIKE is kept as a fast coarse pre-filter, then rows are
  /// kept only when the keyword starts a word in at least one searched
  /// field. A plain substring match would let "ill" hit "drill" —
  /// those are not the same word.
  Future<List<Item>> search(String keyword) async {
    final db = await database;
    final trimmed = keyword.trim();
    final q = '%$trimmed%';
    final rows = await db.query(
      _table,
      where: '(title LIKE ? OR category LIKE ? '
          'OR description LIKE ? OR details LIKE ?)',
      whereArgs: [q, q, q, q],
      orderBy: 'category COLLATE NOCASE, title COLLATE NOCASE',
    );
    final items =
        rows.map((m) => Item.fromMap(m, source: 'bundled')).toList();
    if (trimmed.isEmpty) return items;
    bool matches(Item item) => <String?>[
          item.title,
          item.category,
          item.description,
          item.details,
        ].any((field) => matchesWordStart(field, trimmed));
    return items.where(matches).toList();
  }

  /// Categories with item counts, biggest first.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.rawQuery(
      'SELECT category, COUNT(*) AS c FROM $_table '
      'WHERE category IS NOT NULL GROUP BY category ORDER BY c DESC, category',
    );
  }

  Future<List<Item>> getByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title COLLATE NOCASE',
    );
    return rows.map((m) => Item.fromMap(m, source: 'bundled')).toList();
  }
}
