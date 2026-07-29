import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/teams/data/repositories/team_repository_impl.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/screens/team_info_screen.dart';
import 'package:jadal_app/features/teams/presentation/widgets/team_list_card.dart';

/// A debater's "find a team to join" browser — `GET /teams` for a debater
/// returns active, non-random teams they're not already on, and this lets
/// them search by name and tap through to [TeamInfoScreen] to submit a join
/// request.
class JoinableTeamsScreen extends StatefulWidget {
  const JoinableTeamsScreen({super.key});

  @override
  State<JoinableTeamsScreen> createState() => _JoinableTeamsScreenState();
}

class _JoinableTeamsScreenState extends State<JoinableTeamsScreen> {
  final TeamRepository _repository = TeamRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Team> _teams = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final query = _searchController.text.trim();
    final result = await _repository.getTeams(search: query.isEmpty ? null : query);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (teams) => setState(() {
        _loading = false;
        _teams = teams;
      }),
    );
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'انضم إلى فريق',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onQueryChanged,
                style: const TextStyle(fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فريق بالاسم...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? JadalColors.darkSurfaceElevated
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: JadalColors.judgesGrey),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ: $_error',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_teams.isEmpty) {
      return RefreshIndicator(
        color: JadalColors.primaryOrange,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'لا توجد فرق متاحة للانضمام حالياً',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: JadalColors.primaryOrange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          return TeamListCard(
            team: team,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamInfoScreen(
                    teamId: team.id,
                    teamName: team.name,
                    canJoin: true,
                    initialTeam: team,
                  ),
                ),
              );
              if (context.mounted) _load();
            },
          );
        },
      ),
    );
  }
}
