import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/ai_models.dart';
import 'ai_provider.dart';

/// مزود يمر عبر Cloud Function
///
/// لماذا Cloud Function ولا نستدعي المزود مباشرة؟
/// لأن مفتاح API لا يجوز وضعه داخل التطبيق — يمكن استخراجه من ملف
/// التطبيق بسهولة. الـ Function تحمل المفتاح سرًا على الخادم.
class CloudFunctionAIProvider extends AIProvider {
  /// رابط الدالة بعد النشر، مثل:
  /// https://us-central1-<project-id>.cloudfunctions.net/aiAssistant
  final String endpoint;

  CloudFunctionAIProvider({required this.endpoint});

  @override
  String get id => 'cloud_function';

  @override
  String get displayName => 'مساعد بيننا';

  @override
  bool get supportsStreaming => false; // يمكن تفعيله لاحقًا بـ SSE

  @override
  Future<AIResponse> complete(AIRequest request) async {
    if (endpoint.isEmpty) {
      throw const AIException(
          'خدمة المساعد غير مُهيّأة بعد — راجع إعدادات المشروع');
    }
    try {
      // رمز المصادقة يضمن أن المستخدم مسجّل فعلًا
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final res = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toMap()),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw AIException(
            'تعذر الاتصال بالمساعد (${res.statusCode})، حاول مرة أخرى');
      }
      final decoded =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return AIResponse.fromMap(decoded);
    } on AIException {
      rethrow;
    } catch (_) {
      throw const AIException('تعذر الاتصال بالمساعد، تأكد من الإنترنت');
    }
  }
}

/// مزود بديل يقرأ الرابط من إعدادات Firestore (config/ai)
/// يسمح بتغيير المزود أو الرابط بدون تحديث التطبيق
class RemoteConfiguredAIProvider extends AIProvider {
  @override
  String get id => 'remote_configured';

  @override
  String get displayName => 'مساعد بيننا (إعداد بعيد)';

  String? _cachedEndpoint;

  Future<String> _resolveEndpoint() async {
    if (_cachedEndpoint != null) return _cachedEndpoint!;
    final doc =
        await FirebaseFirestore.instance.collection('config').doc('ai').get();
    _cachedEndpoint = doc.data()?['endpoint'] as String? ?? '';
    return _cachedEndpoint!;
  }

  @override
  Future<AIResponse> complete(AIRequest request) async {
    final endpoint = await _resolveEndpoint();
    return CloudFunctionAIProvider(endpoint: endpoint).complete(request);
  }
}
