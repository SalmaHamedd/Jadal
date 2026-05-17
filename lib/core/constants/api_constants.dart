class ApiConstants {
  static const String baseUrl = 'http://31.70.76.84/api';

  static const String loginEndpoint = '/auth/login';

  static String get loginUrl => '$baseUrl$loginEndpoint';
}