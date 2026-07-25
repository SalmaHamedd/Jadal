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
}
