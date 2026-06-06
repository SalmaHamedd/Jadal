import 'package:equatable/equatable.dart';

import 'debate_results.dart';
import 'people.dart';
import 'team.dart';

enum DebateLifecycle { upcoming, live, past }

extension DebateLifecycleArabic on DebateLifecycle {
  String get arabicLabel => switch (this) {
        DebateLifecycle.upcoming => 'قادمة',
        DebateLifecycle.live => 'مباشرة الآن',
        DebateLifecycle.past => 'منتهية',
      };
}

class Debate extends Equatable {
  final String id;
  final String title;
  final String motionFramework;
  final DebateLifecycle status;
  final DateTime scheduledAt;
  final Team governmentTeam;
  final Team oppositionTeam;
  final Judge judge;
  final Coach coach;
  final DebateResults? results;
  final String venue;

  const Debate({
    required this.id,
    required this.title,
    required this.motionFramework,
    required this.status,
    required this.scheduledAt,
    required this.governmentTeam,
    required this.oppositionTeam,
    required this.judge,
    required this.coach,
    this.results,
    this.venue = 'قاعة المناظرات الرئيسية',
  });

  @override
  List<Object?> get props => [
        id,
        title,
        motionFramework,
        status,
        scheduledAt,
        governmentTeam,
        oppositionTeam,
        judge,
        coach,
        results,
        venue,
      ];
}
