import '../models/ai_models.dart';

/// ===== الواجهة المجردة لأي مزود ذكاء اصطناعي =====
///
/// لإضافة مزود جديد (OpenAI / Gemini / Claude / محلي):
/// 1. أنشئ صنفًا جديدًا ينفّذ AIProvider
/// 2. سجّله في AIProviderRegistry
/// 3. غيّر السطر الواحد في main.dart
///
/// لا شيء آخر في التطبيق يحتاج تعديلًا — الشاشات والـ ViewModels
/// تتعامل مع AIRequest/AIResponse فقط
abstract class AIProvider {
  /// معرّف المزود (للإعدادات والسجلات)
  String get id;

  /// اسم للعرض
  String get displayName;

  /// هل يدعم البث التدريجي؟ (جاهز للمستقبل)
  bool get supportsStreaming => false;

  /// هل يدعم استدعاء الأدوات؟ (جاهز للمستقبل)
  bool get supportsTools => false;

  /// هل يدعم توليد الصور؟ (جاهز للمستقبل)
  bool get supportsImages => false;

  /// تنفيذ مهمة والحصول على النتيجة كاملة
  Future<AIResponse> complete(AIRequest request);

  /// بث تدريجي للنص — الافتراضي: نتيجة واحدة دفعة واحدة
  /// المزودون الداعمون يعيدون تعريفه
  Stream<String> stream(AIRequest request) async* {
    final res = await complete(request);
    if (res.text != null) yield res.text!;
  }

  /// توليد صورة — يرمي استثناءً ما لم يدعمه المزود
  Future<String> generateImage(String prompt) async {
    throw const AIException('توليد الصور غير مدعوم في هذا المزود');
  }
}

/// سجل المزودين المتاحين — يسهّل التبديل من الإعدادات مستقبلًا
class AIProviderRegistry {
  AIProviderRegistry._();

  static final Map<String, AIProvider Function()> _builders = {};

  static void register(String id, AIProvider Function() builder) {
    _builders[id] = builder;
  }

  static List<String> get availableIds => _builders.keys.toList();

  static AIProvider? build(String id) => _builders[id]?.call();
}
