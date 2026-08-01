import 'dart:math';

/// أدوات مساعدة عامة
class AppUtils {
  AppUtils._();

  /// توليد رمز دعوة عشوائي (أحرف وأرقام واضحة، بدون المتشابهة مثل O و 0)
  static String generateInviteCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}

/// تنسيق الوقت النسبي بالعربية — "متصل الآن"، "قبل 5 دقائق"…
class TimeUtils {
  TimeUtils._();

  static const Duration onlineThreshold = Duration(minutes: 3);

  static bool isOnline(DateTime lastActive) =>
      DateTime.now().difference(lastActive) < onlineThreshold;

  static String relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff < onlineThreshold) return 'متصل الآن';
    if (diff.inMinutes < 60) return 'قبل ${_ar(diff.inMinutes, "دقيقة", "دقيقتين", "دقائق")}';
    if (diff.inHours < 24) return 'قبل ${_ar(diff.inHours, "ساعة", "ساعتين", "ساعات")}';
    if (diff.inDays < 30) return 'قبل ${_ar(diff.inDays, "يوم", "يومين", "أيام")}';
    return 'قبل ${_ar(diff.inDays ~/ 30, "شهر", "شهرين", "أشهر")}';
  }

  static String _ar(int n, String one, String two, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n <= 10) return '$n $many';
    return '$n $one';
  }
}
