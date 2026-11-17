/// item.dart — One row of the starter kit's data: a single item.
///
/// An [Item] comes from one of two places, and [source] says which:
/// 'bundled' items ship with the app in the read-only seed database
/// (assets/starter.db, copied on first launch by [DatabaseHelper]),
/// while 'user' items are ones the user added themselves, kept in the
/// separate writable user database ([UserDatabaseHelper]). The two id
/// spaces collide (both AUTOINCREMENT from 1), so anywhere an id is
/// stored — favorites, for example — the source travels with it.
///
/// Keep the model flat and boring on purpose: title, category,
/// description, details. A buyer shapes it into their own domain by
/// renaming the fields and adding columns to both databases.
library;

class Item {
  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? details;

  /// 'bundled' for a seed-database row, 'user' for one the user added.
  final String source;

  /// When a user item was created (ISO 8601). Null for bundled items.
  final String? createdAt;

  const Item({
    required this.id,
    required this.title,
    this.category,
    this.description,
    this.details,
    this.source = 'bundled',
    this.createdAt,
  });

  /// True for an item the user added themselves.
  bool get isUserItem => source == 'user';

  factory Item.fromMap(Map<String, dynamic> m, {String source = 'bundled'}) =>
      Item(
        id: m['id'] as int,
        title: m['title'] as String,
        category: m['category'] as String?,
        description: m['description'] as String?,
        details: m['details'] as String?,
        source: source,
        createdAt: m['created_at'] as String?,
      );

  /// Map for writing a user item. Bundled items are never written —
  /// the seed database is read-only.
  Map<String, dynamic> toMap() => {
        if (id != 0) 'id': id,
        'title': title,
        'category': category,
        'description': description,
        'details': details,
      };

  /// A copy with new field values (used by the edit form).
  Item copyWith({
    int? id,
    String? title,
    String? category,
    String? description,
    String? details,
    String? source,
    String? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      details: details ?? this.details,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
