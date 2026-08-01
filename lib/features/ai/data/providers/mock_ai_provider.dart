import 'dart:math';

import '../models/ai_models.dart';
import 'ai_provider.dart';

/// مزود تجريبي يعمل بدون إنترنت ولا مفاتيح API
/// مفيد للتطوير والتجربة قبل نشر Cloud Function
class MockAIProvider extends AIProvider {
  final Random _rand = Random();

  @override
  String get id => 'mock';

  @override
  String get displayName => 'مساعد تجريبي (بدون إنترنت)';

  List<String> _pick(List<String> src, int n) {
    final copy = List<String>.from(src)..shuffle(_rand);
    return copy.take(n).toList();
  }

  @override
  Future<AIResponse> complete(AIRequest request) async {
    // محاكاة زمن الاستجابة
    await Future.delayed(const Duration(milliseconds: 900));
    final ctx = request.context;

    switch (request.task) {
      case AITask.dateIdeas:
        return AIResponse(items: _pick(const [
          'موعد عشاء افتراضي: اطلبا نفس الأكل وافتحا مكالمة فيديو 🍽️',
          'شاهدا فيلمًا بالتزامن وعلّقا عليه في الرسائل 🎬',
          'جولة افتراضية: كل واحد يصور حيّه ويشرحه للثاني 🚶',
          'اطبخا نفس الوصفة كل في بيته وقارنا النتيجة 👨‍🍳',
          'خططا معًا لأول رحلة بعد الزواج على الخريطة 🗺️',
        ], 3));

      case AITask.activitySuggestion:
        final hour = ctx['hour'] as int? ?? DateTime.now().hour;
        final byTime = hour < 12
            ? ['أرسلا لبعض رسالة صوتية صباحية ☀️', 'شاركا خطة يومكما ودعوة قصيرة 🌅']
            : hour < 18
                ? ['العبا "لو خيروك" في استراحة الغداء 🎮', 'أرسل صورة من يومك الآن 📸']
                : ['مكالمة فيديو هادئة قبل النوم 🌙', 'العبا "اعرفني" واختما اليوم بسؤال عميق 💭'];
        return AIResponse(items: byTime);

      case AITask.gameSuggestion:
        return AIResponse(items: _pick(const [
          'جربا "اعرفني" — أسئلة عميقة تكشف جديدًا عن بعضكما',
          'العبا "مين يعرف الثاني أكثر؟" وتنافسا على التطابق',
          '"عجلة التحديات" مناسبة لو تبيان شي سريع وممتع',
        ], 2));

      case AITask.challengeIdeas:
        return AIResponse(items: _pick(const [
          'تحدي الأسبوع: كل يوم أرسلا لبعض شيئًا تشكرانه عليه 🙏',
          'تحدي الصور: كل واحد يرسل صورة لشيء يذكره بالثاني 📷',
          'تحدي السؤال: سؤال جديد كل ليلة قبل النوم ❓',
          'تحدي الطبخ: نفس الوصفة، ومن يطلع أحلى؟ 🍳',
        ], 3));

      case AITask.giftSuggestion:
        final coins = ctx['coins'] as int? ?? 0;
        return AIResponse(items: [
          if (coins >= 50) 'وردة حمراء 🌹 — بسيطة وتوصل المعنى',
          if (coins >= 150) 'باقة ورد 💐 — مناسبة لمناسبة خاصة',
          if (coins >= 80) 'رسالة حب 💌 — أضف كلمات من قلبك',
          if (coins < 50) 'اجمع عملات أكثر بلعبة سريعة، وبعدها اختر هدية 🎮',
        ]);

      case AITask.writeMessage:
        final kind = ctx['kind'] as String? ?? 'romantic';
        final tone = ctx['tone'] as String? ?? 'romantic';
        return AIResponse(
            text: _mockMessage(kind, tone),
            extra: {'kind': kind, 'tone': tone});

      case AITask.generateQuestions:
        final level = ctx['level'] as String? ?? 'light';
        final pool = switch (level) {
          'deep' => const [
              'وش أكثر لحظة غيّرت نظرتك للحياة؟',
              'وش الشي اللي تخاف أفقده فيك؟',
              'كيف تتخيل حياتنا بعد عشر سنين؟',
              'وش الدرس اللي تعلمته من أصعب فترة مرت عليك؟',
            ],
          'spicy' => const [
              'وش أكثر شي يجذبك فيني ما قلته لي؟',
              'متى حسيت بالغيرة آخر مرة؟',
              'وش الشي اللي ودك نجربه مع بعض ومحرج تقوله؟',
            ],
          _ => const [
              'وش أكثر أكلة تشتهيها الحين؟',
              'لو نسافر بكرة، وين؟',
              'وش آخر شي ضحكك بصوت عالي؟',
              'وش أغنيتك المفضلة هالفترة؟',
            ],
        };
        final exclude =
            List<String>.from(ctx['exclude'] as List? ?? const []);
        final fresh =
            pool.where((q) => !exclude.contains(q)).toList();
        return AIResponse(
            items: _pick(fresh.isEmpty ? pool : fresh, 3));

      case AITask.relationshipInsights:
        return AIResponse(text: _mockInsights(ctx));
    }
  }

