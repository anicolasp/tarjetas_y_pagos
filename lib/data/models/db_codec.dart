/// Shared encoding helpers for model <-> SQLite maps.
library;

/// Calendar dates (expense date, due date) are stored as `yyyy-MM-dd`.
String encodeDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime decodeDate(String s) => DateTime.parse(s);

/// Timestamps (`created_at`) are stored as full ISO-8601.
String encodeTimestamp(DateTime d) => d.toIso8601String();

DateTime decodeTimestamp(String s) => DateTime.parse(s);

int encodeBool(bool b) => b ? 1 : 0;

bool decodeBool(Object? v) => v == 1;
