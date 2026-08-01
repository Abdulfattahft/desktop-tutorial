import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_viewmodel.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../data/models/settings_models.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_widgets.dart';

/// إدارة العلاقة — بيانات الشريك وفصل العلاقة بموافقة الطرفين
class RelationshipScreen extends StatefulWidget {
  const RelationshipScreen({super.key});

  @override
  State<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  Stream<CoupleModel?>? _coupleStream;
  Stream<UserModel?>? _partnerStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _rawCoupleStream;

  Future<void> _requestUnlink(String coupleId, String uid) async {
    final ok = await confirmDialog(
      context,
      title: 'طلب فصل العلاقة',
      message:
          'بيوصل طلب لشريكك، والفصل ما يتم إلا بموافقته.\n\n'
          'ذكرياتكما وهداياكما ونقاطكما تبقى محفوظة، وترجع لو ارتبطتما مرة ثانية.',
      confirmText: 'أرسل الطلب',
      danger: true,
    );
    if (!ok || !mounted) return;
    final done = await context
        .read<SettingsViewModel>()
        .requestUnlink(coupleId: coupleId, uid: uid);
    if (!mounted) return;
    _toast(done ? 'أُرسل الطلب لشريكك' : 'تعذر إرسال الطلب', done);
  }

  Future<void> _confirmUnlink(String coupleId, String uid) async {
    final ok = await confirmDialog(
      context,
      title: 'تأكيد فصل العلاقة',
      message:
          'بعد الفصل ما بتقدران تلعبان أو تتشاركان الذكريات.\n\n'
          'البيانات تبقى محفوظة وترجع لو ارتبطتما مرة ثانية.',
      confirmText: 'أوافق على الفصل',
      danger: true,
    );
    if (!ok || !mounted) return;
    final vm = context.read<SettingsViewModel>();
    final done = await vm.confirmUnlink(coupleId: coupleId, uid: uid);
    if (!mounted) return;
    if (done) {
      await context.read<AuthViewModel>().loadCurrentUser();
      if (mounted) context.go(AppRoutes.linkPartner);
    } else {
      _toast(vm.errorMessage ?? 'تعذر الفصل', false);
    }
  }

  Future<void> _cancelUnlink(String coupleId) async {
    final done =
        await context.read<SettingsViewModel>().cancelUnlink(coupleId);
    if (!mounted) return;
    _toast(done ? 'أُلغي الطلب' : 'تعذر إلغاء الطلب', done);
  }

