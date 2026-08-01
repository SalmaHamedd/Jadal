import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';

/// Pick a single debate to file a complaint about — debounced search by
/// title over `GET /debates/search`, matching the picker pattern used for
/// team member search. Selection lives with the caller.
class DebatePickerField extends StatefulWidget {
  final DebateListItem? selected;
  final ValueChanged<DebateListItem?> onChanged;

  const DebatePickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<DebatePickerField> createState() => _DebatePickerFieldState();
}

class _DebatePickerFieldState extends State<DebatePickerField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<DebateListItem> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(query.trim()),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await di.sl<LiveDebateRepository>().searchDebates(
      DebateSearchFilter(q: query),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (page) => setState(() {
        _loading = false;
        _results = page.items;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.selected;

    if (selected != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 18,
              color: JadalColors.primaryBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? JadalColors.darkTextPrimary
                      : JadalColors.lightTextPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => widget.onChanged(null),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onQueryChanged,
          style: AppTextStyles.body(context).copyWith(
            color: isDark
                ? JadalColors.darkTextPrimary
                : JadalColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: context.loc.debateSearchHint,
            hintStyle: AppTextStyles.body(
              context,
            ).copyWith(color: JadalColors.judgesGrey),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: isDark
                ? JadalColors.darkSurfaceElevated
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              context.loc.debateSearchFailed(_error ?? ''),
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: JadalColors.negativeRed),
            ),
          )
        else if (_controller.text.trim().isNotEmpty && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              context.loc.noResults,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: JadalColors.judgesGrey),
            ),
          )
        else if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 8),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final debate = _results[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => widget.onChanged(debate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 18,
                          color: JadalColors.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            debate.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
