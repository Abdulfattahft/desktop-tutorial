import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/content/games_content.dart';
import '../../data/models/game_models.dart';
import '../viewmodels/games_viewmodel.dart';

/// شاشة اللعب الموحدة — تشغّل أي لعبة (نص حر أو اختيارات)
/// المزامنة عبر Stream: كل تغيير من أي طرف يظهر مباشرة عند الآخر
class GamePlayScreen extends StatefulWidget {
  final GameType gameType;
  const GamePlayScreen({super.key, required this.gameType});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  final _textCtrl = TextEditingController();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  bool _finishedShown = false;

  GameMeta get meta => GamesContent.metaOf(widget.gameType);

  @override
  void dispose() {
    _textCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _submit(String answer) async {
    if (answer.trim().isEmpty) return;
    final user = context.read<AuthViewModel>().currentUser!;
    final vm = context.read<GamesViewModel>();
    final session = _lastSession;
    if (session == null) return;

    await vm.submitAnswer(
      coupleId: user.coupleId!,
      type: widget.gameType,
      roundIndex: session.currentRound,
      uid: user.uid,
      answer: answer.trim(),
    );
    _textCtrl.clear();
  }

  Future<void> _next() async {
    final user = context.read<AuthViewModel>().currentUser!;
    final session = _lastSession;
    if (session == null) return;
    await context.read<GamesViewModel>().advanceOrFinish(
          coupleId: user.coupleId!,
          type: widget.gameType,
          fromRound: session.currentRound,
        );
  }

  GameSession? _lastSession;

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
                const Text('🏆', style: TextStyle(fontSize: 56))
                    .animate()
                    .scale(curve: Curves.elasticOut, duration: 700.ms),
                const SizedBox(height: 12),
                Text('انتهت اللعبة!',
                    style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'جمعتما ${session.score} نقطة لعلاقتكما ⭐\nو +15 عملة لكل واحد فيكما 🪙',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.7),
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
      appBar: AppBar(title: Text(meta.title)),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          StreamBuilder<GameSession?>(
            stream: vm.sessionStream(user.coupleId!, widget.gameType),
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
              final iAnswered = round.answeredBy(user.uid);
              final revealed = round.bothAnswered;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شريط التقدم
                    Row(
                      children: [
                        Text(
                          'الجولة ${session.currentRound + 1} من ${session.rounds.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text('⭐ ${session.score}',
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (session.currentRound + (revealed ? 1 : 0.4)) /
                                session.rounds.length,
                        minHeight: 8,
                        backgroundColor: AppColors.surface,
                        color: meta.color,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // بطاقة السؤال
                    Card(
                      key: ValueKey('q${session.currentRound}'),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Icon(meta.icon, color: meta.color, size: 36),
                            const SizedBox(height: 14),
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
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),

                    // ===== حالات الجولة =====
                    if (revealed)
                      _RevealSection(
                        round: round,
                        user: user,
                        meta: meta,
                        isLast: session.isLastRound,
                        onNext: _next,
                      )
                    else if (iAnswered)
                      const _WaitingPartner()
                    else
                      _AnswerSection(
                        meta: meta,
                        round: round,
                        textCtrl: _textCtrl,
                        onSubmit: _submit,
                      ),
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

/// قسم الإجابة (نص حر أو اختيارات)
class _AnswerSection extends StatelessWidget {
  final GameMeta meta;
  final GameRound round;
  final TextEditingController textCtrl;
  final Future<void> Function(String) onSubmit;

  const _AnswerSection({
    required this.meta,
    required this.round,
    required this.textCtrl,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (meta.mode == AnswerMode.freeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: textCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(hintText: 'اكتب إجابتك هنا…'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => onSubmit(textCtrl.text),
            child: const Text('إرسال الإجابة'),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms);
    }

    // وضع الاختيارات
    return Column(
      children: round.options.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton(
            onPressed: () => onSubmit(e.value),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: meta.color, width: 1.5),
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(e.value, textAlign: TextAlign.center),
          )
              .animate()
              .fadeIn(delay: (100 * e.key).ms)
              .slideX(begin: 0.1, curve: Curves.easeOutCubic),
        );
      }).toList(),
    );
  }
}

/// انتظار الطرف الآخر — نبض قلب
class _WaitingPartner extends StatelessWidget {
  const _WaitingPartner();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 56)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.25, 1.25),
                duration: 700.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 14),
        Text(
          'أرسلنا إجابتك ✅\nبانتظار شريكك…',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    ).animate().fadeIn();
  }
}

/// كشف الإجابتين + زر التالي
class _RevealSection extends StatelessWidget {
  final GameRound round;
  final UserModel user;
  final GameMeta meta;
  final bool isLast;
  final VoidCallback onNext;

  const _RevealSection({
    required this.round,
    required this.user,
    required this.meta,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final myAnswer = round.answers[user.uid] ?? '';
    final partnerAnswer = round.answers.entries
        .firstWhere((e) => e.key != user.uid,
            orElse: () => const MapEntry('', ''))
        .value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (round.isMatch == true)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '🎉 تطابقتما! +5 نقاط إضافية',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        if (round.isMatch == true) const SizedBox(height: 14),

        _AnswerCard(label: 'إجابتك', answer: myAnswer, color: meta.color)
            .animate()
            .fadeIn()
            .slideX(begin: -0.08),
        const SizedBox(height: 12),
        _AnswerCard(
                label: 'إجابة شريكك 💕',
                answer: partnerAnswer,
                color: AppColors.secondary)
            .animate()
            .fadeIn(delay: 200.ms)
            .slideX(begin: 0.08),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onNext,
          child: Text(isLast ? 'إنهاء اللعبة 🏁' : 'الجولة التالية ←'),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String label;
  final String answer;
  final Color color;

  const _AnswerCard(
      {required this.label, required this.answer, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(answer,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
