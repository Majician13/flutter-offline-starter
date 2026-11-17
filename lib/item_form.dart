/// item_form.dart — The shared add/edit form for the user's own
/// items, used by both the home screen's "add" flow and the item
/// page's "edit" flow so the two can never drift apart.
///
/// Category is picked, not typed — a searchable picker over the
/// seed database's categories plus any category the user already
/// files their own items under, with a "New category…" escape hatch.
/// Consistent categories keep user items visible to category
/// browsing.
library;

import 'package:flutter/material.dart';

import 'db_helper.dart';
import 'item.dart';
import 'theme.dart';
import 'user_db_helper.dart';

/// Shows the item form. With [existing] null it is the "add" form;
/// otherwise it edits that item. Returns the item to save, or null
/// when cancelled / the title is empty.
Future<Item?> showItemFormDialog(
  BuildContext context, {
  Item? existing,
}) {
  return showDialog<Item>(
    context: context,
    builder: (context) => _ItemFormDialog(existing: existing),
  );
}

class _ItemFormDialog extends StatefulWidget {
  final Item? existing;
  const _ItemFormDialog({this.existing});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _details;
  late String? _category;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _details = TextEditingController(text: item?.details ?? '');
    _category = item?.category;
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _orNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _pickCategory() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const CategoryPickerPage()),
    );
    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      Item(
        id: widget.existing?.id ?? 0,
        title: _title.text.trim(),
        category: _category,
        description: _orNull(_description),
        details: _orNull(_details),
        source: 'user',
        createdAt: widget.existing?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add your own item' : 'Edit item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Category is picked from the shared taxonomy, not typed,
            // so user items file alongside the seed items.
            InkWell(
              onTap: _pickCategory,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  suffixIcon: _category == null
                      ? const Icon(Icons.arrow_drop_down)
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear category',
                          onPressed: () =>
                              setState(() => _category = null),
                        ),
                ),
                child: _category == null
                    ? Text(
                        'Choose a category',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Row(
                        children: [
                          CategoryDot(category: _category),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _category!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What it is, in a sentence',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Anything worth remembering about it',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Searchable category picker: every category in the seed database
/// (with its item count) plus any category the user already files
/// their own items under — and a "New category…" escape hatch for
/// items that fit no existing heading. Pops with the chosen name.
class CategoryPickerPage extends StatefulWidget {
  const CategoryPickerPage({super.key});

  @override
  State<CategoryPickerPage> createState() => _CategoryPickerPageState();
}

class _CategoryPickerPageState extends State<CategoryPickerPage> {
  final _search = TextEditingController();
  List<({String name, int? count})>? _categories;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seedRows = await DatabaseHelper.instance.getCategories();
    final custom = await UserDatabaseHelper.instance.getUserCategories();
    final counts = <String, int>{
      for (final r in seedRows)
        r['category'] as String: (r['c'] as int?) ?? 0,
    };
    final names = <String>{...counts.keys, ...custom}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _categories = [
        for (final n in names) (name: n, count: counts[n]),
      ];
    });
  }

  Future<void> _newCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'e.g. Pantry',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Use category'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      Navigator.of(context).pop(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final filtered = categories
        ?.where((c) => c.name.toLowerCase().contains(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const PlumAppBarBackground(),
        title: const Text('Choose a category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('New category…'),
            subtitle: const Text('File it under a category of your own'),
            onTap: _newCategory,
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered == null
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text('No categories match your search.'),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          return ListTile(
                            leading: CategoryDot(category: c.name),
                            title: Text(c.name),
                            trailing: c.count == null
                                ? null
                                : Text('${c.count}'),
                            onTap: () =>
                                Navigator.of(context).pop(c.name),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