  String _mockMessage(String kind, String tone) {
    final base = switch (kind) {
      'morning' => 'صباحك ورد 🌅\nأول ما فتحت عيني تذكرتك… أتمنى لك يومًا جميلًا مثلك.',
      'evening' => 'مساء الخير 🌙\nيومي ما اكتمل إلا لما كلمتك. تصبح على خير يا أغلى الناس.',
      'apology' => 'أعتذر منك بصدق 🙏\nما كان قصدي أزعلك، وأنت أهم من أي خلاف. سامحني؟',
      'thanks' => 'شكرًا لك 🤍\nوجودك في حياتي نعمة، وما أقصر معي أبدًا. أقدّر كل شي تسويه.',
      'occasion' => 'مبروك! 🎉\nكل عام وأنت بخير، وكل سنة وأنا أقرب لك أكثر.',
      _ => 'أحبك 💕\nالمسافة بيننا ما تعني شي… قلبي عندك دائمًا.',
    };
    final touch = switch (tone) {
      'playful' => '\n\nوبالمناسبة… دورك ترد برسالة أحلى 😏',
      'formal' => '\n\nمع خالص التقدير والمودة.',
      'gentle' => '\n\nخذ راحتك، وأنا هنا دائمًا 🤍',
      _ => '\n\nمشتاق لك أكثر مما تتخيل 💗',
    };
    return base + touch;
  }

  String _mockInsights(Map<String, dynamic> ctx) {
    final games = ctx['gamesPlayed'] as int? ?? 0;
    final streak = ctx['streak'] as int? ?? 0;
    final memories = ctx['memories'] as int? ?? 0;
    final gifts = ctx['gifts'] as int? ?? 0;
    final level = ctx['level'] as int? ?? 1;

    final b = StringBuffer();
    b.writeln('📊 ملخص علاقتكما\n');
    b.writeln('وصلتما للمستوى $level، ولعبتما $games لعبة معًا.');
    if (streak >= 3) {
      b.writeln('ستريككما $streak أيام 🔥 — استمراريتكما ممتازة، حافظا عليها!');
    } else if (streak > 0) {
      b.writeln('ستريككما $streak — لعبة واحدة يوميًا تكفي لتكبيره.');
    } else {
      b.writeln('ما فيه ستريك حاليًا — ابدآ اليوم بلعبة سريعة وارجعا للمسار 🔥');
    }
    b.writeln('حفظتما $memories ذكرى وتبادلتما $gifts هدية.\n');
    b.writeln('💡 اقتراحات:');
    if (memories < 3) b.writeln('• أضيفا ذكرى هذا الأسبوع — الصور تبني أرشيفكما');
    if (gifts < 2) b.writeln('• هدية صغيرة مفاجئة ترفع المزاج كثيرًا 🎁');
    if (games < 5) b.writeln('• جربا لعبة جديدة ما لعبتماها من قبل');
    b.writeln('• خصصا وقتًا ثابتًا يوميًا للتواصل — الانتظام أهم من الطول');
    return b.toString();
  }
}
