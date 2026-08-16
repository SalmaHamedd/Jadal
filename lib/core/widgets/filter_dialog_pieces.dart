import 'package:flutter/material.dart';

import '../localization/l10n/context_localiztion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A generic (id, label) option for the multi-select pieces below — shared by
/// every filter dialog (debate search, blog search) so they don't each
/// invent their own option shape.
class FilterOption {
  final String id;
  final String label;
  const FilterOption({required this.id, required this.label});
}

/// A titled group of selectable chips over a small, already-fetched option
/// list (formats, frameworks, debate tags, judges, teams, categories, tags,
/// publishers, statuses…). Multi-select: tapping a chip toggles it.
class MultiSelectChipGroup extends StatelessWidget {
  final String title;
  final List<FilterOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool loading;

  const MultiSelectChipGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.bodyEmphasis(context).copyWith(
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            )),
        const SizedBox(height: 6),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (options.isEmpty)
          Text(context.loc.filterNoneAvailable,
              style: AppTextStyles.caption(context).copyWith(color: JadalColors.judgesGrey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                FilterChip(
                  label: Text(o.label, style: AppTextStyles.caption(context)),
                  selected: selected.contains(o.id),
                  selectedColor: JadalColors.primaryOrange.withValues(alpha: 0.2),
                  checkmarkColor: JadalColors.primaryOrange,
                  onSelected: (v) {
                    final next = Set<String>.from(selected);
                    if (v) {
                      next.add(o.id);
                    } else {
                      next.remove(o.id);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// A user/judge-style picker with its own search-as-you-type field (the list
/// is too large to show all at once) — the caller supplies the async search
/// function (e.g. the existing `GET /search?q=`).
class SearchableMultiSelect extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<FilterOption>> Function(String query) onSearch;
  final Map<String, String> selectedLabels; // id -> label, so chips survive without a live search
  final ValueChanged<Map<String, String>> onChanged;

  const SearchableMultiSelect({
    super.key,
    required this.title,
    required this.hint,
    required this.onSearch,
    required this.selectedLabels,
    required this.onChanged,
  });

  @override
  State<SearchableMultiSelect> createState() => _SearchableMultiSelectState();
}

class _SearchableMultiSelectState extends State<SearchableMultiSelect> {
  final _controller = TextEditingController();
  List<FilterOption> _results = const [];
  bool _searching = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    final results = await widget.onSearch(q.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title,
            style: AppTextStyles.bodyEmphasis(context).copyWith(
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            )),
        const SizedBox(height: 6),
        if (widget.selectedLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in widget.selectedLabels.entries)
                  Chip(
                    label: Text(e.value, style: AppTextStyles.caption(context)),
                    onDeleted: () {
                      final next = Map<String, String>.from(widget.selectedLabels)..remove(e.key);
                      widget.onChanged(next);
                    },
                  ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                final isSelected = widget.selectedLabels.containsKey(r.id);
                return CheckboxListTile(
                  dense: true,
                  title: Text(r.label, style: AppTextStyles.body(context)),
                  value: isSelected,
                  onChanged: (v) {
                    final next = Map<String, String>.from(widget.selectedLabels);
                    if (v == true) {
                      next[r.id] = r.label;
                    } else {
                      next.remove(r.id);
                    }
                    widget.onChanged(next);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A from/to date range with two tappable fields opening the platform date
/// picker. Values are `YYYY-MM-DD` strings, matching what the backend wants.
class DateRangeField extends StatelessWidget {
  final String? from;
  final String? to;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  const DateRangeField({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
  });

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context, ValueChanged<String?> onChanged, String? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null ? (DateTime.tryParse(current) ?? DateTime.now()) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(_fmt(picked));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.loc.filterDateRangeLabel,
            style: AppTextStyles.bodyEmphasis(context).copyWith(
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            )),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(context, onFromChanged, from),
                child: Text(from ?? context.loc.filterFromLabel, style: AppTextStyles.caption(context)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pick(context, onToChanged, to),
                child: Text(to ?? context.loc.filterToLabel, style: AppTextStyles.caption(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
