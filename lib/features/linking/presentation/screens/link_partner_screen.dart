import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/linking_viewmodel.dart';

/// شاشة ربط الشريكين
/// - تعرض رمز دعوة المستخدم مع نسخ ومشاركة
/// - تستقبل رمز الشريك وتتحقق منه من Firestore
/// - تستمع لحظيًا: لو الشريك ربطك من جهازه تنتقل تلقائيًا
class LinkPartnerScreen extends StatefulWidget {
  const LinkPartnerScreen({super.key});

  @override
  State<LinkPartnerScreen> createState() => _LinkPartnerScreenState();
}

class _LinkPartnerScreenState extends State<LinkPartnerScreen> {
  final _codeCtrl = TextEditingController();
  late final LinkingViewModel _linkVm;

  /// حارس يمنع ظهور رسالة النجاح أكثر من مرة مهما كان مصدرها
  bool _handledSuccess = false;

  @override
  void initState() {
    super.initState();
    _linkVm = context.read<LinkingViewModel>();
    _linkVm.addListener(_onLinkVmChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUid = context.read<AuthViewModel>().currentUser?.uid;
      if (myUid != null) {
        _linkVm.watchMyAccount(myUid);
      }
    });
  }

  /// يُستدعى عند أي تغيير في ViewModel — خارج build (النمط الصحيح)
  void _onLinkVmChanged() {
    if (_linkVm.linkedByPartner && !_handledSuccess && mounted) {
      _handledSuccess = true;
      _showSuccessAndGo();
    }
  }

  @override
  void dispose() {
    _linkVm.removeListener(_onLinkVmChanged);
    _linkVm.stopWatching();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرمز ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareCode(String code, String name) async {
    await Share.share(
      '💕 $name يدعوك للانضمام إليه في تطبيق "بيننا"\n\n'
      'رمز الدعوة: $code\n\n'
      'حمّل التطبيق وأدخل الرمز لنرتبط معًا!',
    );
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;
    if (myUid == null) return;

    final ok = await _linkVm.linkWithCode(myUid: myUid, code: _codeCtrl.text);

    if (!mounted) return;
    if (ok) {
      if (!_handledSuccess) {
        _handledSuccess = true;
        await _showSuccessAndGo();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_linkVm.errorMessage ?? 'حدث خطأ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// رسالة نجاح جميلة ثم الانتقال للرئيسية
  Future<void> _showSuccessAndGo() async {
    // تحديث بيانات المستخدم المحلية (partnerId أصبح موجودًا)
    await context.read<AuthViewModel>().loadCurrentUser();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  gradient: AppColors.romanticGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 46),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              const SizedBox(height: 20),
              Text('ارتبطتما بنجاح! 🎉',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'من اليوم… كل لعبة وتحدٍ وذكرى بتكون بينكما',
                textAlign: TextAlign.center,
                style:
                    Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('يلا نبدأ 💕'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final linkVm = context.watch<LinkingViewModel>();
    final user = authVm.currentUser;
    final myCode = user?.inviteCode ?? '------';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط الشريك'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أهلًا ${user?.name ?? ''} 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              Text(
                'خطوة واحدة تفصلكما… شارك رمزك مع شريكك أو أدخل رمزه',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.6),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 28),

              // ===== بطاقة رمزي =====
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('رمز الدعوة الخاص بك',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          myCode.split('').join(' '),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyCode(myCode),
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              label: const Text('نسخ'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _shareCode(myCode, user?.name ?? ''),
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: const Text('مشاركة'),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('أو',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // ===== إدخال رمز الشريك =====
              Text('عندك رمز شريكك؟ أدخله هنا:',
                      style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 14),

              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _codeCtrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: 6,
                        color: AppColors.primaryDark,
                      ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '• • • • • •',
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: linkVm.isLoading ? null : _submitCode,
                child: linkVm.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('ربط الحسابين 💞'),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لو شريكك أدخل رمزك من جهازه، بننقلك تلقائيًا — خلّ الشاشة مفتوحة',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
