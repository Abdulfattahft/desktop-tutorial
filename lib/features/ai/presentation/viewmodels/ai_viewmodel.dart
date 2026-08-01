import 'package:flutter/foundation.dart';

import '../../data/models/ai_models.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/repositories/ai_repository.dart';

class AIViewModel extends ChangeNotifier {
  final AIRepository _repo;
  AIViewModel(this._repo) {
    _loadSettings();
  }

  bool isLoading = false;
  String? errorMessage;
  AIResponse? result;
  AITask? lastTask;

  bool aiEnabled = true;
  List<AIHistoryEntry> history = const [];

  String get providerName => _repo.provider.displayName;
  String get activeProviderId => _repo.provider.id;
  List<String> get availableProviders => AIProviderRegistry.availableIds;

  Future<void> _loadSettings() async {
    aiEnabled = await _repo.isEnabled();
    history = await _repo.history();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    aiEnabled = value;
    await _repo.setEnabled(value);
    notifyListeners();
  }

  /// تبديل المزود — سطر واحد يغيّر مصدر الذكاء الاصطناعي كله
  Future<void> switchProvider(String providerId) async {
    final p = AIProviderRegistry.build(providerId);
    if (p == null) return;
    _repo.setProvider(p);
    await _repo.saveProviderId(providerId);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repo.clearHistory();
    history = const [];
    notifyListeners();
  }

  /// غلاف موحد لكل المهام
  Future<void> _run(
    AITask task,
    Future<AIResponse> Function() action, {
    String? historyTitle,
  }) async {
    if (!aiEnabled) {
      errorMessage = 'ميزات المساعد معطّلة — فعّلها من الإعدادات';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    result = null;
    lastTask = task;
    notifyListeners();

    try {
      final res = await action();
      result = res;
      // حفظ في السجل المحلي
      final content = res.text ?? res.items.join('\n• ');
      if (content.isNotEmpty) {
        await _repo.addHistory(AIHistoryEntry(
          taskName: task.name,
          title: historyTitle ?? task.label,
          content: content,
          at: DateTime.now(),
        ));
        history = await _repo.history();
      }
    } on AIException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dateIdeas() => _run(AITask.dateIdeas, _repo.dateIdeas);

  Future<void> activityNow() =>
      _run(AITask.activitySuggestion, _repo.activityNow);

  Future<void> gameSuggestion(int gamesPlayed) => _run(
      AITask.gameSuggestion,
      () => _repo.gameSuggestion(gamesPlayed: gamesPlayed));

  Future<void> challengeIdeas() =>
      _run(AITask.challengeIdeas, _repo.challengeIdeas);

  Future<void> giftSuggestion(int coins) => _run(
      AITask.giftSuggestion, () => _repo.giftSuggestion(coins: coins));

  Future<void> writeMessage({
    required MessageKind kind,
    required MessageTone tone,
    String? occasion,
  }) =>
      _run(
        AITask.writeMessage,
        () => _repo.writeMessage(
            kind: kind, tone: tone, occasion: occasion),
        historyTitle: '${kind.label} (${tone.label})',
      );

  Future<void> generateQuestions({
    required QuestionLevel level,
    List<String> exclude = const [],
  }) =>
      _run(
        AITask.generateQuestions,
        () => _repo.generateQuestions(level: level, exclude: exclude),
        historyTitle: 'أسئلة ${level.label}',
      );

  Future<void> insights({
    required int gamesPlayed,
    required int streak,
    required int challengesDone,
    required int memories,
    required int gifts,
    required int level,
    required int totalPoints,
  }) =>
      _run(
        AITask.relationshipInsights,
        () => _repo.relationshipInsights(
          gamesPlayed: gamesPlayed,
          streak: streak,
          challengesDone: challengesDone,
          memories: memories,
          gifts: gifts,
          level: level,
          totalPoints: totalPoints,
        ),
      );

  void clearResult() {
    result = null;
    errorMessage = null;
    notifyListeners();
  }
}
