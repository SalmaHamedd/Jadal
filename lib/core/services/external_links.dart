import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// MF_FU §1.2 — opens a contact value in the right external app.
///
/// Every helper returns `false` when nothing could be opened, so the caller can
/// fall back to copying the value to the clipboard instead of the tap doing
/// nothing at all.
abstract class ExternalLinks {
  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// `phoneE164` only — never a human-formatted number. The backend returns
  /// null when the stored number has no country code, precisely because a
  /// `tel:` built from a local number dials the wrong country.
  static Future<bool> dial(String phoneE164) =>
      _open(Uri(scheme: 'tel', path: phoneE164));

  static Future<bool> email(String address) =>
      _open(Uri(scheme: 'mailto', path: address));

  /// Tries the Instagram app first, then the profile URL in a browser.
  static Future<bool> instagram({String? handle, String? url}) async {
    if (handle != null && handle.isNotEmpty) {
      final app = Uri.parse('instagram://user?username=$handle');
      if (await _open(app)) return true;
    }
    if (url != null && url.isNotEmpty) return _open(Uri.parse(url));
    if (handle != null && handle.isNotEmpty) {
      return _open(Uri.parse('https://instagram.com/$handle'));
    }
    return false;
  }

  static Future<bool> whatsapp(String phoneE164) {
    final digits = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    return _open(Uri.parse('https://wa.me/$digits'));
  }

  static Future<bool> web(String url) {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    return _open(Uri.parse(normalized));
  }

  static Future<void> copy(String value) =>
      Clipboard.setData(ClipboardData(text: value));
}