  void _toast(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final homeVm = context.read<HomeViewModel>();
    _coupleStream ??= homeVm.coupleStream(user.coupleId!);
    _partnerStream ??= homeVm.userStream(user.partnerId!);
    _rawCoupleStream ??= FirebaseFirestore.instance
        .collection('couples')
        .doc(user.coupleId!)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('العلاقة 💕')),
      body: SafeArea(
        child: StreamBuilder<CoupleModel?>(
          stream: _coupleStream,
          builder: (context, coupleSnap) {
            final couple = coupleSnap.data;
            if (couple == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // ===== بطاقة العلاقة =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.romanticGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        '${couple.names[user.uid] ?? ""} 💕 ${couple.partnerNameOf(user.uid)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'مرتبطان منذ ${intl.DateFormat("d MMMM yyyy", "ar").format(couple.createdAt)}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _daysTogether(couple.createdAt),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.08),

                // ===== بيانات الشريك =====
                StreamBuilder<UserModel?>(
                  stream: _partnerStream,
                  builder: (context, partnerSnap) {
                    final partner = partnerSnap.data;
                    return SettingsSection(
                      title: 'شريكك',
                      emoji: '👤',
                      index: 1,
                      children: [
                        SettingsTile(
                          icon: Icons.person_rounded,
                          title: partner?.name ?? '—',
                          subtitle: partner == null
                              ? null
                              : TimeUtils.relative(partner.lastActive),
                          trailing: partner != null &&
                                  TimeUtils.isOnline(partner.lastActive)
                              ? const Icon(Icons.circle,
                                  color: AppColors.success, size: 12)
                              : const SizedBox.shrink(),
                        ),
                        SettingsTile(
                          icon: Icons.emoji_events_rounded,
                          title: 'مستوى العلاقة',
                          subtitle:
                              '${couple.level} — ${_levelName(couple.level)}',
                          iconColor: AppColors.secondary,
                          trailing: Text('⭐ ${couple.totalPoints}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                        SettingsTile(
                          icon: Icons.local_fire_department_rounded,
                          title: 'الستريك',
                          subtitle: '${couple.streak} يوم متتالٍ',
                          iconColor: const Color(0xFFE08E45),
                        ),
                        SettingsTile(
                          icon: Icons.videogame_asset_rounded,
                          title: 'الألعاب المكتملة',
                          subtitle: '${couple.gamesPlayedTotal} لعبة',
                        ),
                      ],
                    );
                  },
                ),

                // ===== فصل العلاقة =====
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _rawCoupleStream,
                  builder: (context, rawSnap) {
                    final raw = rawSnap.data?.data();
                    final reqMap = raw?['unlinkRequest'] as Map?;
                    final request = reqMap == null
                        ? null
                        : UnlinkRequest.fromMap(
                            Map<String, dynamic>.from(reqMap));

                    // لا يوجد طلب
                    if (request == null ||
                        request.status != UnlinkStatus.pending) {
                      return SettingsSection(
                        title: 'إدارة العلاقة',
                        emoji: '⚠️',
                        index: 2,
                        children: [
                          SettingsTile(
                            icon: Icons.heart_broken_rounded,
                            title: 'فصل العلاقة',
                            subtitle:
                                'يحتاج موافقة الطرفين — البيانات تبقى محفوظة',
                            danger: true,
                            onTap: () =>
                                _requestUnlink(couple.id, user.uid),
                          ),
                        ],
                      );
                    }

                    // أنا صاحب الطلب → بانتظار الشريك
                    if (request.requestedBy == user.uid) {
                      return _RequestBanner(
                        title: 'بانتظار موافقة شريكك ⏳',
                        message:
                            'أرسلت طلب فصل العلاقة. ما يتم الفصل إلا بموافقته.',
                        actionLabel: 'إلغاء الطلب',
                        onAction: () => _cancelUnlink(couple.id),
                      );
                    }

                    // الشريك طلب الفصل → أوافق أو أرفض
                    return _RequestBanner(
                      title: 'شريكك طلب فصل العلاقة 💔',
                      message:
                          'إذا وافقت بينفصل الحسابان. ذكرياتكما تبقى محفوظة وترجع لو ارتبطتما مرة ثانية.',
                      actionLabel: 'أوافق على الفصل',
                      onAction: () => _confirmUnlink(couple.id, user.uid),
                      secondaryLabel: 'رفض الطلب',
                      onSecondary: () => _cancelUnlink(couple.id),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _daysTogether(DateTime since) {
    final days = DateTime.now().difference(since).inDays;
    if (days == 0) return 'اليوم بدأت حكايتكما ✨';
    if (days == 1) return 'يوم واحد معًا';
    if (days == 2) return 'يومان معًا';
    if (days < 11) return '$days أيام معًا';
    return '$days يومًا معًا';
  }

  String _levelName(int level) {
    const names = [
      'بداية الحكاية', 'تعارف', 'قرب', 'مودة', 'انسجام',
      'وفاء', 'عشق', 'توأم روح', 'حب أسطوري', 'إلى الأبد',
    ];
    return names[(level - 1).clamp(0, names.length - 1)];
  }
}

/// بانر طلب الفصل
class _RequestBanner extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _RequestBanner({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, minimumSize: const Size(0, 46)),
            child: Text(actionLabel),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().shake(hz: 2, rotation: 0.005, duration: 400.ms);
  }
}
