import '../storage/preferences_database.dart';

/// Support contact info returned on login —
/// cached locally by [ApiAuthRepository.login] so the nav drawer can show it
/// without a network call. Any field may be null until the backend row is set.
/// Two backend corrections baked in here:
/// • `instagram` holds a **full URL** in the live data, not a bare handle —
/// so it is never used to build a URL. Use [instagramUrl] / [instagramHandle].
/// • [phoneE164] is null (not a guess) when the stored number has no country
/// code, because a `tel:` built from a local number dials the wrong country.
class ContactInfo {
  final String? email;
  final String? phone;
  final String? phoneE164;
  final String? instagramUrl;
  final String? instagramHandle;
  final String? whatsapp;
  final String? website;
  final String? telegram;
  final String? x;
  final String? facebook;
  final String? youtube;

  const ContactInfo({
    this.email,
    this.phone,
    this.phoneE164,
    this.instagramUrl,
    this.instagramHandle,
    this.whatsapp,
    this.website,
    this.telegram,
    this.x,
    this.facebook,
    this.youtube,
  });

  bool get isEmpty =>
      email == null &&
      phoneE164 == null &&
      instagramUrl == null &&
      whatsapp == null &&
      website == null &&
      telegram == null &&
      x == null &&
      facebook == null &&
      youtube == null;

  static const _keys = <String>[
    'contact_email',
    'contact_phone',
    'contact_phone_e164',
    'contact_instagram_url',
    'contact_instagram_handle',
    'contact_whatsapp',
    'contact_website',
    'contact_telegram',
    'contact_x',
    'contact_facebook',
    'contact_youtube',
  ];

  /// Persists the login response's `contact` block. Blank strings are stored as
  /// null so the drawer's "hide empty rows" rule needs no special casing.
  static Future<void> cache(Map<dynamic, dynamic> contact) async {
    final prefs = PreferencesDatabase();
    String? clean(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    // `instagram` is a URL in live data; keep the explicit keys authoritative
    // and only fall back to it when the backend hasn't sent them yet.
    final legacyInsta = clean(contact['instagram']);
    final values = <String?>[
      clean(contact['email']),
      clean(contact['phone']),
      clean(contact['phone_e164']),
      clean(contact['instagram_url']) ??
          (legacyInsta != null && legacyInsta.startsWith('http')
              ? legacyInsta
              : null),
      clean(contact['instagram_handle']) ??
          (legacyInsta != null && !legacyInsta.startsWith('http')
              ? legacyInsta.replaceFirst('@', '')
              : null),
      clean(contact['whatsapp']),
      clean(contact['website']),
      clean(contact['telegram']),
      clean(contact['x']),
      clean(contact['facebook']),
      clean(contact['youtube']),
    ];

    // One batched flush — this was eleven separate read-modify-writes of the
    // whole store, which raced with the token write happening beside it.
    await prefs.setValues({
      for (var i = 0; i < _keys.length; i++) _keys[i]: values[i],
    });
  }

  static Future<ContactInfo> load() async {
    final prefs = PreferencesDatabase();
    Future<String?> get(String k) => prefs.getValue<String>(k);
    return ContactInfo(
      email: await get('contact_email'),
      phone: await get('contact_phone'),
      phoneE164: await get('contact_phone_e164'),
      instagramUrl: await get('contact_instagram_url'),
      instagramHandle: await get('contact_instagram_handle'),
      whatsapp: await get('contact_whatsapp'),
      website: await get('contact_website'),
      telegram: await get('contact_telegram'),
      x: await get('contact_x'),
      facebook: await get('contact_facebook'),
      youtube: await get('contact_youtube'),
    );
  }
}
