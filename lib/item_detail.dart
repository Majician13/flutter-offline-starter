/// item_detail.dart — One item's detail page.
///
/// The header band shows the title and its category chip. Below it,
/// a Details card carries the description and the free-form details,
/// and a "More in this category" card lists up to 3 other items filed
/// under the same category. A favorite star lives in the AppBar,
/// backed by the separate user database ([UserDatabaseHelper]).
///
/// Items the user added themselves also get Edit and Delete actions
/// in the AppBar; bundled seed items are read-only and show neither.
library;

import 'package:flutter/material.dart';

import 'category_items_page.dart';
import 'db_helper.dart';
import 'item.dart';
import 'item_form.dart';
import 'theme.dart';
import 'user_db_helper.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final _db = DatabaseHelper.instance;
  final _userDb = UserDatabaseHelper.instance;

  late Item _item;
  bool _isFavorite = false;

  /// Up to 3 other items in the same category. Empty — and the
  /// section hidden — when this item has no category or is alone in it.
  List<Item> _related = [];

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadFavorite();
    _loadRelated();
  }

  Future<void> _loadFavorite() async {
    final fav = await _userDb.isFavorite(
      _item.id,
      kind: _item.isUserItem ? 'user' : 'bundled',
    );
    if (!mounted) return;
    setState(() => _isFavorite = fav);
  }

  Future<void> _loadRelated() async {
    final category = _item.category;
    if (category == null) return;
    final bundled = await _db.getByCategory(category);
    final user = (await _userDb.getUserItems())
        .where((i) => i.category == category)
        .toList();
    final others = [...bundled, ...user]
        .where((i) => !(i.id == _item.id && i.source == _item.source))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    if (!mounted) return;
    setState(() => _related = others.take(3).toList());
  }

  Future<void> _toggleFavorite() async {
    await _userDb.toggleFavorite(
      _item.id,
      kind: _item.isUserItem ? 'user' : 'bundled',
    );
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _edit() async {
    final edited = await showItemFormDialog(context, existing: _item);
    if (edited == null) return;
    await _userDb.updateUserItem(edited);
    if (!mounted) return;
    setState(() {
      _item = edited;
      _related = [];
    });
    _loadRelated();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('"${_item.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _userDb.deleteUserItem(_item.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const PlumAppBarBackground(),
        title: const Text('Item'),
        actions: [
          if (item.isUserItem) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit item',
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete item',
              onPressed: _delete,
            ),
          ],
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? AppColors.gold : null,
            ),
            tooltip: _isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header band: a subtle plum wash behind the title block,
          // with a thin gold rule along its foot.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.category != null)
                      CategoryChip(
                        category: item.category!,
                        onTap: () =>
                            openCategoryItems(context, item.category!),
                      ),
                    if (item.isUserItem) const MyItemBadge(),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionCard(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Details',
                  headerBackground: AppColors.plum,
                  headerForeground: AppColors.cream,
                  headerIconColor: AppColors.goldLight,
                  rows: const [],
                  bodyWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.description != null) Text(item.description!),
                      if (item.description != null &&
                          item.details != null)
                        const SizedBox(height: 8),
                      if (item.details != null)
                        Text(
                          item.details!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (item.description == null && item.details == null)
                        Text(
                          'No details yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // More in this category. Hidden when this item has
                // no category or is alone in it.
                if (item.category != null && _related.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    context,
                    icon: Icons.category_outlined,
                    title: 'More in ${item.category}',
                    headerBackground: AppColors.plum,
                    headerForeground: AppColors.cream,
                    headerIconColor: AppColors.goldLight,
                    rows: const [],
                    bodyWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final other in _related)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              other.isUserItem
                                  ? Icons.add_box_outlined
                                  : Icons.inventory_2_outlined,
                            ),
                            title: Text(other.title),
                            subtitle: other.description == null
                                ? null
                                : Text(
                                    other.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailPage(item: other),
                                  ),
                                )
                                .then((_) {
                              _loadFavorite();
                              _loadRelated();
                            }),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: Text('See all in ${item.category}'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => openCategoryItems(
                                context, item.category!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color headerBackground,
    required Color headerForeground,
    required Color headerIconColor,
    required List<(String, String)> rows,
    String? body,
    Widget? bodyWidget,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: headerBackground,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(icon, color: headerIconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: headerForeground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, value) in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            label.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (bodyWidget != null) ...[
                  const SizedBox(height: 6),
                  bodyWidget,
                ] else if (body != null) ...[
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
