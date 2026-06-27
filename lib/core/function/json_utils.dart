library;

int? asInt(dynamic v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

double? asDouble(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

num? asNum(dynamic v) =>
    v is num ? v : (v is String ? num.tryParse(v) : null);

bool asBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

String? asString(dynamic v) => v?.toString();

DateTime? asDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;

/// A list of JSON objects; tolerates null / non-list / non-map entries.
List<Map<String, dynamic>> asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

List<String> asStringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// A nested JSON object, or null.
Map<String, dynamic>? asMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : null;
