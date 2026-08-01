import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/memory_model.dart';
import '../viewmodels/memories_viewmodel.dart';
import '../widgets/memory_card.dart';

/// شاشة الذكريات — Timeline زمني + "في مثل هذا اليوم"
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  Stream<List<MemoryModel>>? _memoriesStream;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<MemoriesViewModel>();
    _memoriesStream ??= vm.memoriesStream(user.coupleId!);

    return Scaffold(
      appBar: AppBar(title: const Text('ذكرياتنا 📸')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.memoriesAdd),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('ذكرى جديدة'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<MemoryModel>>(
          stream: _memoriesStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final memories = snap.data ?? const [];
            if (memories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 14),
                    Text('صفحاتكما ما زالت بيضاء',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text('أضيفا أول ذكرى واكتبا حكايتكما ✨',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ).animate().fadeIn(),
              );
            }

            final onThisDay =
                memories.where((m) => m.isOnThisDay).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                // ===== في مثل هذا اليوم =====
                if (onThisDay.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.romanticGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🗓️ في مثل هذا اليوم',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        ...onThisDay.map((m) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${m.title} — قبل ${m.yearsAgo == 1 ? "سنة" : m.yearsAgo == 2 ? "سنتين" : "${m.yearsAgo} سنوات"} 💕',
                                style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.95),
                                    fontSize: 13.5),
                              ),
                            )),
                      ],
                    ),
                  ).animate().fadeIn().shimmer(
                      delay: 400.ms,
                      duration: 1500.ms,
                      color: Colors.white24),
                  const SizedBox(height: 18),
                ],

                // ===== الـ Timeline =====
                ...memories.asMap().entries.map((e) {
                  final m = e.value;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // خط الزمن
                      Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: m.category.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        m.category.color.withOpacity(0.4),
                                    blurRadius: 6),
                              ],
                            ),
                          ),
                          if (e.key != memories.length - 1)
                            Container(
                              width: 2.5,
                              height: 235,
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // البطاقة
                      Expanded(
                        child: MemoryCard(
                          memory: m,
                          myUid: user.uid,
                          onTap: () => context.push(
                              AppRoutes.memoryDetail,
                              extra: m),
                          onLike: () => vm.toggleLike(
                              coupleId: user.coupleId!,
                              memory: m,
                              uid: user.uid,
                              partnerUid: user.partnerId,
                              likerName: user.name),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: (60 * e.key.clamp(0, 8)).ms)
                      .slideY(begin: 0.08, curve: Curves.easeOutCubic);
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
