import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/content/games_content.dart';
import '../../data/models/game_models.dart';
import '../viewmodels/games_viewmodel.dart';

/// عجلة التحديات — عجلة مرسومة يدويًا (بدون حزم إضافية)
/// أول طرف يلفّ يحدد النتيجة للطرفين عبر Transaction
class WheelGameScreen extends StatefulWidget {
  const WheelGameScreen({super.key});

  @override
  State<WheelGameScreen> createState() => _WheelGameScreenState();
}

class _WheelGameScreenState extends State<WheelGameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  Animation<double>? _rotation;
  int? _animatingToIndex;
  bool _finishedShown = false;
  GameSession? _lastSession;

  static const int _segments = 8;

  @override
  void dispose() {
    _spinCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// لفّ العجلة: نطلب النتيجة من الـ Transaction ثم نحرك العجلة إليها
  Future<void> _spin() async {
    final user = context.read<AuthViewModel>().currentUser!;
    final session = _lastSession;
    if (session == null || _spinCtrl.isAnimating) return;

    final idx = await context.read<GamesViewModel>().spinWheel(
          coupleId: user.coupleId!,
          roundIndex: session.currentRound,
        );
    if (idx == null || !mounted) return;

    _animateTo(idx);
  }

  void _animateTo(int idx) {
    if (_animatingToIndex == idx || _spinCtrl.isAnimating) return;
    _animatingToIndex = idx;

    // زاوية القطاع المستهدف (يتوقف المؤشر عند منتصفه) + 4 لفات كاملة
    final segmentAngle = 2 * math.pi / _segments;
    final target = (4 * 2 * math.pi) + (idx * segmentAngle) + segmentAngle / 2;

    _rotation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutQuart),
    );
    _spinCtrl.forward(from: 0);
  }

  Future<void> _answer(String value) async {
    final user = context.read<AuthViewModel>().currentUser!;
    final session = _lastSession;
    if (session == null) return;
    await context.read<GamesViewModel>().submitAnswer(
          coupleId: user.coupleId!,
          type: GameType.wheel,
          roundIndex: session.currentRound,
          uid: user.uid,
          answer: value,
        );
  }

  Future<void> _next() async {
    final user = context.read<AuthViewModel>().currentUser!;
    final session = _lastSession;
    if (session == null) return;
    _animatingToIndex = null; // عجلة جديدة للجولة القادمة
    await context.read<GamesViewModel>().advanceOrFinish(
          coupleId: user.coupleId!,
          type: GameType.wheel,
          fromRound: session.currentRound,
        );
  }

  void _showResults(GameSession session) {
    if (_finishedShown) return;
    _finishedShown = true;
    _confetti.play();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎡', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text('خلصت العجلة!',
                    style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'جمعتما ${session.score} نقطة ⭐ و +15 عملة لكل واحد 🪙',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('رجوع للألعاب'),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<GamesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('عجلة التحديات 🎡')),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          StreamBuilder<GameSession?>(
            stream: vm.sessionStream(user.coupleId!, GameType.wheel),
            builder: (context, snap) {
              final session = snap.data;
              _lastSession = session;
              if (session == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (session.status == SessionStatus.finished) {
                _showResults(session);
                return const SizedBox.shrink();
              }

              final round = session.round;
              final spun = round.wheelIndex != null;
              final iAnswered = round.answeredBy(user.uid);
              final revealed = round.bothAnswered;

              // الطرف الآخر لفّ من جهازه؟ حرّك عجلتنا لنفس النتيجة
              if (spun && _animatingToIndex != round.wheelIndex) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _animateTo(round.wheelIndex!));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'اللفة ${session.currentRound + 1} من ${session.rounds.length} — ⭐ ${session.score}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // ===== العجلة =====
                    SizedBox(
                      width: 280,
                      height: 300,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 20,
                            child: AnimatedBuilder(
                              animation: _spinCtrl,
                              builder: (context, child) => Transform.rotate(
                                // سالب: العجلة تدور والمؤشر ثابت أعلاها
                                angle: -(_rotation?.value ?? 0),
                                child: child,
                              ),
                              child: CustomPaint(
                                size: const Size(260, 260),
                                painter: _WheelPainter(),
                              ),
                            ),
                          ),
                          // المؤشر
                          const Icon(Icons.arrow_drop_down_rounded,
                              size: 52, color: AppColors.textPrimary),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ===== حالات الجولة =====
                    if (!spun)
                      ElevatedButton.icon(
                        onPressed: _spin,
                        icon: const Icon(Icons.casino_rounded),
                        label: const Text('لفّ العجلة!'),
                      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9))
                    else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Text('التحدي 🔥',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                              const SizedBox(height: 8),
                              Text(
                                round.prompt,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      if (revealed) ...[
                        Text(
                          'أنتما الاثنان جاوبتما ✅',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _next,
                          child: Text(session.isLastRound
                              ? 'إنهاء اللعبة 🏁'
                              : 'لفة جديدة 🎡'),
                        ),
                      ] else if (iAnswered)
                        Text(
                          'بانتظار شريكك… 💗',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fadeIn(duration: 700.ms)
                      else
                        Row(
                          children: GamesContent.wheelOptions.map((o) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: OutlinedButton(
                                  onPressed: () => _answer(o),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    side: const BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5),
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: Text(o),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.secondaryLight,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }
}

/// رسم العجلة: 8 قطاعات بألوان الهوية مع إيموجي كل تحدٍ
class _WheelPainter extends CustomPainter {
  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.secondaryLight,
    Color(0xFFD4838C),
    Color(0xFFE7C873),
    Color(0xFFE8A0A8),
    Color(0xFFC9A227),
    Color(0xFFF0B7BD),
    Color(0xFFDDBA55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / _colors.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _colors.length; i++) {
      paint.color = _colors[i];
      // القطاع i يتمركز أعلى العجلة عند دورانها بزاوية i*segment
      final start = -math.pi / 2 + (i * segmentAngle) - segmentAngle / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          segmentAngle, true, paint);
    }

    // إيموجي كل قطاع
    for (var i = 0; i < _colors.length; i++) {
      final angle = -math.pi / 2 + (i * segmentAngle);
      final emoji =
          GamesContent.wheelItems[i].split(' ').last; // آخر جزء = الإيموجي
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: const TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(
        center.dx + (radius * 0.68) * math.cos(angle) - tp.width / 2,
        center.dy + (radius * 0.68) * math.sin(angle) - tp.height / 2,
      );
      tp.paint(canvas, pos);
    }

    // مركز العجلة
    canvas.drawCircle(center, 26, Paint()..color = Colors.white);
    final heart = TextPainter(
      text: const TextSpan(text: '💗', style: TextStyle(fontSize: 24)),
      textDirection: TextDirection.ltr,
    )..layout();
    heart.paint(
        canvas, center - Offset(heart.width / 2, heart.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
