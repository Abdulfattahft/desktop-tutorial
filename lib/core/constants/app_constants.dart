/// ثوابت عامة تُستخدم في كل التطبيق
class AppConstants {
  AppConstants._();

  static const String appName = 'بيننا';

  // ===== أسماء مجموعات Firestore =====
  static const String usersCollection = 'users';
  static const String couplesCollection = 'couples';
  static const String sessionsCollection = 'sessions'; // couples/{id}/sessions
  static const String gameHistoryCollection = 'gameHistory';
  static const String challengesCollection = 'challenges';
  static const String memoriesCollection = 'memories';
  static const String giftsCollection = 'gifts';
  static const String giftCatalogCollection = 'giftCatalog';
  static const String notificationsCollection = 'notifications';
  static const String dailyQuestionsCollection = 'daily_questions';

  // ===== نظام النقاط =====
  static const int pointsPerRound = 10; // لكل جولة مكتملة
  static const int matchBonus = 5; // مكافأة تطابق الإجابتين
  static const int coinsPerGame = 15; // عملات لكل طرف عند إنهاء لعبة
  static const int pointsPerChallenge = 25;
  static const int pointsPerDailyQuestion = 5;
  static const int pointsPerMemory = 5;

  // النقاط المطلوبة لكل مستوى (المستوى 1 يبدأ من صفر)
  static const List<int> levelThresholds = [
    0, 100, 250, 500, 900, 1500, 2500, 4000, 6000, 9000,
  ];

  // أسماء المستويات
  static const List<String> levelNames = [
    'بداية الحكاية',
    'تعارف',
    'قرب',
    'مودة',
    'انسجام',
    'وفاء',
    'عشق',
    'توأم روح',
    'حب أسطوري',
    'إلى الأبد',
  ];

  /// حساب المستوى من مجموع النقاط
  static int levelForPoints(int points) {
    var level = 1;
    for (var i = 0; i < levelThresholds.length; i++) {
      if (points >= levelThresholds[i]) level = i + 1;
    }
    return level;
  }

  static String levelName(int level) =>
      levelNames[(level - 1).clamp(0, levelNames.length - 1)];

  // ===== الهدايا الافتراضية =====
  static const int giftRosePrice = 50;
  static const int giftChocolatePrice = 80;
  static const int giftLoveLetterPrice = 120;

  // ===== أخرى =====
  static const int inviteCodeLength = 6;
}
