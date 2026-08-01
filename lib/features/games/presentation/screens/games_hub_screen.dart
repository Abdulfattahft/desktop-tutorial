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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 350
                ? 1
                : width < 700
                    ? 2
                    : width < 1050
                        ? 3
                        : 4;
            final padding = width < 380 ? 12.0 : width < 700 ? 16.0 : 24.0;
            final ratio = columns == 1
                ? 2.15
                : width < 430
                    ? 0.88
                    : 1.0;

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(padding, 8, padding, 28),
              children: [
                Text(
                  'اختارا لعبة والعبا مع بعض… مباشرة!',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ).animate().fadeIn(),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                  itemCount: GamesContent.allGames.length,
                  itemBuilder: (context, i) {
                    final meta = GamesContent.allGames[i];
                    return _GameCard(
                      meta: meta,
                      horizontal: columns == 1,
                      onTap: () => _openGame(context, meta.type),
                    )
                        .animate()
                        .fadeIn(delay: (70 * i).ms, duration: 350.ms)
                        .slideY(begin: 0.12, curve: Curves.easeOutCubic);
                  },
                ),
                const SizedBox(height: 28),
                if (user?.coupleId != null) ...[
                  Text(
                    'آخر الألعاب 🕹️',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                        children: items.map((entry) {
                          GameMeta? meta;
                          try {
                            meta = GamesContent.metaOf(
                              GameType.values.byName(entry.gameTypeName),
                            );
                          } catch (_) {}

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    (meta?.color ?? AppColors.primary)
                                        .withOpacity(0.15),
                                child: Icon(
                                  meta?.icon ?? Icons.videogame_asset,
                                  color: meta?.color ?? AppColors.primary,
                                ),
                              ),
                              title: Text(
                                meta?.title ?? entry.gameTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                intl.DateFormat('d MMM • h:mm a', 'ar')
                                    .format(entry.playedAt),
                                maxLines: 1,
                              ),
                              trailing: Text(
                                '+${entry.score} ⭐',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width < 380 ? 12.5 : 15,
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
            );
          },
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameMeta meta;
  final VoidCallback onTap;
  final bool horizontal;

  const _GameCard({
    required this.meta,
    required this.onTap,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(meta.icon, color: meta.color, size: 27),
    );

    final text = Column(
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          meta.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15.5),
        ),
        const SizedBox(height: 4),
        Text(
          meta.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 12, height: 1.35),
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: horizontal
              ? Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                )
              : Column(
                  children: [
                    icon,
                    const SizedBox(height: 9),
                    Expanded(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}
