/// main.dart — Offline Starter home screen.
///
/// Live search across the whole collection, filter by category,
/// browse by category. Tap any item for its detail page. The user's
/// own items (from the separate user database) are merged into the
/// results with a "My item" badge, seed rows carry a favorite star,
/// and the + button adds a new item of your own.
library;

import 'package:flutter/material.dart';

import 'category_items_page.dart';
import 'db_helper.dart';
import 'item.dart';
import 'item_detail.dart';
import 'item_form.dart';
import 'theme.dart';
import 'user_db_helper.dart';

void main() {
  runApp(const OfflineStarterApp());
}

class OfflineStarterApp extends StatelessWidget {
  const OfflineStarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Starter',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = DatabaseHelper.instance;
  final _userDb = UserDatabaseHelper.instance;
  final _searchController = TextEditingController();

  List<Item> _items = [];
  List<Item> _userItems = [];
  Set<int> _favoriteBundledIds = {};
  Set<int> _favoriteUserIds = {};
  List<String> _topCategories = [];
  String? _category; // null = all categories
  bool _favoritesOnly = false;
  bool _loading = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final total = await _db.countItems();
    final q = _searchController.text.trim();

    List<Item> results;
    if (_category != null) {
      results = await _db.getByCategory(_category!);
      if (q.isNotEmpty) {
        results = results
            .where((item) =>
                matchesWordStart(item.title, q) ||
                matchesWordStart(item.category, q) ||
                matchesWordStart(item.description, q) ||
                matchesWordStart(item.details, q))
            .toList();
      }
    } else if (q.isNotEmpty) {
      results = await _db.search(q);
    } else {
      results = await _db.getAll();
    }

    // Favorites and the user's own items, filtered by the same
    // query / category rules as the seed results so the two lists
    // behave as one.
    final favBundled = await _userDb.favoriteIds();
    final favUser = await _userDb.favoriteUserIds();
    final userItems = (await _userDb.getUserItems()).where((item) {
      if (_category != null && item.category != _category) return false;
      if (_favoritesOnly && !favUser.contains(item.id)) return false;
      if (q.isEmpty) return true;
      return matchesWordStart(item.title, q) ||
          matchesWordStart(item.category, q) ||
          matchesWordStart(item.description, q) ||
          matchesWordStart(item.details, q);
    }).toList();
    if (_favoritesOnly) {
      results = results.where((e) => favBundled.contains(e.id)).toList();
    }

    final categoryRows = await _db.getCategories();
    if (!mounted) return;
    setState(() {
      _items = results;
      _userItems = userItems;
      _favoriteBundledIds = favBundled;
      _favoriteUserIds = favUser;
      _topCategories = categoryRows
          .map((r) => r['category'] as String)
          .take(6)
          .toList();
      _totalCount = total;
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
    _refresh();
  }

  Future<void> _addItem() async {
    final created = await showItemFormDialog(context);
    if (created == null) return;
    await _userDb.addUserItem(created);
    _refresh();
  }

  Future<void> _openCategories() async {
    final rows = await _db.getCategories();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryListPage(categories: rows),
      ),
    );
    // Category pages carry favorite stars; keep the home stars in sync.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const PlumAppBarBackground(),
        title: const Text('Offline Starter'),
        actions: [
          IconButton(
            icon: Icon(
              _favoritesOnly ? Icons.star : Icons.star_border,
              color: _favoritesOnly ? AppColors.gold : null,
            ),
            tooltip: _favoritesOnly
                ? 'Show all items'
                : 'Show favorites only',
            onPressed: () {
              setState(() => _favoritesOnly = !_favoritesOnly);
              _refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Browse by category',
            onPressed: _openCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add your own item',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: 'Search items, categories…',
                filled: true,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _refresh();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          // Category shortcut row: the biggest categories first,
          // plus "More" for the full list. Always visible — a browse
          // shortcut, not a filter.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                for (final c in _topCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CategoryChip(
                      category: c,
                      onTap: () => openCategoryItems(context, c),
                    ),
                  ),
                ActionChip(
                  label: const Text(
                    'More',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.25),
                  ),
                  onPressed: _openCategories,
                ),
              ],
            ),
          ),
          if (_category != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Chip(
                    backgroundColor: categoryColor(_category),
                    side: BorderSide.none,
                    label: Text(
                      _category!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    deleteIconColor: Colors.white,
                    onDeleted: () {
                      setState(() => _category = null);
                      _refresh();
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loading
                    ? ''
                    : _userItems.isEmpty
                        ? '${_items.length} of $_totalCount items'
                        : '${_items.length} of $_totalCount items'
                            ' · ${_userItems.length} of yours',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty && _userItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 10),
                            const Text('No items match.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _userItems.length + _items.length,
                        itemBuilder: (context, i) {
                          // The user's own items come first, badged.
                          if (i < _userItems.length) {
                            return _itemTile(_userItems[i]);
                          }
                          return _itemTile(
                              _items[i - _userItems.length]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(Item item) {
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
          subtitle: item.category == null && item.description == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category != null) ...[
                      CategoryChip(
                        category: item.category!,
                        onTap: () =>
                            openCategoryItems(context, item.category!),
                      ),
                      const SizedBox(height: 3),
                    ],
                    if (item.description != null)
                      Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
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
                tooltip:
                    isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => _toggleFavorite(item),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => ItemDetailPage(item: item),
                ),
              )
              .then((_) => _refresh()),
        ),
      ),
    );
  }
}

class CategoryListPage extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const CategoryListPage({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const PlumAppBarBackground(),
        title: const Text('Categories'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final name = categories[i]['category'] as String;
          final count = categories[i]['c'] as int;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Card(
              child: ListTile(
                leading: CategoryDot(category: name, size: 16),
                title: Text(name),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                // Straight to this category's full item list.
                onTap: () => openCategoryItems(context, name),
              ),
            ),
          );
        },
      ),
    );
  }
}
