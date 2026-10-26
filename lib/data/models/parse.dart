/// Small helpers so a missing or oddly-typed field never crashes the app.
///
/// Django sends DecimalField as a STRING ("89.00"), not a number. Every money
/// field in this app goes through [asDouble] for that reason.
library;

double asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

String asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<Map<String, dynamic>> asMapList(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return const [];
}

/// DRF can return either a plain list or a paginated {count, results:[...]}.
List<Map<String, dynamic>> unwrapList(dynamic body) {
  if (body is List) return asMapList(body);
  if (body is Map && body['results'] is List) return asMapList(body['results']);
  return const [];
}
