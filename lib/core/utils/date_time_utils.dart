/// UTC timestamps from backend → hiển thị giờ Việt Nam (UTC+7).
class DateTimeUtils {
  static const Duration _vietnamOffset = Duration(hours: 7);

  /// Parse chuỗi ISO UTC từ API thành [DateTime] UTC (không cộng offset ở đây).
  static DateTime parseApiUtc(String value) {
    final trimmed = value.trim();
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(trimmed);

    if (match != null) {
      return DateTime.utc(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
      );
    }

    final parsed = DateTime.parse(trimmed);
    return parsed.isUtc ? parsed : parsed.toUtc();
  }

  static DateTime? tryParseApiUtc(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return parseApiUtc(value);
    } catch (_) {
      return null;
    }
  }

  /// UTC → wall-clock VN dạng local DateTime (tránh DateFormat cộng offset lần nữa).
  static DateTime toVietnamWallClock(DateTime utc) {
    final base = utc.isUtc ? utc : utc.toUtc();
    final shifted = base.add(_vietnamOffset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  static String formatHm(DateTime dateTime) {
    final display = dateTime.isUtc ? toVietnamWallClock(dateTime) : dateTime;
    final h = display.hour.toString().padLeft(2, '0');
    final m = display.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
