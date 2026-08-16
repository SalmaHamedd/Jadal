import 'package:flutter/widgets.dart';

import '../localization/l10n/context_localiztion.dart';
import 'failures.dart';

/// Turns a failure into something an end user can actually act on.
/// The app used to render whatever string the repository happened to put in the
/// failure — `"Network error: SocketException: Failed host lookup..."`, or a
/// backend message with both languages pipe-separated. Those are debugging
/// aids, not user-facing copy.
/// The rule here: **transport and server problems are described by their
/// TYPE**, never by the raw string; only messages the backend wrote *for the
/// user* (validation, business rules) are passed through — and even then the
/// caller's language is picked out of a bilingual string.
abstract class FailureText {
  /// Technical noise that must never reach a user, whatever wrapped it.
  static final _technical = RegExp(
    r'SocketException|HandshakeException|TimeoutException|ClientException|'
    r'HttpException|FormatException|Failed host lookup|Connection (closed|refused|reset)|'
    r'Software caused connection abort|OS Error|errno|Network is unreachable|'
    r'XMLHttpRequest|#\d+\s+',
    caseSensitive: false,
  );

  /// Phrases repositories use for "the request never reached the server".
  static final _connectivity = RegExp(
    r'network error|no internet|offline|unreachable|failed host lookup|'
    r'connection (closed|refused|reset|timed out)|timeout',
    caseSensitive: false,
  );

  /// Maps a [Failure] to user-facing copy.
  static String of(BuildContext context, Failure failure) {
    final loc = context.loc;
    return switch (failure) {
      NetworkFailure() || OfflineFailure() => loc.errorNoConnection,
      AuthFailure() => loc.errorSessionExpired,
      RateLimitFailure() => loc.errorTooManyRequests,
      NotFoundFailure() => _passThroughOr(context, failure.message, loc.errorNotFound),
      // The backend writes a proper bilingual sentence for a closed share link,
      // so show it rather than a generic error.
      GoneFailure() => _passThroughOr(context, failure.message, loc.errorLinkExpired),
      // 403 and 422 carry a reason the user needs (why an action was refused,
      // which field is wrong), so they are shown when they look human-written.
      ForbiddenFailure() => _passThroughOr(context, failure.message, loc.errorNotAllowed),
      ValidationFailure() => _passThroughOr(context, failure.message, loc.errorGeneric),
      EmptyCacheFailure() => loc.errorGeneric,
      _ => fromMessage(context, failure.message),
    };
  }

  /// For cubits that only kept the message string. Same rules as [of], applied
  /// heuristically since the type is gone.
  static String fromMessage(BuildContext context, String? raw) {
    final loc = context.loc;
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return loc.errorGeneric;
    if (_connectivity.hasMatch(text)) return loc.errorNoConnection;
    if (_technical.hasMatch(text)) return loc.errorServer;
    return _localizedSide(context, text);
  }

  /// Shows [message] when it reads like something written for a user;
  /// otherwise falls back to [fallback].
  static String _passThroughOr(
    BuildContext context,
    String message,
    String fallback,
  ) {
    final text = message.trim();
    if (text.isEmpty || _technical.hasMatch(text)) return fallback;
    return _localizedSide(context, text);
  }

  /// The backend returns some messages with both languages in one string,
  /// separated by a pipe — e.g.
  /// `"غير مصرح. هذا الفريق ليس ضمن فرق هذا المدرب. | Unauthorized. That team…"`.
  /// Show only the caller's side.
  static String _localizedSide(BuildContext context, String text) {
    if (!text.contains('|')) return text;
    final parts = text.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (parts.length < 2) return text;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Arabic is written first in the backend's pairs; detect rather than
    // assume, so a reordered pair still resolves correctly.
    final arabic = parts.firstWhere(_looksArabic, orElse: () => parts.first);
    final latin = parts.firstWhere((p) => !_looksArabic(p), orElse: () => parts.last);
    return isArabic ? arabic : latin;
  }

  static bool _looksArabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);
}
