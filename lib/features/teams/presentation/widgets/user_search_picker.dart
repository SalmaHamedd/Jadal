import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';
import 'package:jadal_app/features/search/domain/repositories/search_repository.dart';

/// A debounced "search users by name, tap to pick" field, backed by the same
/// `/search` endpoint the search tab uses. Selection lives with the caller —
/// this widget only reports taps via [onSelected] and hides anyone whose id
/// is in [excludeIds] (already picked) from the results.
class UserSearchPicker extends StatefulWidget {
  final Set<int> excludeIds;
  final ValueChanged<SearchUser> onSelected;
  final String? hintText;

  const UserSearchPicker({
    super.key,
    this.excludeIds = const {},
    required this.onSelected,
    this.hintText,
  });

  @override
  State<UserSearchPicker> createState() => _UserSearchPickerState();
}

class _UserSearchPickerState extends State<UserSearchPicker> {
  final SearchRepository _repository = SearchRepositoryImpl();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<SearchUser> _results = const [];
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
    final result = await _repository.search(query: query);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (data) => setState(() {
        _loading = false;
        _results = data.$1;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleResults = _results
        .where((u) => !widget.excludeIds.contains(u.id))
        .toList();

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
            hintText: widget.hintText ?? context.loc.userSearchHint,
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
        else if (_controller.text.trim().isNotEmpty && visibleResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              context.loc.noResults,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: JadalColors.judgesGrey),
            ),
          )
        else if (visibleResults.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 8),
              itemCount: visibleResults.length,
              itemBuilder: (context, index) {
                final user = visibleResults[index];
                return _UserResultTile(
                  user: user,
                  onTap: () {
                    widget.onSelected(user);
                    setState(() {
                      _results = _results
                          .where((u) => u.id != user.id)
                          .toList();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final SearchUser user;
  final VoidCallback onTap;

  const _UserResultTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Builder(builder: (context) {
              // Resolved avatar URL + deterministic initial color.
              final url = resolveMediaUrl(user.avatarUrl);
              return CircleAvatar(
                radius: 16,
                backgroundColor: userAvatarColor(user.id),
                backgroundImage: url != null ? NetworkImage(url) : null,
                child: url == null
                    ? Text(
                        user.name.isEmpty
                            ? '?'
                            : user.name.characters.first.toUpperCase(),
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: userAvatarForeground(userAvatarColor(user.id)),
                        ),
                      )
                    : null,
              );
            }),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: isDark
                      ? JadalColors.darkTextPrimary
                      : JadalColors.lightTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: JadalColors.primaryOrange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
