/// user_db_helper.dart — The user's own data.
///
/// This is a SECOND, writable database (`user_data.db`), kept completely
/// separate from the bundled read-only seed database (`starter.db`).
/// That separation is the whole point: when a newer seed ships, the app
/// re-copies the bundled database, and nothing the user built —
/// favorites and their own items — can be wiped by the update.
///
/// Tables:
///   favorites  — starred items: (item_id, kind), kind 'bundled' for a
///                  seed row or 'user' for one of the user's own items.
///                  The two id spaces collide (both AUTOINCREMENT from
///                  1), so the kind is part of the key — bundled id 5
///                  and user id 5 can both be starred at once.
///   user_items — items the user adds themselves.
///
/// Schema history:
///   v1 — Initial release: favorites + user items.
library;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'item.dart';

class UserDatabaseHelper {
  UserDatabaseHelper._privateConstructor();
  static final UserDatabaseHelper instance =
      UserDatabaseHelper._privateConstructor();

  static const String _dbName = 'user_data.db';

  /// Current user-database schema version.
  static const int kUserDbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Absolute path of the user database file on disk.
  Future<String> get databasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  /// Close the open database handle. The next access re-opens it.
  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    return openDatabase(
      dbPath,
      version: kUserDbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            item_id INTEGER NOT NULL,
            kind TEXT NOT NULL,
            added_at TEXT NOT NULL,
            PRIMARY KEY (item_id, kind)
          )
        ''');
        await db.execute('''
          CREATE TABLE user_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT,
            description TEXT,
            details TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  String _now() => DateTime.now().toIso8601String();

  // ----- Favorites -----
  //
  // [kind] is 'bundled' for a seed item or 'user' for one of the
  // user's own items, and defaults to 'bundled' so every bundled
  // call site keeps working unchanged.

  Future<bool> isFavorite(int itemId, {String kind = 'bundled'}) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      columns: ['item_id'],
      where: 'item_id = ? AND kind = ?',
      whereArgs: [itemId, kind],
    );
    return rows.isNotEmpty;
  }

  Future<Set<int>> favoriteIds({String kind = 'bundled'}) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      columns: ['item_id'],
      where: 'kind = ?',
      whereArgs: [kind],
    );
    return rows.map((r) => r['item_id'] as int).toSet();
  }

  /// Favorited user-item ids (kind 'user').
  Future<Set<int>> favoriteUserIds() => favoriteIds(kind: 'user');

  Future<void> toggleFavorite(int itemId, {String kind = 'bundled'}) async {
    final db = await database;
    if (await isFavorite(itemId, kind: kind)) {
      await db.delete(
        'favorites',
        where: 'item_id = ? AND kind = ?',
        whereArgs: [itemId, kind],
      );
    } else {
      await db.insert('favorites', {
        'item_id': itemId,
        'kind': kind,
        'added_at': _now(),
      });
    }
  }

  // ----- The user's own items -----

  Future<List<Item>> getUserItems() async {
    final db = await database;
    final rows = await db.query(
      'user_items',
      orderBy: 'title COLLATE NOCASE',
    );
    return rows.map((m) => Item.fromMap(m, source: 'user')).toList();
  }

  /// Distinct categories the user has filed their own items under.
  /// The item form's category picker offers these alongside the
  /// seed database's categories.
  Future<List<String>> getUserCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM user_items '
      'WHERE category IS NOT NULL ORDER BY category COLLATE NOCASE',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<int> addUserItem(Item item) async {
    final db = await database;
    return db.insert(
        'user_items', item.toMap()..['created_at'] = _now());
  }

  Future<void> updateUserItem(Item item) async {
    final db = await database;
    if (item.id == 0) return;
    // toMap() carries no created_at, so the original timestamp survives.
    final values = item.toMap()..remove('id');
    await db.update(
      'user_items',
      values,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteUserItem(int id) async {
    final db = await database;
    // Its star goes with it — a dangling 'user' favorite row would
    // never render (it joins against user_items), but there is no
    // reason to keep it.
    await db.delete(
      'favorites',
      where: "item_id = ? AND kind = 'user'",
      whereArgs: [id],
    );
    await db.delete('user_items', where: 'id = ?', whereArgs: [id]);
  }
}
