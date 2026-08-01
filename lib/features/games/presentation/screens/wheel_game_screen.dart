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

class WheelGameScreen extends StatefulWidget {
  const WheelGameScreen({super.key});

  @override
  State<WheelGameScreen> createState() => _WheelGameScreenState();
}

class _WheelGameScreenState extends State<WheelGameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
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
    _animatingToIndex = null;
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎡', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(
                    'خلصت العجلة!',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جمعتما ${session.score} نقطة ⭐ و +15 عملة لكل واحد 🪙',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('رجوع للألعاب'),
                  ),
                ],
              ),
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

              if (spun && _animatingToIndex != round.wheelIndex) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _animateTo(round.wheelIndex!),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final padding = width < 380 ? 12.0 : width < 700 ? 18.0 : 24.0;
                  final wheelDiameter =
                      (width - (padding * 2) - 16).clamp(210.0, 300.0).toDouble();
                  final wheelHeight = wheelDiameter + 38;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(padding, 8, padding, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          children: [
                            Text(
                              'اللفة ${session.currentRound + 1} من ${session.rounds.length} — ⭐ ${session.score}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: wheelDiameter + 20,
                              height: wheelHeight,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Positioned(
                                    top: 20,
                                    child: AnimatedBuilder(
                                      animation: _spinCtrl,
                                      builder: (context, child) => Transform.rotate(
                                        angle: -(_rotation?.value ?? 0),
                                        child: child,
                                      ),
                                      child: CustomPaint(
                                        size: Size(wheelDiameter, wheelDiameter),
                                        painter: _WheelPainter(),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: wheelDiameter < 240 ? 44 : 52,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (!spun)
                              ElevatedButton.icon(
                                onPressed: _spin,
                                icon: const Icon(Icons.casino_rounded),
                                label: const Text('لفّ العجلة!'),
                              )
                                  .animate()
                                  .fadeIn()
                                  .scale(begin: const Offset(0.9, 0.9))
                            else ...[
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(width < 380 ? 14 : 18),
                                  child: Column(
                                    children: [
                                      Text(
                                        'التحدي 🔥',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        round.prompt,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(height: 1.55),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                              const SizedBox(height: 16),
                              if (revealed) ...[
                                Text(
                                  'أنتما الاثنان جاوبتما ✅',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _next,
                                  child: Text(
                                    session.isLastRound
                                        ? 'إنهاء اللعبة 🏁'
                                        : 'لفة جديدة 🎡',
                                  ),
                                ),
                              ] else if (iAnswered)
                                Text(
                                  'بانتظار شريكك… 💗',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .fadeIn(duration: 700.ms)
                              else
                                LayoutBuilder(
                                  builder: (context, answerConstraints) {
                                    final oneColumn = answerConstraints.maxWidth < 360;
                                    final optionWidth = oneColumn
                                        ? answerConstraints.maxWidth
                                        : (answerConstraints.maxWidth - 10) / 2;
                                    return Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: GamesContent.wheelOptions
                                          .map(
                                            (option) => SizedBox(
                                              width: optionWidth,
                                              child: OutlinedButton(
                                                onPressed: () => _answer(option),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(0, 52),
                                                  side: const BorderSide(
                                                    color: AppColors.secondary,
                                                    width: 1.5,
                                                  ),
                                                  foregroundColor: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: Text(
                                                  option,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
      final start = -math.pi / 2 + (i * segmentAngle) - segmentAngle / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segmentAngle,
        true,
        paint,
      );
    }

    final emojiSize = (size.width * 0.085).clamp(16.0, 24.0).toDouble();
    for (var i = 0; i < _colors.length; i++) {
      final angle = -math.pi / 2 + (i * segmentAngle);
      final emoji = GamesContent.wheelItems[i].split(' ').last;
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: TextStyle(fontSize: emojiSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(
        center.dx + (radius * 0.68) * math.cos(angle) - tp.width / 2,
        center.dy + (radius * 0.68) * math.sin(angle) - tp.height / 2,
      );
      tp.paint(canvas, pos);
    }

    final centerRadius = (size.width * 0.1).clamp(20.0, 28.0).toDouble();
    canvas.drawCircle(center, centerRadius, Paint()..color = Colors.white);
    final heart = TextPainter(
      text: TextSpan(
        text: '💗',
        style: TextStyle(fontSize: centerRadius * 0.92),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    heart.paint(canvas, center - Offset(heart.width / 2, heart.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
