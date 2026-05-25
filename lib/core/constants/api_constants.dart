class ApiConstants {
  static const String baseUrl = 'http://31.70.76.84/api';

  static const String loginEndpoint = '/auth/login';
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  static const String profile = '/profile';

  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get forgotPasswordUrl => '$baseUrl$forgotPassword';
  static String get resetPasswordUrl => '$baseUrl$resetPassword';
  static String get profileUrl => '$baseUrl$profile';
}
