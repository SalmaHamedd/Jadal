import '../storage/preferences_database.dart';

/// Support contact info returned on login (sprinkles §9) — cached locally by
/// [ApiAuthRepository.login] so the nav drawer can show it without a network
/// call. Any field may be null until the backend env vars are set.
class ContactInfo {
  final String? email;
  final String? phone;
  final String? instagram;
  const ContactInfo({this.email, this.phone, this.instagram});

  bool get isEmpty => email == null && phone == null && instagram == null;

  static Future<ContactInfo> load() async {
    final prefs = PreferencesDatabase();
    return ContactInfo(
      email: await prefs.getValue<String>('contact_email'),
      phone: await prefs.getValue<String>('contact_phone'),
      instagram: await prefs.getValue<String>('contact_instagram'),
    );
  }
}
