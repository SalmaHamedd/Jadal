import '../../features/debates/domain/entities/debate.dart';
import '../../features/debates/domain/entities/debate_results.dart';
import '../../features/debates/domain/entities/debater.dart';
import '../../features/debates/domain/entities/people.dart';
import '../../features/debates/domain/entities/score_entry.dart';
import '../../features/debates/domain/entities/session_models.dart';
import '../../features/debates/domain/entities/statistics_models.dart';
import '../../features/debates/domain/entities/team.dart';

final _now = DateTime.now();

// ---- 8 unique debaters split into 2 named teams (kTeamSize = 4 each) ----

const _govDebaters = <Debater>[
  Debater(id: 'd-001', name: 'أحمد الزهراني', isOnline: true, priority: 0),
  Debater(id: 'd-002', name: 'سارة القحطاني', isOnline: true, priority: 1),
  Debater(id: 'd-003', name: 'محمد العتيبي', isOnline: false, priority: 2),
  Debater(id: 'd-004', name: 'نورة الشمري', isOnline: true, priority: 3),
];

const _oppDebaters = <Debater>[
  Debater(id: 'd-005', name: 'خالد المطيري', isOnline: true, priority: 0),
  Debater(id: 'd-006', name: 'ريم الحربي', isOnline: false, priority: 1),
  Debater(id: 'd-007', name: 'عبدالله الدوسري', isOnline: true, priority: 2),
  Debater(id: 'd-008', name: 'لجين الغامدي', isOnline: true, priority: 3),
];

// ---- Two teams reused across debates ----

final mockTeamA = Team(
  id: 'team-a',
  name: 'فريق الفصاحة',
  side: TeamSide.government,
  debaters: _govDebaters,
);

final mockTeamB = Team(
  id: 'team-b',
  name: 'فريق البلاغة',
  side: TeamSide.opposition,
  debaters: _oppDebaters,
);

final mockTeamC = Team(
  id: 'team-c',
  name: 'فريق المنطق',
  side: TeamSide.government,
  debaters: _oppDebaters,
);

final mockTeamD = Team(
  id: 'team-d',
  name: 'فريق البرهان',
  side: TeamSide.opposition,
  debaters: _govDebaters,
);

const mockJudge = Judge(id: 'judge-1', name: 'د. عمر الفهد');
const mockCoach = Coach(id: 'coach-1', name: 'أ. هند المالكي');

// ---- Results for the past debate ----

final mockResults = DebateResults(
  debateId: 'debate-003',
  winningSide: TeamSide.government,
  governmentTotal: 348,
  oppositionTotal: 332,
  governmentScores: const [
    ScoreEntry(
      debaterId: 'd-001',
      debaterName: 'أحمد الزهراني',
      score: 92,
      comment: 'حجج قوية ومنطق متماسك، أداء صوتي ممتاز.',
    ),
    ScoreEntry(
      debaterId: 'd-002',
      debaterName: 'سارة القحطاني',
      score: 88,
      comment: 'تنظيم رائع للأفكار مع أمثلة مقنعة.',
    ),
    ScoreEntry(
      debaterId: 'd-003',
      debaterName: 'محمد العتيبي',
      score: 84,
      comment: 'حضور هادئ وردود فعّالة على نقاط المعارضة.',
    ),
    ScoreEntry(
      debaterId: 'd-004',
      debaterName: 'نورة الشمري',
      score: 84,
      comment: 'ختام قوي مع تلخيص واضح لمسار الفريق.',
    ),
  ],
  oppositionScores: const [
    ScoreEntry(
      debaterId: 'd-005',
      debaterName: 'خالد المطيري',
      score: 86,
      comment: 'افتتاح جريء ومحاور دقيقة.',
    ),
    ScoreEntry(
      debaterId: 'd-006',
      debaterName: 'ريم الحربي',
      score: 82,
      comment: 'مرونة في الرد، ينقصها قليل من العمق.',
    ),
    ScoreEntry(
      debaterId: 'd-007',
      debaterName: 'عبدالله الدوسري',
      score: 80,
      comment: 'تقديم منظم لكن مع تكرار لبعض النقاط.',
    ),
    ScoreEntry(
      debaterId: 'd-008',
      debaterName: 'لجين الغامدي',
      score: 84,
      comment: 'إيقاع جيد وتفاعل قوي مع نقاط الاستفسار.',
    ),
  ],
);

// ---- 3 debates ----

