import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_models.dart';

class GiftShopCard extends StatelessWidget {
  final GiftCatalogItem gift;
  final int myCoins;
  final GiftLock? lock;
  final VoidCallback onTap;

  const GiftShopCard({
    super.key,
    required this.gift,
    required this.myCoins,
    required this.onTap,
    this.lock,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lock != null;
    final affordable = myCoins >= gift.price;
    final isLegendary = gift.rarity == GiftRarity.legendary && !locked;
    final accent = gift.displayColor;

    Widget card = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withOpacity(
                gift.rarity == GiftRarity.common ? 0.25 : 0.7,
              ),
              width: gift.rarity == GiftRarity.common ? 1 : 1.8,
            ),
            boxShadow: isLegendary
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(compact ? 9 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        locked ? '🔒' : gift.emoji,
                        style: TextStyle(fontSize: compact ? 32 : 40),
                      ),
                      SizedBox(height: compact ? 5 : 8),
                      Text(
                        gift.name,
                        textAlign: TextAlign.center,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: compact ? 12.5 : 14.5,
                              height: 1.25,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        locked ? lock!.reason : gift.rarity.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w700,
                          color: locked ? AppColors.textSecondary : accent,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: affordable
                              ? AppColors.secondary.withOpacity(0.15)
                              : AppColors.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🪙 ${gift.price}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 13,
                            fontWeight: FontWeight.w800,
                            color: affordable
                                ? Theme.of(context).colorScheme.onSurface
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (gift.isNew || gift.isLimited || gift.isSeasonal)
                  PositionedDirectional(
                    top: 7,
                    start: 7,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: compact ? 78 : 110),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: gift.isLimited
                            ? AppColors.error
                            : gift.isSeasonal
                                ? const Color(0xFF5EA3A3)
                                : AppColors.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        gift.isLimited
                            ? '⏳ محدودة'
                            : gift.isSeasonal
                                ? '🍂 موسمية'
                                : 'جديد ✨',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 8.5 : 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (locked) card = Opacity(opacity: 0.6, child: card);
    if (isLegendary) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 8,
            ),
            end: BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            duration: 1600.ms,
            borderRadius: BorderRadius.circular(20),
          );
    }
    return card;
  }
}

class GiftHistoryTile extends StatelessWidget {
  final SentGift gift;
  final String myUid;
  final String partnerName;
  final VoidCallback? onOpen;

  const GiftHistoryTile({
    super.key,
    required this.gift,
    required this.myUid,
    required this.partnerName,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final received = gift.toUid == myUid;
    final unopened = received && !gift.opened;
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: unopened
            ? const BorderSide(color: AppColors.secondary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: unopened ? onOpen : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: 3,
        ),
        leading: Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            color: gift.rarity.defaultColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            unopened ? '🎁' : gift.emoji,
            style: TextStyle(fontSize: compact ? 21 : 24),
          ),
        ),
        title: Text(
          unopened
              ? 'هدية مغلفة من ${gift.senderNameOr(partnerName)}'
              : '${gift.name}${gift.reaction ?? ""}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13.5 : 14.5,
          ),
        ),
        subtitle: Text(
          '${received ? "من ${gift.senderNameOr(partnerName)}" : "أرسلتها لـ$partnerName"} • ${intl.DateFormat('d MMM', 'ar').format(gift.sentAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: compact ? 10.5 : 12),
        ),
        trailing: unopened
            ? Text(
                compact ? 'افتح' : 'افتحها!',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11 : 13,
                ),
              )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 700.ms)
            : Text(
                received ? '📥' : '📤',
                style: TextStyle(fontSize: compact ? 16 : 18),
              ),
      ),
    );
  }
}

class GiftStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const GiftStatCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 9 : 12,
            horizontal: 3,
          ),
          child: Column(
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: compact ? 17 : 20),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 8 : 10,
                  height: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
