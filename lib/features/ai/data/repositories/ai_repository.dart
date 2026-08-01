import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_models.dart';
import '../providers/ai_provider.dart';

/// المستودع الوحيد لكل طلبات الذكاء الاصطناعي
///
/// الخصوصية: هذا هو المكان الوحيد الذي تُبنى فيه الطلبات، فيسهل
/// مراجعة ما يُرسل. لا تُرسل أسماء ولا بريد ولا معرّفات مستخدمين —
/// فقط أرقام مجمّعة أو خيارات اختارها المستخدم
class AIRepository {
  AIProvider _provider;
  AIRepository(this._provider);

  AIProvider get provider => _provider;

  /// تبديل المزود في وقت التشغيل
  void setProvider(AIProvider provider) => _provider = provider;

  static const String _historyKey = 'ai_history';
  static const String _enabledKey = 'ai_enabled';
  static const String _providerKey = 'ai_provider_id';
  static const int _maxHistory = 30;

  // ===== المهام =====

  Future<AIResponse> dateIdeas() =>
      _provider.complete(const AIRequest(task: AITask.dateIdeas));

  Future<AIResponse> activityNow() => _provider.complete(AIRequest(
        task: AITask.activitySuggestion,
        // نرسل الساعة فقط — لا تاريخ ولا موقع ولا هوية
        context: {'hour': DateTime.now().hour},
      ));

  Future<AIResponse> gameSuggestion({required int gamesPlayed}) =>
      _provider.complete(AIRequest(
        task: AITask.gameSuggestion,
        context: {'gamesPlayed': gamesPlayed},
      ));

  Future<AIResponse> challengeIdeas() =>
      _provider.complete(const AIRequest(task: AITask.challengeIdeas));

  Future<AIResponse> giftSuggestion({required int coins}) =>
      _provider.complete(AIRequest(
        task: AITask.giftSuggestion,
        context: {'coins': coins},
      ));

  Future<AIResponse> writeMessage({
    required MessageKind kind,
    required MessageTone tone,
    String? occasion,
  }) =>
      _provider.complete(AIRequest(
        task: AITask.writeMessage,
        context: {
          'kind': kind.name,
          'tone': tone.name,
          // المناسبة كلمة عامة يكتبها المستخدم (مثل "عيد ميلاد")
          if (occasion != null && occasion.trim().isNotEmpty)
            'occasion': occasion.trim(),
        },
      ));

  /// توليد أسئلة — نرسل الأسئلة السابقة لتفادي التكرار
  Future<AIResponse> generateQuestions({
    required QuestionLevel level,
    List<String> exclude = const [],
  }) =>
      _provider.complete(AIRequest(
        task: AITask.generateQuestions,
        context: {
          'level': level.name,
          'exclude': exclude.take(30).toList(),
        },
      ));

  /// تحليل الإحصائيات — أرقام مجمّعة فقط، بلا أي محتوى شخصي
  Future<AIResponse> relationshipInsights({
    required int gamesPlayed,
    required int streak,
    required int challengesDone,
    required int memories,
    required int gifts,
    required int level,
    required int totalPoints,
  }) =>
      _provider.complete(AIRequest(
        task: AITask.relationshipInsights,
        context: {
          'gamesPlayed': gamesPlayed,
          'streak': streak,
          'challengesDone': challengesDone,
          'memories': memories,
          'gifts': gifts,
          'level': level,
          'totalPoints': totalPoints,
        },
      ));

  // ===== الإعدادات المحلية =====

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<String?> savedProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerKey);
  }

  Future<void> saveProviderId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, id);
  }

  // ===== السجل المحلي =====

  Future<List<AIHistoryEntry>> history() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? const [];
    return raw
        .map((s) => AIHistoryEntry.fromMap(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addHistory(AIHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    raw.insert(0, jsonEncode(entry.toMap()));
    if (raw.length > _maxHistory) raw.removeRange(_maxHistory, raw.length);
    await prefs.setStringList(_historyKey, raw);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
