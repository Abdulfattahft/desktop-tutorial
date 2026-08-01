import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/memory_model.dart';
import '../viewmodels/memories_viewmodel.dart';

/// تفاصيل الذكرى — صور، ملاحظة، إعجاب، تعليقات، حذف (لصاحبها)
/// تستمع للتيار لعرض التعليقات والإعجابات لحظيًا
class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel initial;
  const MemoryDetailScreen({super.key, required this.initial});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final _commentCtrl = TextEditingController();
  int _imageIndex = 0;
  Stream<MemoryModel?>? _memoryStream;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment(MemoryModel memory) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthViewModel>().currentUser!;
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
    await context.read<MemoriesViewModel>().addComment(
          coupleId: user.coupleId!,
          memoryId: memory.id,
          comment: MemoryComment(
            uid: user.uid,
            name: user.name,
            text: text,
            at: DateTime.now(),
          ),
          partnerUid: user.partnerId,
          memoryTitle: memory.title,
        );
  }

  Future<void> _delete(MemoryModel memory) async {
    final user = context.read<AuthViewModel>().currentUser!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الذكرى'),
        content: const Text('متأكد؟ الصور والتعليقات بتنحذف نهائيًا'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await context
        .read<MemoriesViewModel>()
        .deleteMemory(coupleId: user.coupleId!, memory: memory);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الحذف'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;
    final vm = context.read<MemoriesViewModel>();

    // نستمع لمستند هذه الذكرى فقط (أخف من الاستماع للقائمة كاملة)
    _memoryStream ??=
        vm.memoryStream(user.coupleId!, widget.initial.id);

    return StreamBuilder<MemoryModel?>(
      stream: _memoryStream,
      builder: (context, snap) {
        final memory = snap.data ?? widget.initial;
        final liked = memory.likedBy(user.uid);
        final isMine = memory.createdBy == user.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(memory.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (isMine)
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: () => _delete(memory),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      // ===== الصور =====
                      if (memory.imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 300,
                          child: PageView.builder(
                            itemCount: memory.imageUrls.length,
                            onPageChanged: (i) =>
                                setState(() => _imageIndex = i),
                            itemBuilder: (_, i) => Hero(
                              tag: i == 0
                                  ? 'memory_${memory.id}'
                                  : 'memory_${memory.id}_$i',
                              child: CachedNetworkImage(
                                imageUrl: memory.imageUrls[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (memory.imageUrls.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(
                                memory.imageUrls.length,
                                (i) => AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: i == _imageIndex ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: i == _imageIndex
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withOpacity(0.25),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // معلومات
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: memory.category.color
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${memory.category.emoji} ${memory.category.label}',
                                    style: TextStyle(
                                        color: memory.category.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const Spacer(),
                                // إعجاب
                                InkWell(
                                  onTap: () => vm.toggleLike(
                                      coupleId: user.coupleId!,
                                      memory: memory,
                                      uid: user.uid,
                                      partnerUid: user.partnerId,
                                      likerName: user.name),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          liked
                                              ? Icons.favorite_rounded
                                              : Icons
                                                  .favorite_outline_rounded,
                                          color: liked
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                        if (memory.likesCount > 0) ...[
                                          const SizedBox(width: 4),
                                          Text('${memory.likesCount}'),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              intl.DateFormat(
                                      'EEEE، d MMMM yyyy', 'ar')
                                  .format(memory.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                            if (memory.location != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4),
                                child: Text('📍 ${memory.location}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                              ),
                            if (memory.note.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(memory.note,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(height: 1.7)),
                            ],

                            // ===== التعليقات =====
                            const SizedBox(height: 20),
                            Text('التعليقات 💬',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge),
                            const SizedBox(height: 10),
                            if (memory.comments.isEmpty)
                              Text('ما فيه تعليقات… اكتب أول تعليق 🤍',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ...memory.comments.map(
                              (c) => Container(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.uid == user.uid
                                      ? AppColors.primary
                                          .withOpacity(0.08)
                                      : AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.uid == user.uid
                                          ? 'أنت'
                                          : c.name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              AppColors.primaryDark),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(c.text,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                                fontSize: 14,
                                                height: 1.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== إدخال تعليق =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            hintText: 'اكتب تعليقًا…',
                            counterText: '',
                          ),
                          onSubmitted: (_) => _sendComment(memory),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _sendComment(memory),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            gradient: AppColors.romanticGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
