import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_colors.dart';
import '../../data/models/memory_model.dart';

/// بطاقة ذكرى في الـ Timeline
class MemoryCard extends StatelessWidget {
  final MemoryModel memory;
  final String myUid;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.myUid,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final liked = memory.likedBy(myUid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة الرئيسية
            if (memory.imageUrls.isNotEmpty)
              Stack(
                children: [
                  Hero(
                    tag: 'memory_${memory.id}',
                    child: CachedNetworkImage(
                      imageUrl: memory.imageUrls.first,
                      height: 190,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 190,
                        color: AppColors.surface,
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 190,
                        color: AppColors.surface,
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  // شارة عدد الصور
                  if (memory.imageUrls.length > 1)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '📷 ${memory.imageUrls.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11.5),
                        ),
                      ),
                    ),
                  // شارة التصنيف
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: memory.category.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${memory.category.emoji} ${memory.category.label}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(memory.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      // إعجاب
                      InkWell(
                        onTap: onLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: liked
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                              if (memory.likesCount > 0) ...[
                                const SizedBox(width: 3),
                                Text('${memory.likesCount}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        intl.DateFormat('d MMMM yyyy', 'ar')
                            .format(memory.date),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (memory.location != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.place_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(memory.location!,
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      if (memory.comments.isNotEmpty) ...[
                        const Spacer(),
                        Text('💬 ${memory.comments.length}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