final mockDebates = <Debate>[
  Debate(
    id: 'debate-001',
    title: 'التعليم الرقمي أفضل من التقليدي',
    motionFramework: 'تعليمي',
    status: DebateLifecycle.upcoming,
    scheduledAt: _now.add(const Duration(days: 2)),
    governmentTeam: mockTeamA,
    oppositionTeam: mockTeamB,
    judge: mockJudge,
    coach: mockCoach,
  ),
  Debate(
    id: 'debate-002',
    title: 'وسائل التواصل الاجتماعي تضر بالمجتمع',
    motionFramework: 'اجتماعي',
    status: DebateLifecycle.live,
    scheduledAt: _now,
    governmentTeam: mockTeamC,
    oppositionTeam: mockTeamD,
    judge: mockJudge,
    coach: mockCoach,
  ),
  Debate(
    id: 'debate-003',
    title: 'الذكاء الاصطناعي يهدد سوق العمل',
    motionFramework: 'ثقافي',
    status: DebateLifecycle.past,
    scheduledAt: _now.subtract(const Duration(days: 5)),
    governmentTeam: mockTeamA,
    oppositionTeam: mockTeamC,
    judge: mockJudge,
    coach: mockCoach,
    results: mockResults,
  ),
];

// ---- Preparation chat seed ----

List<PrepChatMessage> mockPrepChatFor(String debateId) {
  final now = DateTime.now();
  return [
    PrepChatMessage(
      id: 'msg-1',
      authorId: 'd-001',
      authorName: 'أحمد الزهراني',
      text: 'لنركز على الجانب التعليمي في الافتتاح.',
      createdAt: now.subtract(const Duration(minutes: 6)),
    ),
    PrepChatMessage(
      id: 'msg-2',
      authorId: 'd-002',
      authorName: 'سارة القحطاني',
      text: 'سأجهز إحصائيات عن الفصول الافتراضية.',
      createdAt: now.subtract(const Duration(minutes: 4)),
    ),
    PrepChatMessage(
      id: 'msg-3',
      authorId: 'd-004',
      authorName: 'نورة الشمري',
      text: 'متفقة. والختام أتولاه أنا.',
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}

// ---- Live participants for an active debate ----

List<LiveParticipant> mockLiveParticipants() => [
      // Government — 4
      LiveParticipant(
        id: 'd-001',
        name: 'أحمد الزهراني',
        role: ParticipantRole.debater,
        team: TeamSide.government,
        isMicOn: true,
        isCameraOn: true,
        isActiveSpeaker: true,
        currentScore: 24,
      ),
      const LiveParticipant(
        id: 'd-002',
        name: 'سارة القحطاني',
        role: ParticipantRole.debater,
        team: TeamSide.government,
        isMicOn: false,
        isCameraOn: true,
        currentScore: 18,
      ),
      const LiveParticipant(
        id: 'd-003',
        name: 'محمد العتيبي',
        role: ParticipantRole.debater,
        team: TeamSide.government,
        isMicOn: false,
        isCameraOn: false,
        currentScore: 12,
      ),
      const LiveParticipant(
        id: 'd-004',
        name: 'نورة الشمري',
        role: ParticipantRole.debater,
        team: TeamSide.government,
        isMicOn: false,
        isCameraOn: true,
        currentScore: 0,
      ),
      // Opposition — 4
      const LiveParticipant(
        id: 'd-005',
        name: 'خالد المطيري',
        role: ParticipantRole.debater,
        team: TeamSide.opposition,
        isMicOn: false,
        isCameraOn: true,
        currentScore: 22,
      ),
      const LiveParticipant(
        id: 'd-006',
        name: 'ريم الحربي',
        role: ParticipantRole.debater,
        team: TeamSide.opposition,
        isMicOn: false,
        isCameraOn: false,
        currentScore: 16,
      ),
      const LiveParticipant(
        id: 'd-007',
        name: 'عبدالله الدوسري',
        role: ParticipantRole.debater,
        team: TeamSide.opposition,
        isMicOn: false,
        isCameraOn: true,
        currentScore: 14,
      ),
      const LiveParticipant(
        id: 'd-008',
        name: 'لجين الغامدي',
        role: ParticipantRole.debater,
        team: TeamSide.opposition,
        isMicOn: false,
        isCameraOn: true,
        currentScore: 0,
      ),
      // Judge
      const LiveParticipant(
        id: 'judge-1',
        name: 'د. عمر الفهد',
        role: ParticipantRole.judge,
        isMicOn: true,
        isCameraOn: true,
      ),
    ];

List<POIRequest> mockPOIRequests() => [
      POIRequest(
        id: 'poi-1',
        debaterId: 'd-005',
        debaterName: 'خالد المطيري',
        team: TeamSide.opposition,
        createdAt: DateTime.now().subtract(const Duration(seconds: 18)),
      ),
      POIRequest(
        id: 'poi-2',
        debaterId: 'd-007',
        debaterName: 'عبدالله الدوسري',
        team: TeamSide.opposition,
        createdAt: DateTime.now().subtract(const Duration(seconds: 6)),
      ),
    ];

List<PrivateNote> mockPrivateNotes() => [
      PrivateNote(
        id: 'n-1',
        fromName: 'سارة القحطاني',
        toName: 'أحمد الزهراني',
        text: 'لا تنسَ الإشارة لإحصائية المدارس الذكية.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      PrivateNote(
        id: 'n-2',
        fromName: 'نورة الشمري',
        toName: 'أحمد الزهراني',
        text: 'انتبه: المعارضة تتجه نحو الجانب الاقتصادي.',
        createdAt: DateTime.now().subtract(const Duration(seconds: 40)),
      ),
    ];

List<ActivityEvent> mockActivityFeed() => [
      ActivityEvent(
        id: 'a-1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        description: 'بدء جلسة المناظرة.',
      ),
      ActivityEvent(
        id: 'a-2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3, seconds: 12)),
        description: 'أحمد الزهراني بدأ كلمة الافتتاح.',
      ),
      ActivityEvent(
        id: 'a-3',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1, seconds: 50)),
        description: 'خالد المطيري طلب نقطة استفسار.',
      ),
      ActivityEvent(
        id: 'a-4',
        timestamp: DateTime.now().subtract(const Duration(seconds: 40)),
        description: 'الحكم أوقف الميكروفون لمحمد العتيبي.',
      ),
    ];

