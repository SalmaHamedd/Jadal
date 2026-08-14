class ApiConstants {
  static const String baseUrl = 'https://jadal-platform.com/api';

  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  static const String profile = '/profile';
  static const String avatar = '/profile/avatar';
  static const String changePassword = '/profile/password';
  static const String logout = '/auth/logout';
  static const String search = '/search';
  static const String blog = '/blog';
  static const String teams = '/teams';
  static const String adminCategories = '/admin/blog/categories';
  static const String adminTags = '/admin/blog/tags';
  static const String surveys = '/surveys';
  static const String complaints = '/complaints';

  static String get loginUrl => '$baseUrl$login';
  static String get forgotPasswordUrl => '$baseUrl$forgotPassword';
  static String get resetPasswordUrl => '$baseUrl$resetPassword';
  static String get profileUrl => '$baseUrl$profile';
  static String get avatarUrl => '$baseUrl$avatar';
  static String get changePasswordUrl => '$baseUrl$changePassword';
  static String get logoutUrl => '$baseUrl$logout';
  static String get searchUrl => '$baseUrl$search';
  static String get blogUrl => '$baseUrl$blog';
  static String get teamsUrl => '$baseUrl$teams';
  static String teamUrl(int id) => '$teamsUrl/$id';
  static String teamMembersUrl(int id) => '$teamsUrl/$id/members';
  static String teamMemberUrl(int id, int userId) => '$teamsUrl/$id/members/$userId';
  static String teamMembersPriorityUrl(int id) => '$teamsUrl/$id/members/priority';
  static String teamLeaveUrl(int id) => '$teamsUrl/$id/leave';
  static String teamLeaveRequestsUrl(int id) => '$teamsUrl/$id/leave-requests';
  static String teamLeaveRequestRespondUrl(int id, int requestId) =>
      '$teamsUrl/$id/leave-requests/$requestId/respond';
  static String teamJoinUrl(int id) => '$teamsUrl/$id/join';
  static String teamJoinRequestsUrl(int id) => '$teamsUrl/$id/join-requests';
  static String teamJoinRequestRespondUrl(int id, int requestId) =>
      '$teamsUrl/$id/join-requests/$requestId/respond';
  static String get complaintsUrl => '$baseUrl$complaints';
  static String get myComplaintsUrl => '$complaintsUrl/mine';
  static String get categoriesUrl => '$baseUrl$adminCategories';
  static String get tagsUrl => '$baseUrl$adminTags';
  static String get surveysUrl => '$baseUrl$surveys';
  static String surveyDetailsUrl(int id) => '$surveysUrl/$id';
  static String surveyRespondUrl(int id) => '$surveysUrl/$id/respond';

  static const String trainerSurveys = '/trainer/surveys';
  static String get trainerSurveysUrl => '$baseUrl$trainerSurveys';
  static String trainerSurveyDetailsUrl(int id) => '$trainerSurveysUrl/$id';
  static String trainerSurveyResultsUrl(int id) => '$trainerSurveysUrl/$id/results';

  // `Accept: application/json` (mandatory) + the Sanctum bearer.
  static String get debatesUrl => '$baseUrl/debates';
  static String liveStateUrl(int id) => '$baseUrl/debates/$id/live-state';
  static String tokenUrl(int id) => '$baseUrl/debates/$id/token';
  static String teamSpeakersUrl(int id) => '$baseUrl/debates/$id/team-speakers';
  static String nextStageUrl(int id) => '$baseUrl/debates/$id/next-stage';
  static String rollbackToLobbyUrl(int id) => '$baseUrl/debates/$id/rollback-to-lobby';
  // V11: server-authoritative timer (pause/resume) + intro phase (start-live).
  static String timerUrl(int id) => '$baseUrl/debates/$id/timer';
  static String startLiveUrl(int id) => '$baseUrl/debates/$id/start-live';
  static String poiUrl(int id, int phaseId) => '$baseUrl/debates/$id/stages/$phaseId/poi';
  static String resultUrl(int id) => '$baseUrl/debates/$id/result';
  static String revealResultUrl(int id) => '$baseUrl/debates/$id/result/reveal';
  static String closeMainUrl(int id) => '$baseUrl/debates/$id/close-main';
  static String closeRoomUrl(int id) => '$baseUrl/debates/$id/close-room';
  static String get feedbackUrl => '$baseUrl/feedback';

  // Persistent team chat (sprinkles §2) — additive to the peer `team_chat`
  // data-channel event, which still handles live delivery unchanged.
  static String chatUrl(int id) => '$baseUrl/debates/$id/chat';
  static String chatReadUrl(int id) => '$baseUrl/debates/$id/chat/read';

  /// Self-registration for a debate (as = debater | judge | team).
  static String registerUrl(int id) => '$baseUrl/debates/$id/register';

  /// V12 §1 — teams the caller may register for this debate (lead/coach).
  static String registerableTeamsUrl(int id) => '$baseUrl/debates/$id/registerable-teams';

  /// V12 §3 — who registered so far, split into teams / judges / solo.
  static String registrationsUrl(int id) => '$baseUrl/debates/$id/registrations';

  // ── Debater statistics (read-only, §"Debater Statistics API") ────────────────
  // {debater} is the debater's user id. Auth: bearer + check.status.
  static String _statsBase(int debaterId) => '$baseUrl/debaters/$debaterId/stats';
  static String winRateUrl(int debaterId) => '${_statsBase(debaterId)}/win-rate';
  static String avgScoreUrl(int debaterId) => '${_statsBase(debaterId)}/avg-score';
  static String bestSpeakerUrl(int debaterId) => '${_statsBase(debaterId)}/best-speaker';
  static String scoreRankingUrl(int debaterId) => '${_statsBase(debaterId)}/score-ranking';
  static String improvementUrl(int debaterId) => '${_statsBase(debaterId)}/improvement';

  // ── Public profile / achievements / team history (sprinkles §6) ──────────────
  static String userProfileUrl(int id) => '$baseUrl/users/$id';
  static String userAchievementsUrl(int id) => '$baseUrl/users/$id/achievements';
  static String userTeamsUrl(int id) => '$baseUrl/users/$id/teams';
  static String userTeamsHistoryUrl(int id) => '$baseUrl/users/$id/teams/history';

  // ── Debate search + filter option lists (sprinkles §8) ────────────────────────
  static String get debatesSearchUrl => '$baseUrl/debates/search';
  static String get debateFormatsUrl => '$baseUrl/debate-formats';
  static String get debateTagsDistinctUrl => '$baseUrl/debates/tags/distinct';
  static String get motionFrameworksUrl => '$baseUrl/motion-frameworks';
  static String get judgesListUrl => '$baseUrl/judges';
  static String get teamsOptionsUrl => '$baseUrl/teams/options';

  // ── Blog search + filter option lists (sprinkles §10) ─────────────────────────
  static String get blogAuthorsUrl => '$baseUrl/blog/authors';

  // ── Push notifications §7 — FCM device-token registry ────────────────────────
  // POST upserts keyed on the token (reassigning it across users); DELETE is
  // idempotent and scoped to the authenticated caller, so it must be called
  // BEFORE the auth token is discarded on logout or it 401s.
  static String get devicesUrl => '$baseUrl/devices';

  // ── V2 §3 — public leaderboards (top-10; best_speaker is debaters-only) ──────
  static String get leaderboardDebatersUrl => '$baseUrl/leaderboards/debaters';
  static String get leaderboardTeamsUrl => '$baseUrl/leaderboards/teams';

  // ── V2 §3 — coach team-summary (scalar per metric, averaged across teams) ────
  static String trainerTeamSummaryUrl(int trainerId) =>
      '$baseUrl/trainers/$trainerId/stats/team-summary';

  // ── V2 §7 — participation/activity score (raw weighted points + breakdown) ───
  static String debaterActivityUrl(int id) => '${_statsBase(id)}/activity';
  static String trainerActivityUrl(int id) => '$baseUrl/trainers/$id/stats/activity';
  static String judgeActivityUrl(int id) => '$baseUrl/judges/$id/stats/activity';

  // ── MF_FU §3 — per-team coach analytics ──────────────────────────────────────
  /// The coach's teams, for the analysis screen's team picker. `GET /teams` is
  /// NOT reusable here: it is scoped to the caller rather than the subject,
  /// doesn't exclude random teams for a trainer caller, and has no
  /// `members_count` (BACKEND_REPLY_MF_FU §3.1b).
  static String trainerTeamsUrl(int trainerId) =>
      '$baseUrl/trainers/$trainerId/teams';

  /// `metric` ∈ win-rate | avg-score | improvement | activity. Same query
  /// params and same response envelopes as the debater endpoints, so the
  /// existing parsers are reused unchanged.
  static String teamStatUrl(int teamId, String metric) =>
      '$baseUrl/teams/$teamId/stats/$metric';

  /// MF_FU §4 — which line-up performs best. Coach/admin only (403 otherwise):
  /// a line-up analysis tells any reader which three people to prepare against.
  static String teamCombinationsUrl(int teamId) =>
      '$baseUrl/teams/$teamId/stats/combinations';

  // ── MF_FU §5 — judge ratings received (aggregates only, never per-rating) ────
  static String judgeRatingsUrl(int judgeId) =>
      '$baseUrl/judges/$judgeId/stats/ratings';
}
