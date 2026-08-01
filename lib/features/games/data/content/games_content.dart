import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/game_models.dart';

/// كل محتوى الألعاب في مكان واحد
/// لإضافة لعبة جديدة: أضف GameType + GameMeta + قائمة أسئلتها هنا فقط
class GamesContent {
  GamesContent._();

  /// البيانات الوصفية لكل الألعاب — ترتيب العرض في الشاشة
  static const List<GameMeta> allGames = [
    GameMeta(
      type: GameType.knowMe,
      title: 'اعرفني',
      description: 'أسئلة عميقة تقرّبكما أكثر',
      icon: Icons.psychology_alt_rounded,
      color: AppColors.primary,
      mode: AnswerMode.freeText,
    ),
    GameMeta(
      type: GameType.whoKnows,
      title: 'مين يعرف الثاني أكثر؟',
      description: 'جاوبا عن بعضكما… وشوفا التطابق',
      icon: Icons.favorite_rounded,
      color: Color(0xFFD4838C),
      mode: AnswerMode.choices,
      scoreOnMatch: true,
    ),
    GameMeta(
      type: GameType.wouldYouRather,
      title: 'لو خيروك',
      description: 'اختيارات صعبة… مين يشبه مين؟',
      icon: Icons.alt_route_rounded,
      color: AppColors.secondary,
      mode: AnswerMode.choices,
      scoreOnMatch: true,
    ),
    GameMeta(
      type: GameType.truth,
      title: 'الصراحة',
      description: 'أسئلة جريئة… بصراحة كاملة',
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFF9C7BB8),
      mode: AnswerMode.freeText,
    ),
    GameMeta(
      type: GameType.dares,
      title: 'التحديات',
      description: 'تحديات خفيفة تكسر الروتين',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE08E45),
      mode: AnswerMode.choices,
      rounds: 4,
    ),
    GameMeta(
      type: GameType.guess,
      title: 'التخمين',
      description: 'خمّن وش بيختار شريكك',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF5EA3A3),
      mode: AnswerMode.choices,
      scoreOnMatch: true,
    ),
    GameMeta(
      type: GameType.wheel,
      title: 'عجلة التحديات',
      description: 'لفّا العجلة وخلّ الحظ يقرر',
      icon: Icons.casino_rounded,
      color: Color(0xFFC9A227),
      mode: AnswerMode.choices,
      rounds: 3,
    ),
  ];

  static GameMeta metaOf(GameType type) =>
      allGames.firstWhere((g) => g.type == type);

  /// أسئلة نص حر — اعرفني
  static const List<String> knowMePrompts = [
    'وش أكثر لحظة حسيت فيها إني أفهمك بدون كلام؟',
    'لو نسافر بكرة الصبح، وين تبينا نروح وليش؟',
    'وش الشي اللي تتمنى أسويه أكثر؟',
    'وش أول انطباع أخذته عني؟ وهل تغيّر؟',
    'وش الحلم اللي تتمنى نحققه مع بعض؟',
    'متى حسيت إنك محظوظ فيني؟',
    'وش الشي اللي يريّحك لما تكون متضايق؟',
    'لو تقدر تغيّر عادة وحدة عندي، وش بتكون؟ 😄',
    'وش أكثر شي تخاف منه في المستقبل؟',
    'وش الرسالة اللي ودك توصلها لي وما قلتها؟',
  ];

  /// أسئلة اختيارات — مين يعرف الثاني أكثر (كلاكما يجاوب عن نفس الشي)
  static const List<Map<String, dynamic>> whoKnowsQuestions = [
    {'q': 'وش الأكلة المفضلة عند شريكك؟', 'o': ['مندي 🍖', 'برجر 🍔', 'باستا 🍝', 'سوشي 🍣']},
    {'q': 'وقت شريكك المفضل في اليوم؟', 'o': ['الفجر 🌅', 'الظهر ☀️', 'العصر 🌇', 'الليل 🌙']},
    {'q': 'لو شريكك زعلان، وش يبي؟', 'o': ['كلام حلو 💬', 'سكوت وقربك 🤍', 'أكل 😋', 'طلعة 🚗']},
    {'q': 'وش يفضل شريكك في الإجازة؟', 'o': ['سفر ✈️', 'بحر 🏖️', 'بيت وأفلام 🎬', 'طلعات مع الأهل 👨‍👩‍👧']},
    {'q': 'مشروب شريكك المفضل؟', 'o': ['قهوة ☕', 'شاهي 🍵', 'عصير 🧃', 'موية بس 😅']},
  ];

  /// لو خيروك
  static const List<Map<String, dynamic>> wouldYouRatherQuestions = [
    {'q': 'لو خيروك…', 'o': ['سفر كل شهر بدون توفير 🧳', 'توفير وبيت أحلامكما 🏡']},
    {'q': 'لو خيروك…', 'o': ['عشاء فاخر مرة بالشهر 🍽️', 'طلعات بسيطة كل أسبوع 🌯']},
    {'q': 'لو خيروك…', 'o': ['تعرف المستقبل 🔮', 'تغيّر الماضي ⏪']},
    {'q': 'لو خيروك…', 'o': ['شتاء دائم 🌧️', 'صيف دائم ☀️']},
    {'q': 'لو خيروك…', 'o': ['أسبوع بدون جوال 📵', 'أسبوع بدون قهوة ☕']},
  ];

  /// الصراحة
  static const List<String> truthPrompts = [
    'وش أكثر موقف أحرجك قدامي؟ 😅',
    'صارحني: وش الشي اللي أسويه ويضحكك من داخل؟',
    'وش أكثر شي غيّرته في نفسك عشاني؟',
    'هل فيه شي تسويه وتخاف أعرفه؟ 👀',
    'وش أول شي لفت نظرك فيني؟ بصراحة كاملة',
    'متى آخر مرة حسيت بالغيرة؟ واحكِ الموقف',
    'وش الشي اللي تتمنى أقوله لك أكثر؟',
    'لو ترجع لأول يوم تعرفنا، وش بتغيّر؟',
  ];

  /// التحديات (يجاوب كل طرف: سويتها أو أتجاوز)
  static const List<String> darePrompts = [
    'أرسل لشريكك رسالة صوتية تغني فيها مقطع من أغنية 🎤',
    'صوّر نفسك بأغرب وجه وأرسلها 🤪',
    'اكتب لشريكك 3 أشياء تحبها فيه… الحين!',
    'اتصل بشريكك وقل له "أحبك" بثلاث لهجات مختلفة 😂',
  ];
  static const List<String> dareOptions = ['سويتها ✅', 'أتجاوز 😅'];

  /// التخمين — خمّن وش بيختار شريكك
  static const List<Map<String, dynamic>> guessQuestions = [
    {'q': 'لو شريكك يربح مليون، أول شي بيسويه؟', 'o': ['بيت 🏡', 'سيارة 🚗', 'سفر ✈️', 'استثمار 📈']},
    {'q': 'وش بيختار شريكك: طلعة مفاجئة ولا خطة مرتبة؟', 'o': ['مفاجئة 🎉', 'مرتبة 📋']},
    {'q': 'شريكك في الزحمة…', 'o': ['هادي 😌', 'يتنرفز 😤', 'يغني 🎶', 'يتصل فيك 📱']},
    {'q': 'لو خيّرنا شريكك بحيوان أليف؟', 'o': ['قطة 🐱', 'كلب 🐶', 'طيور 🦜', 'ولا شي 😅']},
    {'q': 'وش بيطلب شريكك في الكوفي؟', 'o': ['لاتيه ☕', 'إسبريسو ⚡', 'شاهي 🍵', 'آيس كوفي 🧊']},
  ];

  /// عناصر العجلة (8 أقسام ثابتة)
  static const List<String> wheelItems = [
    'أرسل صورة قديمة لكما 📸',
    'قل 3 أشياء تحبها في شريكك 💗',
    'خطط لمكالمة فيديو الليلة 📹',
    'أرسل رسالة صوتية رومانسية 🎙️',
    'شارك أغنية تذكرك بشريكك 🎵',
    'احكِ ذكرى مضحكة صارت لكما 😂',
    'أرسل إيموجي يصف شعورك الحين 😍',
    'اكتب بيت شعر لشريكك ✍️',
  ];
  static const List<String> wheelOptions = ['تم التحدي ✅', 'أتجاوز 😅'];
}