List<JoinRequest> mockJoinRequests() => [
      JoinRequest(
        id: 'jr-1',
        debaterName: 'بدر السهلي',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      JoinRequest(
        id: 'jr-2',
        debaterName: 'فاطمة العمري',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

// ---- Statistics seed ----

final mockGeneralStats = GeneralStatistics(
  totalDebates: 142,
  leaderboard: const [
    LeaderboardEntry(name: 'أحمد الزهراني', totalScore: 1240, wins: 14),
    LeaderboardEntry(name: 'سارة القحطاني', totalScore: 1180, wins: 13),
    LeaderboardEntry(name: 'خالد المطيري', totalScore: 1150, wins: 12),
    LeaderboardEntry(name: 'لجين الغامدي', totalScore: 1090, wins: 11),
    LeaderboardEntry(name: 'نورة الشمري', totalScore: 1040, wins: 10),
    LeaderboardEntry(name: 'محمد العتيبي', totalScore: 990, wins: 9),
    LeaderboardEntry(name: 'عبدالله الدوسري', totalScore: 940, wins: 8),
    LeaderboardEntry(name: 'ريم الحربي', totalScore: 910, wins: 7),
    LeaderboardEntry(name: 'بدر السهلي', totalScore: 870, wins: 6),
    LeaderboardEntry(name: 'فاطمة العمري', totalScore: 820, wins: 5),
  ],
  winRateByFramework: const [
    FrameworkWinRate(framework: 'تعليمي', winRate: 0.68),
    FrameworkWinRate(framework: 'اجتماعي', winRate: 0.54),
    FrameworkWinRate(framework: 'ثقافي', winRate: 0.61),
    FrameworkWinRate(framework: 'اقتصادي', winRate: 0.47),
  ],
);

final mockPersonalStats = PersonalStatistics(
  winRate: 0.72,
  scoreTrend: const [78, 82, 85, 88, 92],
  history: [
    DebateHistoryEntry(
      debateId: 'debate-003',
      title: 'الذكاء الاصطناعي يهدد سوق العمل',
      date: _now.subtract(const Duration(days: 5)),
      score: 92,
      win: true,
    ),
    DebateHistoryEntry(
      debateId: 'debate-h-2',
      title: 'الرياضة في المدرسة إلزامية',
      date: _now.subtract(const Duration(days: 18)),
      score: 88,
      win: true,
    ),
    DebateHistoryEntry(
      debateId: 'debate-h-3',
      title: 'القراءة الإلكترونية تحل محل الورقية',
      date: _now.subtract(const Duration(days: 27)),
      score: 85,
      win: false,
    ),
    DebateHistoryEntry(
      debateId: 'debate-h-4',
      title: 'العمل عن بُعد أنتجيّة',
      date: _now.subtract(const Duration(days: 40)),
      score: 82,
      win: true,
    ),
    DebateHistoryEntry(
      debateId: 'debate-h-5',
      title: 'الفنون مادة أساسية',
      date: _now.subtract(const Duration(days: 55)),
      score: 78,
      win: false,
    ),
  ],
);
