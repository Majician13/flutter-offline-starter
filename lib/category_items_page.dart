/// category_items_page.dart — Category navigation: the full list of
/// items filed under one category, alphabetically.
///
/// Reached three ways: tapping a category in "Browse by category",
/// tapping the category chip on a home result row, and tapping the
/// category chip inside an item's detail page. Rows mirror the home
/// list: icon, title, description line, favorite star; tapping a row
/// opens the item's detail page. Seed items and the user's own items
/// appear together, the user's first and badged.
library;

import 'package:flutter/material.dart';

import 'db_helper.dart';
import 'item.dart';
import 'item_detail.dart';
import 'theme.dart';
import 'user_db_helper.dart';

/// Pushes the [CategoryItemsPage] for [category] onto the navigator.
void openCategoryItems(BuildContext context, String category) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryItemsPage(category: category),
    ),
  );
}

class CategoryItemsPage extends StatefulWidget {
  final String category;
  const CategoryItemsPage({super.key, required this.category});

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  final _db = DatabaseHelper.instance;
  final _userDb = UserDatabaseHelper.instance;

  List<Item> _items = [];
  Set<int> _favoriteBundledIds = {};
  Set<int> _favoriteUserIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bundled = await _db.getByCategory(widget.category);
    final user = (await _userDb.getUserItems())
        .where((i) => i.category == widget.category)
        .toList();
    final favBundled = await _userDb.favoriteIds();
    final favUser = await _userDb.favoriteUserIds();
    if (!mounted) return;
    setState(() {
      // The user's own items first, then the seed items.
      _items = [...user, ...bundled];
      _favoriteBundledIds = favBundled;
      _favoriteUserIds = favUser;
      _loading = false;
    });
  }

  bool _isFavorite(Item item) {
    return item.isUserItem
        ? _favoriteUserIds.contains(item.id)
        : _favoriteBundledIds.contains(item.id);
  }

  Future<void> _toggleFavorite(Item item) async {
    await _userDb.toggleFavorite(
      item.id,
      kind: item.isUserItem ? 'user' : 'bundled',
    );
    final favBundled = await _userDb.favoriteIds();
    final favUser = await _userDb.favoriteUserIds();
    if (!mounted) return;
    setState(() {
      _favoriteBundledIds = favBundled;
      _favoriteUserIds = favUser;
    });
  }

  Future<void> _reloadFavorites() async {
    final favBundled = await _userDb.favoriteIds();
    final favUser = await _userDb.favoriteUserIds();
    if (!mounted) return;
    setState(() {
      _favoriteBundledIds = favBundled;
      _favoriteUserIds = favUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const PlumAppBarBackground(),
        // Category name (with its color dot) over the item count.
        title: Row(
          children: [
            CategoryDot(category: widget.category, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFF3D6),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  if (!_loading)
                    Text(
                      _items.length == 1
                          ? '1 item'
                          : '${_items.length} items',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Nothing is filed under '
                          '"${widget.category}" yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final isFav = _isFavorite(item);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            item.isUserItem
                                ? Icons.add_box_outlined
                                : Icons.inventory_2_outlined,
                          ),
                          title: Text(item.title),
                          subtitle: item.description == null
                              ? null
                              : Text(
                                  item.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isUserItem) const MyItemBadge(),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? AppColors.gold : null,
                                ),
                                tooltip: isFav
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                onPressed: () => _toggleFavorite(item),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemDetailPage(item: item),
                                ),
                              )
                              .then((_) => _reloadFavorites()),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
