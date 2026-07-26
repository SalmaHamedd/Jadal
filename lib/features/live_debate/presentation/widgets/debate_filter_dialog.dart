import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/filter_dialog_pieces.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/search/data/repositories/search_repository_impl.dart';

/// The filter dialog for debate search (§8) — fetches every option list on
/// open (formats, frameworks, distinct debate tags, judges, teams) and lets
/// the user multi-select each dimension, plus a searchable user picker and a
/// date range. "Motion tag" isn't offered — backend confirmed it isn't real
/// data (motion "tags" are just framework names mirrored flat).
class DebateFilterDialog extends StatefulWidget {
  final DebateSearchFilter initial;
  const DebateFilterDialog({super.key, required this.initial});

  @override
  State<DebateFilterDialog> createState() => _DebateFilterDialogState();
}

class _DebateFilterDialogState extends State<DebateFilterDialog> {
  late DebateSearchFilter _filter;
  bool _loadingOptions = true;

  List<FilterOption> _formats = const [];
  List<FilterOption> _frameworks = const [];
  List<FilterOption> _debateTags = const [];
  List<FilterOption> _judges = const [];
  List<FilterOption> _teams = const [];
  Map<String, String> _selectedUsers = {};

  static const _statusOptions = [
    FilterOption(id: 'scheduled', label: 'Scheduled'),
    FilterOption(id: 'announced', label: 'Announced'),
    FilterOption(id: 'teams-selected', label: 'Sides selected'),
    FilterOption(id: 'live', label: 'Live'),
    FilterOption(id: 'completed', label: 'Completed'),
    FilterOption(id: 'cancelled', label: 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final repo = di.sl<LiveDebateRepository>();
    final formatsRes = await repo.getDebateFormats();
    final frameworksRes = await repo.getMotionFrameworks();
    final tagsRes = await repo.getDebateTagsDistinct();
    final judgesRes = await repo.getJudgesList();
    final teamsRes = await repo.getTeamsOptions();
    if (!mounted) return;
    setState(() {
      formatsRes.fold((_) {}, (list) {
        _formats = [for (final f in list) FilterOption(id: '${f.id}', label: f.name ?? 'Format ${f.id}')];
      });
      frameworksRes.fold((_) {}, (list) {
        _frameworks = [for (final f in list) FilterOption(id: '${f.id}', label: f.name)];
      });
      tagsRes.fold((_) {}, (list) {
        _debateTags = [for (final t in list) FilterOption(id: t, label: t)];
      });
      judgesRes.fold((_) {}, (list) {
        _judges = [for (final j in list) FilterOption(id: '${j.id}', label: j.name)];
      });
      teamsRes.fold((_) {}, (list) {
        _teams = [for (final t in list) FilterOption(id: '${t.id}', label: t.name)];
      });
      _loadingOptions = false;
    });
  }

  Future<List<FilterOption>> _searchUsers(String q) async {
    final res = await SearchRepositoryImpl().search(query: q);
    return res.fold(
      (_) => const [],
      (tuple) => [for (final u in tuple.$1) FilterOption(id: '${u.id}', label: u.name)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter debates',
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
                        title: 'Status',
                        options: _statusOptions,
                        selected: _filter.status.toSet(),
                        onChanged: (s) => setState(() => _filter = _filter.copyWith(status: s.toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Format',
                        options: _formats,
                        loading: _loadingOptions,
                        selected: _filter.formatIds.map((e) => '$e').toSet(),
                        onChanged: (s) => setState(
                            () => _filter = _filter.copyWith(formatIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Motion framework',
                        options: _frameworks,
                        loading: _loadingOptions,
                        selected: _filter.frameworkIds.map((e) => '$e').toSet(),
                        onChanged: (s) => setState(
                            () => _filter = _filter.copyWith(frameworkIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Debate tag',
                        options: _debateTags,
                        loading: _loadingOptions,
                        selected: _filter.debateTags.toSet(),
                        onChanged: (s) => setState(() => _filter = _filter.copyWith(debateTags: s.toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Judge',
                        options: _judges,
                        loading: _loadingOptions,
                        selected: _filter.judgeIds.map((e) => '$e').toSet(),
                        onChanged: (s) =>
                            setState(() => _filter = _filter.copyWith(judgeIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      MultiSelectChipGroup(
                        title: 'Team',
                        options: _teams,
                        loading: _loadingOptions,
                        selected: _filter.teamIds.map((e) => '$e').toSet(),
                        onChanged: (s) =>
                            setState(() => _filter = _filter.copyWith(teamIds: s.map(int.parse).toList())),
                      ),
                      const SizedBox(height: 14),
                      SearchableMultiSelect(
                        title: 'User',
                        hint: 'Search users…',
                        onSearch: _searchUsers,
                        selectedLabels: _selectedUsers,
                        onChanged: (m) => setState(() {
                          _selectedUsers = m;
                          _filter = _filter.copyWith(userIds: m.keys.map(int.parse).toList());
                        }),
                      ),
                      const SizedBox(height: 14),
                      DateRangeField(
                        from: _filter.dateFrom,
                        to: _filter.dateTo,
                        onFromChanged: (v) => setState(() => _filter = _filter.copyWith(dateFrom: v)),
                        onToChanged: (v) => setState(() => _filter = _filter.copyWith(dateTo: v)),
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
                        _filter = const DebateSearchFilter();
                        _selectedUsers = {};
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
