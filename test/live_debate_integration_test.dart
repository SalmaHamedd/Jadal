// Integration contract test for the live-debate feature.
//
// This does NOT hit the network — it feeds a representative `GET /live-state`
// `data` payload (shaped exactly as the backend confirmed in
// V4_BACKEND_RESPONSE_for_frontend.md) through the real Flutter models + derived
// views, and asserts every integration point the FE depends on parses correctly.
//
// If the backend ever changes one of these shapes, this test fails loudly before
// a live multi-device test wastes anyone's time.
import 'package:flutter_test/flutter_test.dart';

import 'package:jadal_app/features/live_debate/data/models/debate_models.dart';
import 'package:jadal_app/features/live_debate/data/models/debate_result_model.dart';
import 'package:jadal_app/features/live_debate/data/models/live_state_model.dart';
import 'package:jadal_app/features/live_debate/domain/debate_result_view.dart';
import 'package:jadal_app/features/live_debate/domain/debate_room_role.dart';
import 'package:jadal_app/features/live_debate/domain/debate_status.dart';

/// A realistic `live-state.data` in the **result phase**: speeches done
/// (`speeches_completed_at` set) but `status` still `live`; result submitted +
/// revealed; a 2-person prop team filling 3 slots via a duplicate in
/// `speaking_order`; a reply speaker flagged on the opposition.
Map<String, dynamic> _liveStateData() => {
      'debate': {
        'id': 71,
        'title': 'هل ينبغي تنظيم الذكاء الاصطناعي؟',
        'status': 'live', // V3 lifecycle: stays live through the result phase
        'current_stage': 7,
        'current_stage_started_at': null,
        'speeches_completed_at': '2026-06-27T09:40:59+00:00',
        'result_revealed_at': '2026-06-27T10:00:00+00:00',
      },
      'format': {
        'speakers_per_side': 3,
        'total_stages': 6,
        'has_reply_speech': false,
        'speech_time_seconds': 420,
      },
      'rooms': {
        'main': {'name': 'main_71', 'open': true, 'joinable_for_me': true, 'role_if_joined': 'judge_chair'},
        'prop': {'name': 'prop_71', 'open': false, 'joinable_for_me': false, 'role_if_joined': 'debater_speaker'},
        'opp': {'name': 'opp_71', 'open': false, 'joinable_for_me': false, 'role_if_joined': 'debater_member'},
        'result': {'name': 'result_71', 'open': true, 'joinable_for_me': true, 'role_if_joined': 'judge_chair'},
      },
      'judges': [
        {'id': 1, 'user': {'id': 16, 'name': 'حصة الدوسري'}, 'judge_order': 1, 'is_chair': true, 'is_attended': true},
        {'id': 2, 'user': {'id': 30, 'name': 'سعود'}, 'judge_order': 2, 'is_chair': false, 'is_attended': true},
      ],
      'proposition': {
        'team': {'id': 10, 'name': 'فريق الإثبات', 'members_count': 2},
        'is_random': false,
        'members': [],
        'speakers': [
          {'id': 40, 'user': {'id': 11, 'name': 'أحمد'}, 'side': 'proposition', 'speaking_phase_order': 1, 'is_reply_speaker': false, 'is_attended': true, 'is_chair': false},
          {'id': 41, 'user': {'id': 12, 'name': 'لينا'}, 'side': 'proposition', 'speaking_phase_order': 2, 'is_reply_speaker': false, 'is_attended': true, 'is_chair': false},
        ],
        // 2-person team, 3 slots → user 11 covers slots 1 AND 3 (multi-role).
        'speaking_order': [
          {'phase_order': 1, 'user_id': 11, 'participant_id': 40},
          {'phase_order': 2, 'user_id': 12, 'participant_id': 41},
          {'phase_order': 3, 'user_id': 11, 'participant_id': 40},
        ],
      },
      'opposition': {
        'team': {'id': 20, 'name': 'فريق النفي', 'members_count': 3},
        'is_random': false,
        'members': [],
        'speakers': [
          {'id': 50, 'user': {'id': 21, 'name': 'عمر'}, 'side': 'opposition', 'speaking_phase_order': 1, 'is_reply_speaker': false, 'is_attended': true, 'is_chair': false},
          {'id': 51, 'user': {'id': 23, 'name': 'سارة'}, 'side': 'opposition', 'speaking_phase_order': 2, 'is_reply_speaker': true, 'is_attended': true, 'is_chair': false},
          {'id': 52, 'user': {'id': 24, 'name': 'خالد'}, 'side': 'opposition', 'speaking_phase_order': 3, 'is_reply_speaker': false, 'is_attended': true, 'is_chair': false},
        ],
        'speaking_order': [
          {'phase_order': 1, 'user_id': 21, 'participant_id': 50},
          {'phase_order': 2, 'user_id': 23, 'participant_id': 51},
          {'phase_order': 3, 'user_id': 24, 'participant_id': 52},
        ],
      },
      'stages': [
        {'id': 100, 'order_index': 1, 'name': 'Proposition 1', 'is_reply': false, 'participant_id': 40, 'speaker_user_id': 11, 'duration_seconds': 420, 'status': 'completed'},
        {'id': 101, 'order_index': 2, 'name': 'Opposition 1', 'is_reply': false, 'participant_id': 50, 'speaker_user_id': 21, 'duration_seconds': 420, 'status': 'completed'},
        {'id': 102, 'order_index': 3, 'name': 'Proposition 2', 'is_reply': false, 'participant_id': 41, 'speaker_user_id': 12, 'duration_seconds': 420, 'status': 'completed'},
        {'id': 103, 'order_index': 4, 'name': 'Opposition 2', 'is_reply': false, 'participant_id': 51, 'speaker_user_id': 23, 'duration_seconds': 420, 'status': 'completed'},
        {'id': 104, 'order_index': 5, 'name': 'Proposition 3', 'is_reply': false, 'participant_id': 40, 'speaker_user_id': 11, 'duration_seconds': 420, 'status': 'completed'},
        {'id': 105, 'order_index': 6, 'name': 'Opposition 3', 'is_reply': false, 'participant_id': 52, 'speaker_user_id': 24, 'duration_seconds': 420, 'status': 'completed'},
      ],
      // Per-stage scores nest under scores.stages, not at the top level.
      'result': {
        'id': 5,
        'winning_side': 'proposition',
        'summary_notes': 'سيطرت الإثبات على نقطة الخلاف.',
        'scores': {
          'stages': [
            {'stage_order': 1, 'participant_id': 40, 'user_id': 11, 'score': 88},
            {'stage_order': 2, 'participant_id': 50, 'user_id': 21, 'score': 75},
            {'stage_order': 3, 'participant_id': 41, 'user_id': 12, 'score': 81},
            {'stage_order': 4, 'participant_id': 51, 'user_id': 23, 'score': 70},
            {'stage_order': 5, 'participant_id': 40, 'user_id': 11, 'score': 79},
            {'stage_order': 6, 'participant_id': 52, 'user_id': 24, 'score': 73},
          ],
          'notes': 'ملاحظات داخلية',
        },
      },
    };

