class ApiConstants {
  static const String baseUrl = 'http://31.70.76.84/api';

  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  static const String profile = '/profile';
  static const String avatar = '/profile/avatar';
  static const String changePassword = '/profile/password';
  static const String logout = '/auth/logout';

  static String get loginUrl => '$baseUrl$login';
  static String get forgotPasswordUrl => '$baseUrl$forgotPassword';
  static String get resetPasswordUrl => '$baseUrl$resetPassword';
  static String get profileUrl => '$baseUrl$profile';
  static String get avatarUrl => '$baseUrl$avatar';
  static String get changePasswordUrl => '$baseUrl$changePassword';
  static String get logoutUrl => '$baseUrl$logout';
}
