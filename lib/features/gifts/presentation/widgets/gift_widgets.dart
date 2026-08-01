import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_colors.dart';
import '../../data/models/gift_models.dart';

/// بطاقة هدية في المتجر — إطار وتوهج حسب الندرة + شارات
class GiftShopCard extends StatelessWidget {
  final GiftCatalogItem gift;
  final int myCoins;
  final GiftLock? lock; // إن وُجد → الهدية مقفلة
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

    Widget card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              .withOpacity(gift.rarity == GiftRarity.common ? 0.25 : 0.7),
          width: gift.rarity == GiftRarity.common ? 1 : 1.8,
        ),
        boxShadow: isLegendary
            ? [
                BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 14,
                    spreadRadius: 1),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  Text(locked ? '🔒' : gift.emoji,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(gift.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(locked ? lock!.reason : gift.rarity.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: locked
                              ? AppColors.textSecondary
                              : accent)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: affordable
                          ? AppColors.secondary.withOpacity(0.15)
                          : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🪙 ${gift.price}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: affordable
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // شارات جديد / لفترة محدودة
            if (gift.isNew || gift.isLimited || gift.isSeasonal)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
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
                        ? '⏳ لفترة محدودة'
                        : gift.isSeasonal
                            ? '🍂 موسمية'
                            : 'جديد ✨',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (locked) card = Opacity(opacity: 0.6, child: card);

    // توهج متكرر للأسطورية غير المقفلة
    if (isLegendary) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            begin: BoxShadow(
                color: accent.withOpacity(0.15), blurRadius: 8),
            end: BoxShadow(
                color: accent.withOpacity(0.4),
                blurRadius: 18,
                spreadRadius: 2),
            duration: 1600.ms,
            borderRadius: BorderRadius.circular(20),
          );
    }
    return card;
  }
}

/// بطاقة هدية في الوارد/السجل
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: gift.rarity.defaultColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(unopened ? '🎁' : gift.emoji,
              style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          unopened
              ? 'هدية مغلفة من ${gift.senderNameOr(partnerName)}'
              : '${gift.name}${gift.reaction ?? ""}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        subtitle: Text(
          '${received ? "من ${gift.senderNameOr(partnerName)}" : "أرسلتها لـ$partnerName"} • ${intl.DateFormat('d MMM', 'ar').format(gift.sentAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: unopened
            ? const Text('افتحها!',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 700.ms)
            : Text(
                received ? '📥' : '📤',
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}

/// بطاقة إحصائية صغيرة
class GiftStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const GiftStatCard(
      {super.key,
      required this.emoji,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
