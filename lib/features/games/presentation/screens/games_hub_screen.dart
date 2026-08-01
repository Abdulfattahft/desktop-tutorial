import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/content/games_content.dart';
import '../../data/models/game_models.dart';
import '../viewmodels/games_viewmodel.dart';

/// شاشة الألعاب — بطاقات كل الألعاب + آخر الألعاب الملعوبة
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  Future<void> _openGame(BuildContext context, GameType type) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) return;

    final vm = context.read<GamesViewModel>();
    final ok = await vm.startOrJoin(
      coupleId: user.coupleId!,
      type: type,
      playerIds: [user.uid, user.partnerId!],
      starterUid: user.uid,
      starterName: user.name,
    );

    if (!context.mounted) return;
    if (ok) {
      context.push('${AppRoutes.games}/${type.name}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'حدث خطأ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final vm = context.read<GamesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('الألعاب 🎮')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'اختارا لعبة والعبا مع بعض… مباشرة!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.5),
            ).animate().fadeIn(),
            const SizedBox(height: 16),

            // شبكة بطاقات الألعاب
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1100 ? 4 : MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemCount: GamesContent.allGames.length,
              itemBuilder: (context, i) {
                final meta = GamesContent.allGames[i];
                return _GameCard(
                  meta: meta,
                  onTap: () => _openGame(context, meta.type),
                )
                    .animate()
                    .fadeIn(delay: (80 * i).ms, duration: 400.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutCubic);
              },
            ),

            const SizedBox(height: 28),

            // ===== آخر الألعاب =====
            if (user?.coupleId != null) ...[
              Text('آخر الألعاب 🕹️',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              StreamBuilder<List<GameHistoryEntry>>(
                stream: vm.recentGames(user!.coupleId!),
                builder: (context, snap) {
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return Text(
                      'ما لعبتما شي بعد… ابدآ أول لعبة! 💕',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: items.map((e) {
                      GameMeta? meta;
                      try {
                        meta = GamesContent.metaOf(
                            GameType.values.byName(e.gameTypeName));
                      } catch (_) {}
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (meta?.color ?? AppColors.primary)
                                    .withOpacity(0.15),
                            child: Icon(meta?.icon ?? Icons.videogame_asset,
                                color: meta?.color ?? AppColors.primary),
                          ),
                          title: Text(meta?.title ?? e.gameTypeName),
                          subtitle: Text(intl.DateFormat(
                                  'd MMM • h:mm a', 'ar')
                              .format(e.playedAt)),
                          trailing: Text(
                            '+${e.score} ⭐',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameMeta meta;
  final VoidCallback onTap;

  const _GameCard({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(meta.icon, color: meta.color, size: 28),
              ),
              const Spacer(),
              Text(meta.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                meta.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12.5, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
