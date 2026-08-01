import 'package:flutter/material.dart';

/// أنواع مهام الذكاء الاصطناعي
enum AITask {
  dateIdeas,       // أفكار موعد
  activitySuggestion, // نشاط حسب وقت اليوم
  gameSuggestion,  // اقتراح ألعاب
  challengeIdeas,  // تحديات جديدة
  giftSuggestion,  // اقتراح هدايا
  writeMessage,    // كتابة رسالة
  generateQuestions, // توليد أسئلة
  relationshipInsights, // تحليل الإحصائيات
}

extension AITaskX on AITask {
  String get label => switch (this) {
        AITask.dateIdeas => 'أفكار موعد',
        AITask.activitySuggestion => 'نشاط الآن',
        AITask.gameSuggestion => 'اقترح لعبة',
        AITask.challengeIdeas => 'تحديات جديدة',
        AITask.giftSuggestion => 'اقترح هدية',
        AITask.writeMessage => 'اكتب رسالة',
        AITask.generateQuestions => 'أسئلة جديدة',
        AITask.relationshipInsights => 'تحليل علاقتكما',
      };

  String get emoji => switch (this) {
        AITask.dateIdeas => '💑',
        AITask.activitySuggestion => '⏰',
        AITask.gameSuggestion => '🎮',
        AITask.challengeIdeas => '🔥',
        AITask.giftSuggestion => '🎁',
        AITask.writeMessage => '💌',
        AITask.generateQuestions => '❓',
        AITask.relationshipInsights => '📊',
      };

  IconData get icon => switch (this) {
        AITask.dateIdeas => Icons.favorite_rounded,
        AITask.activitySuggestion => Icons.schedule_rounded,
        AITask.gameSuggestion => Icons.videogame_asset_rounded,
        AITask.challengeIdeas => Icons.local_fire_department_rounded,
        AITask.giftSuggestion => Icons.card_giftcard_rounded,
        AITask.writeMessage => Icons.edit_note_rounded,
        AITask.generateQuestions => Icons.help_outline_rounded,
        AITask.relationshipInsights => Icons.insights_rounded,
      };
}

/// أنواع الرسائل
enum MessageKind { morning, evening, apology, thanks, romantic, occasion }

extension MessageKindX on MessageKind {
  String get label => switch (this) {
        MessageKind.morning => 'رسالة صباحية',
        MessageKind.evening => 'رسالة مسائية',
        MessageKind.apology => 'رسالة اعتذار',
        MessageKind.thanks => 'رسالة شكر',
        MessageKind.romantic => 'رسالة رومانسية',
        MessageKind.occasion => 'تهنئة بمناسبة',
      };

  String get emoji => switch (this) {
        MessageKind.morning => '🌅',
        MessageKind.evening => '🌙',
        MessageKind.apology => '🙏',
        MessageKind.thanks => '🤍',
        MessageKind.romantic => '💕',
        MessageKind.occasion => '🎉',
      };
}

/// نبرة الرسالة
enum MessageTone { romantic, gentle, playful, formal }

extension MessageToneX on MessageTone {
  String get label => switch (this) {
        MessageTone.romantic => 'رومانسية',
        MessageTone.gentle => 'لطيفة',
        MessageTone.playful => 'مرحة',
        MessageTone.formal => 'رسمية',
      };
}

/// مستوى صعوبة/عمق الأسئلة
enum QuestionLevel { light, deep, spicy }

extension QuestionLevelX on QuestionLevel {
  String get label => switch (this) {
        QuestionLevel.light => 'خفيفة',
        QuestionLevel.deep => 'عميقة',
        QuestionLevel.spicy => 'جريئة',
      };
}

/// ===== طلب موحد لأي مهمة AI =====
/// السياق (context) لا يحمل أي بيانات شخصية إلا ما تحتاجه المهمة فعلًا
class AIRequest {
  final AITask task;
  final Map<String, dynamic> context;
  final String language; // 'ar' الآن، جاهز لتعدد اللغات

  const AIRequest({
    required this.task,
    this.context = const {},
    this.language = 'ar',
  });

  Map<String, dynamic> toMap() => {
        'task': task.name,
        'context': context,
        'language': language,
      };
}

/// ===== استجابة موحدة =====
class AIResponse {
  final List<String> items; // اقتراحات/أسئلة (قائمة)
  final String? text; // نص واحد (رسالة/تحليل)
  final Map<String, dynamic> extra;

  const AIResponse({this.items = const [], this.text, this.extra = const {}});

  bool get isEmpty => items.isEmpty && (text == null || text!.isEmpty);

  factory AIResponse.fromMap(Map<String, dynamic> map) => AIResponse(
        items: List<String>.from(map['items'] as List? ?? const []),
        text: map['text'] as String?,
        extra: Map<String, dynamic>.from(map['extra'] as Map? ?? const {}),
      );

  Map<String, dynamic> toMap() =>
      {'items': items, 'text': text, 'extra': extra};
}

/// سجل محادثة محفوظ محليًا
class AIHistoryEntry {
  final String taskName;
  final String title;
  final String content;
  final DateTime at;

  const AIHistoryEntry({
    required this.taskName,
    required this.title,
    required this.content,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
        'taskName': taskName,
        'title': title,
        'content': content,
        'at': at.toIso8601String(),
      };

  factory AIHistoryEntry.fromMap(Map<String, dynamic> map) => AIHistoryEntry(
        taskName: map['taskName'] as String? ?? '',
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// استثناء AI برسالة عربية
class AIException implements Exception {
  final String message;
  const AIException(this.message);
}