void main() {
  group('live-state parses the backend contract', () {
    late LiveStateModel state;

    setUp(() => state = LiveStateModel.fromJson(_liveStateData()));

    test('lifecycle: status stays live, result phase open', () {
      expect(state.debate.status, DebateStatus.live);
      expect(state.debate.isCompleted, isFalse);
      expect(state.debate.speechesCompleted, isTrue); // speeches_completed_at set
      expect(state.rooms.result.open, isTrue);
      // This mirrors LiveDebateCubit.resultPhaseOpen: open while still `live`.
      final resultPhaseOpen = !state.debate.isCancelled &&
          (state.rooms.result.open || state.debate.speechesCompleted || state.debate.isCompleted);
      expect(resultPhaseOpen, isTrue);
    });

    test('rooms: result is judges-only joinable; roles parse incl. debater_*', () {
      expect(state.rooms.main.joinableForMe, isTrue);
      expect(state.rooms.main.roleIfJoined, DebateRoomRole.judgeChair);
      expect(state.rooms.prop.roleIfJoined, DebateRoomRole.debaterSpeaker);
      expect(state.rooms.opp.roleIfJoined, DebateRoomRole.debaterMember);
      expect(state.rooms.result.joinableForMe, isTrue);
    });

    test('chair resolves from judges[].is_chair', () {
      expect(state.isChair(16), isTrue);
      expect(state.isChair(30), isFalse);
      expect(state.chairJudge?.user.id, 16);
      expect(state.isJudge(30), isTrue);
    });

    test('multi-role speaking_order keeps the duplicate user', () {
      final order = state.proposition.speakingOrder;
      expect(order.length, 3);
      expect(order.map((s) => s.userId).toList(), [11, 12, 11]); // user 11 holds slots 1 & 3
      expect(order[2].participantId, 40);
    });

    test('reply speaker reads is_reply_speaker flag', () {
      expect(state.opposition.replySpeaker?.user.id, 23);
      expect(state.opposition.speakers.firstWhere((s) => s.user.id == 23).isReplySpeaker, isTrue);
      expect(state.proposition.speakers.first.isReplySpeaker, isFalse);
    });

    test('stages carry the phase id + server-resolved speaker', () {
      final s1 = state.stages.firstWhere((s) => s.orderIndex == 1);
      expect(s1.id, 100); // stages[].id present → POST /stages/{id}/poi works
      expect(s1.speakerUserId, 11);
      expect(state.stages.firstWhere((s) => s.orderIndex == 5).speakerUserId, 11);
    });
  });

  group('result view renders from scores.stages', () {
    late DebateResultView view;

    setUp(() => view = DebateResultView.fromLiveState(LiveStateModel.fromJson(_liveStateData())));

    test('winner + revealed + per-stage scores populate', () {
      expect(view.winningSide, DebateSide.proposition);
      expect(view.winningTeamName, 'فريق الإثبات');
      expect(view.revealed, isTrue);
      expect(view.hasScores, isTrue);
      final first = view.speeches.firstWhere((s) => s.stageOrder == 1);
      expect(first.score, 88);
      expect(first.speakerName, 'أحمد');
    });

    test('best speaker = highest non-reply score', () {
      // Stage 1 (Ahmad, 88) is the top non-reply score.
      expect(view.bestSpeaker, isNotNull);
      expect(view.bestSpeaker!.score, 88);
      expect(view.bestSpeaker!.speakerName, 'أحمد');
    });
  });

  group('result submit payload matches the backend', () {
    test('stage_scores are integers, one per stage', () {
      final model = DebateResultModel(
        winningSide: 'proposition',
        summaryNotes: 'note',
        stageScores: const [
          StageScore(stageOrder: 1, score: 88),
          StageScore(stageOrder: 2, score: 75),
        ],
      );
      final json = model.toJson();
      expect(json['winning_side'], 'proposition');
      final scores = json['stage_scores'] as List;
      expect(scores.length, 2);
      expect(scores.first, {'stage_order': 1, 'score': 88});
      // Every score must serialize as an int (the backend's `integer` validator).
      for (final s in scores) {
        expect((s as Map)['score'], isA<int>());
      }
    });
  });

  group('role enum', () {
    test('both debater_* wire values count as a debater', () {
      expect(DebateRoomRole.fromWire('debater_member').isDebater, isTrue);
      expect(DebateRoomRole.fromWire('debater_speaker').isDebater, isTrue);
      expect(DebateRoomRole.fromWire('debater').isDebater, isTrue);
      expect(DebateRoomRole.fromWire('judge_chair').isDebater, isFalse);
      expect(DebateRoomRole.fromWire('judge_chair').isChair, isTrue);
      expect(DebateRoomRole.fromWire('judge_panel').isJudge, isTrue);
      expect(DebateRoomRole.fromWire('something_new').isDebater, isFalse); // unknown
    });
  });
}
