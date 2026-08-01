import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_viewmodel.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../data/models/ai_models.dart';
import '../viewmodels/ai_viewmodel.dart';

/// شاشة المساعد الذكي
class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.watch<AIViewModel>();
    final homeVm = context.read<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي 🤖'),
        actions: [
          IconButton(
            tooltip: 'إعدادات المساعد',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.aiSettings),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<CoupleModel?>(
          stream: user.coupleId != null
              ? homeVm.coupleStream(user.coupleId!)
              : const Stream.empty(),
          builder: (context, coupleSnap) {
            final couple = coupleSnap.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (!vm.aiEnabled)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ميزات المساعد معطّلة — فعّلها من الإعدادات',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                Text('وش تحتاج اليوم؟',
                        style: Theme.of(context).textTheme.headlineMedium)
                    .animate()
                    .fadeIn(),
                const SizedBox(height: 4),
                Text('مساعدك لأفكار وكلمات تقرّبكما أكثر',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),

                // ===== شبكة المهام =====
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 1000 ? 4 : MediaQuery.sizeOf(context).width >= 650 ? 3 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _TaskCard(
                        task: AITask.dateIdeas,
                        onTap: () => vm.dateIdeas()),
                    _TaskCard(
                        task: AITask.activitySuggestion,
                        onTap: () => vm.activityNow()),
                    _TaskCard(
                        task: AITask.writeMessage,
                        onTap: () =>
                            _openMessageSheet(context, vm)),
                    _TaskCard(
                        task: AITask.generateQuestions,
                        onTap: () =>
                            _openQuestionsSheet(context, vm)),
                    _TaskCard(
                        task: AITask.challengeIdeas,
                        onTap: () => vm.challengeIdeas()),
                    _TaskCard(
                        task: AITask.giftSuggestion,
                        onTap: () =>
                            vm.giftSuggestion(user.coins)),
                    _TaskCard(
                        task: AITask.gameSuggestion,
                        onTap: () => vm.gameSuggestion(
                            couple?.gamesPlayedTotal ?? 0)),
                    _TaskCard(
                      task: AITask.relationshipInsights,
                      onTap: () => _runInsights(vm, user, couple),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ===== النتيجة =====
                if (vm.isLoading)
                  const _ThinkingCard()
                else if (vm.errorMessage != null)
                  _ErrorCard(message: vm.errorMessage!)
                else if (vm.result != null && !vm.result!.isEmpty)
                  _ResultCard(
                      response: vm.result!, task: vm.lastTask),

                // ===== السجل =====
                if (vm.history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('آخر الاقتراحات 🕘',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: vm.clearHistory,
                        child: const Text('مسح',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                  ...vm.history.take(5).map((h) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          title: Text(h.title,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(h.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: h.content));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('تم النسخ ✅'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ));
                            },
                          ),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _runInsights(
      AIViewModel vm, UserModel user, CoupleModel? couple) {
    vm.insights(
      gamesPlayed: couple?.gamesPlayedTotal ?? 0,
      streak: couple?.streak ?? 0,
      challengesDone: 0,
      memories: 0,
      gifts: 0,
      level: couple?.level ?? 1,
      totalPoints: couple?.totalPoints ?? 0,
    );
  }

  /// ورقة اختيار نوع الرسالة والنبرة
  void _openMessageSheet(BuildContext context, AIViewModel vm) {
    MessageKind kind = MessageKind.romantic;
    MessageTone tone = MessageTone.romantic;
    final occasionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اكتب رسالة 💌',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text('النوع', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MessageKind.values
                    .map((k) => ChoiceChip(
                          label: Text('${k.emoji} ${k.label}'),
                          selected: kind == k,
                          onSelected: (_) => setSheet(() => kind = k),
                          showCheckmark: false,
                          selectedColor:
                              AppColors.primary.withOpacity(0.2),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('النبرة', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: MessageTone.values
                    .map((t) => ChoiceChip(
                          label: Text(t.label),
                          selected: tone == t,
                          onSelected: (_) => setSheet(() => tone = t),
                          showCheckmark: false,
                          selectedColor:
                              AppColors.secondary.withOpacity(0.2),
                        ))
                    .toList(),
              ),
              if (kind == MessageKind.occasion) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: occasionCtrl,
                  decoration: const InputDecoration(
                      hintText: 'المناسبة (عيد ميلاد، ذكرى…)'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  vm.writeMessage(
                      kind: kind,
                      tone: tone,
                      occasion: occasionCtrl.text);
                },
                child: const Text('اكتب لي ✍️'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ورقة اختيار مستوى الأسئلة
  void _openQuestionsSheet(BuildContext context, AIViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مستوى الأسئلة ❓',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...QuestionLevel.values.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // نستبعد أسئلة السجل لتفادي التكرار
                      final previous = vm.history
                          .where((h) =>
                              h.taskName == AITask.generateQuestions.name)
                          .expand((h) => h.content.split('\n• '))
                          .toList();
                      vm.generateQuestions(
                          level: l, exclude: previous);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(l.label),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final AITask task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(task.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(task.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                          fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// بطاقة "يفكر…" مع نبض
class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 34))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 700.ms),
            const SizedBox(height: 12),
            Text('أفكر لك…',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    ).animate().fadeIn();
  }
}

/// بطاقة النتيجة مع زر نسخ
class _ResultCard extends StatelessWidget {
  final AIResponse response;
  final AITask? task;

  const _ResultCard({required this.response, this.task});

  @override
  Widget build(BuildContext context) {
    final content =
        response.text ?? response.items.map((e) => '• $e').join('\n\n');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(task?.emoji ?? '✨',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(task?.label ?? 'اقتراح',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم النسخ ✅'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            Text(content,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.8)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }
}
