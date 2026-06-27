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
  static const String adminCategories = '/admin/blog/categories';
  static const String adminTags = '/admin/blog/tags';

  static String get loginUrl => '$baseUrl$login';
  static String get forgotPasswordUrl => '$baseUrl$forgotPassword';
  static String get resetPasswordUrl => '$baseUrl$resetPassword';
  static String get profileUrl => '$baseUrl$profile';
  static String get avatarUrl => '$baseUrl$avatar';
  static String get changePasswordUrl => '$baseUrl$changePassword';
  static String get logoutUrl => '$baseUrl$logout';
  static String get searchUrl => '$baseUrl$search';
  static String get blogUrl => '$baseUrl$blog';
  static String get categoriesUrl => '$baseUrl$adminCategories';
  static String get tagsUrl => '$baseUrl$adminTags';

  // `Accept: application/json` (mandatory) + the Sanctum bearer.
  static String get debatesUrl => '$baseUrl/debates';
  static String liveStateUrl(int id) => '$baseUrl/debates/$id/live-state';
  static String tokenUrl(int id) => '$baseUrl/debates/$id/token';
  static String teamSpeakersUrl(int id) => '$baseUrl/debates/$id/team-speakers';
  static String nextStageUrl(int id) => '$baseUrl/debates/$id/next-stage';
  static String rollbackToLobbyUrl(int id) => '$baseUrl/debates/$id/rollback-to-lobby';
  static String poiUrl(int id, int phaseId) => '$baseUrl/debates/$id/stages/$phaseId/poi';
  static String resultUrl(int id) => '$baseUrl/debates/$id/result';
  static String revealResultUrl(int id) => '$baseUrl/debates/$id/result/reveal';
  static String closeMainUrl(int id) => '$baseUrl/debates/$id/close-main';
  static String closeRoomUrl(int id) => '$baseUrl/debates/$id/close-room';
  static String get feedbackUrl => '$baseUrl/feedback';

  /// Self-registration for a debate (as = debater | judge | team).
  static String registerUrl(int id) => '$baseUrl/debates/$id/register';
}