import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/filter_dialog_pieces.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/blog_search_filter.dart';

/// The filter dialog for blog search (§10) — category (confirmed mapping of
/// the product's "framework" ask) + tag as equal, separate dimensions, plus
/// publisher and "liked by me". Mirrors [DebateFilterDialog]'s shape.
class BlogFilterDialog extends StatefulWidget {
  final BlogSearchFilter initial;
  const BlogFilterDialog({super.key, required this.initial});

  @override
  State<BlogFilterDialog> createState() => _BlogFilterDialogState();
}

class _BlogFilterDialogState extends State<BlogFilterDialog> {
  late BlogSearchFilter _filter;
  bool _loading = true;
  List<FilterOption> _categories = const [];
  List<FilterOption> _tags = const [];
  Map<String, String> _selectedPublisher = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final repo = BlogRepositoryImpl();
    final catRes = await repo.getCategories();
    final tagRes = await repo.getTags();
    if (!mounted) return;
    setState(() {
      catRes.fold((_) {}, (list) {
        _categories = [for (final c in list) FilterOption(id: '${c.id}', label: c.name)];
      });
      tagRes.fold((_) {}, (list) {
        _tags = [for (final t in list) FilterOption(id: '${t.id}', label: t.name)];
      });
      _loading = false;
    });
  }

  Future<List<FilterOption>> _searchAuthors(String q) async {
    final res = await BlogRepositoryImpl().getAuthors();
    return res.fold(
      (_) => const [],
      (list) => list
          .where((a) => a.name.toLowerCase().contains(q.toLowerCase()))
          .map((a) => FilterOption(id: '${a.id}', label: a.name))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter articles',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 17)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MultiSelectChipGroup(
                        title: 'Category',
                        options: _categories,
                        loading: _loading,
                        selected: _filter.categoryIds.map((e) => '$e').toSet(),
                        onChanged: (s) =>
                            setState(() => _filter = _filter.copyWith(categoryIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Tag',
                        options: _tags,
                        loading: _loading,
                        selected: _filter.tagIds.map((e) => '$e').toSet(),
                        onChanged: (s) =>
                            setState(() => _filter = _filter.copyWith(tagIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      SearchableMultiSelect(
                        title: 'Publisher',
                        hint: 'Search authors…',
                        onSearch: _searchAuthors,
                        selectedLabels: _selectedPublisher,
                        onChanged: (m) => setState(() {
                          _selectedPublisher = m.isEmpty ? {} : {m.keys.last: m.values.last};
                          _filter = _filter.copyWith(
                            publisherId: _selectedPublisher.isEmpty ? null : int.parse(_selectedPublisher.keys.first),
                            clearPublisher: _selectedPublisher.isEmpty,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Liked by me', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        value: _filter.likedByMe,
                        activeThumbColor: JadalColors.primaryOrange,
                        onChanged: (v) => setState(() => _filter = _filter.copyWith(likedByMe: v)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _filter = const BlogSearchFilter();
                        _selectedPublisher = {};
                      }),
                      child: const Text('Clear', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: JadalColors.primaryOrange),
                      onPressed: () => Navigator.pop(context, _filter),
                      child: const Text('Apply', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
