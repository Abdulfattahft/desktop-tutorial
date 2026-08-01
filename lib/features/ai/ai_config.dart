import 'data/providers/ai_provider.dart';
import 'data/providers/cloud_function_ai_provider.dart';
import 'data/providers/mock_ai_provider.dart';

/// ===== نقطة التبديل الوحيدة لمزود الذكاء الاصطناعي =====
///
/// للانتقال من التجريبي إلى الحقيقي:
/// 1. انشر الدالة: firebase deploy --only functions:aiAssistant
/// 2. ضع الرابط في cloudFunctionEndpoint أدناه
/// 3. غيّر activeProviderId إلى 'cloud_function'
///
/// لإضافة مزود جديد (OpenAI/Gemini/محلي):
/// 1. أنشئ صنفًا ينفّذ AIProvider
/// 2. سجّله في registerProviders()
/// 3. غيّر activeProviderId
/// لا شيء آخر في التطبيق يحتاج تعديلًا
class AIConfig {
  AIConfig._();

  /// رابط الدالة بعد النشر
  /// مثال: https://us-central1-baynana-app.cloudfunctions.net/aiAssistant
  static const String cloudFunctionEndpoint = '';

  /// المزود النشط حاليًا
  static const String activeProviderId = 'mock';

  /// تسجيل كل المزودين المتاحين
  static void registerProviders() {
    AIProviderRegistry.register('mock', () => MockAIProvider());
    AIProviderRegistry.register(
      'cloud_function',
      () => CloudFunctionAIProvider(endpoint: cloudFunctionEndpoint),
    );
    AIProviderRegistry.register(
      'remote_configured',
      () => RemoteConfiguredAIProvider(),
    );
  }

  /// بناء المزود النشط (مع رجوع آمن للتجريبي)
  static AIProvider buildActive() =>
      AIProviderRegistry.build(activeProviderId) ?? MockAIProvider();
}
