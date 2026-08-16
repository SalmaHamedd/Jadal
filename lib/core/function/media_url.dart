import '../constants/api_constants.dart';

/// Resolves a possibly-relative media path against the API origin (—
/// some endpoints return `/storage/…` paths where others return absolute
/// URLs; a relative path fed to NetworkImage silently renders nothing).
/// Doubled `/storage/https://…` URLs are treated as absent, matching the
/// live-debate sanitizer.
String? resolveMediaUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = raw.trim();
  if (v.startsWith('/storage/http')) return null;
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  final api = Uri.parse(ApiConstants.baseUrl);
  final origin = '${api.scheme}://${api.host}';
  return v.startsWith('/') ? '$origin$v' : '$origin/$v';
}
