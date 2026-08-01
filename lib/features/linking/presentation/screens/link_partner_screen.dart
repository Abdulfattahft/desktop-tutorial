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

class LinkPartnerScreen extends StatefulWidget {
  const LinkPartnerScreen({super.key});

  @override
  State<LinkPartnerScreen> createState() => _LinkPartnerScreenState();
}

class _LinkPartnerScreenState extends State<LinkPartnerScreen> {
  final _codeCtrl = TextEditingController();
  late final LinkingViewModel _linkVm;
  bool _handledSuccess = false;

  @override
  void initState() {
    super.initState();
    _linkVm = context.read<LinkingViewModel>();
    _linkVm.addListener(_onLinkVmChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUid = context.read<AuthViewModel>().currentUser?.uid;
      if (myUid != null) _linkVm.watchMyAccount(myUid);
    });
  }

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
      'افتح الموقع وأدخل الرمز لنرتبط معًا!',
    );
  }

  Future<void> _submitCode() async {
    FocusScope.of(context).unfocus();
    final myUid = context.read<AuthViewModel>().currentUser?.uid;
    if (myUid == null) return;

    final ok = await _linkVm.linkWithCode(
      myUid: myUid,
      code: _codeCtrl.text,
    );

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

  Future<void> _showSuccessAndGo() async {
    await context.read<AuthViewModel>().loadCurrentUser();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    gradient: AppColors.romanticGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ).animate().scale(
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),
                const SizedBox(height: 18),
                Text(
                  'ارتبطتما بنجاح! 🎉',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'من اليوم… كل لعبة وتحدٍ وذكرى بتكون بينكما',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('يلا نبدأ 💕'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final linkVm = context.watch<LinkingViewModel>();
    final user = authVm.currentUser;
    final myCode = user?.inviteCode ?? '------';
    final media = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final padding = compact ? 16.0 : 24.0;
                final codeSize = constraints.maxWidth < 350 ? 23.0 : compact ? 27.0 : 32.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    10,
                    padding,
                    media.viewInsets.bottom + 28,
                  ),
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
                      SizedBox(height: compact ? 20 : 28),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 16 : 20),
                          child: Column(
                            children: [
                              Text(
                                'رمز الدعوة الخاص بك',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    myCode.split('').join(' '),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: codeSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: compact ? 1.2 : 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (compact)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _copyCode(myCode),
                                      icon: const Icon(Icons.copy_rounded, size: 20),
                                      label: const Text('نسخ الرمز'),
                                      style: _copyStyle(),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _shareCode(myCode, user?.name ?? ''),
                                      icon: const Icon(Icons.share_rounded, size: 20),
                                      label: const Text('مشاركة الرمز'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 48),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _copyCode(myCode),
                                        icon: const Icon(Icons.copy_rounded, size: 20),
                                        label: const Text('نسخ'),
                                        style: _copyStyle(),
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
                                          minimumSize: const Size(0, 48),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'أو',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'عندك رمز شريكك؟ أدخله هنا:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 14),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: TextField(
                          controller: _codeCtrl,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 8,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitCode(),
                          style: TextStyle(
                            fontSize: compact ? 21 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: compact ? 3 : 6,
                            color: AppColors.primaryDark,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: linkVm.isLoading ? null : _submitCode,
                        child: linkVm.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('ربط الحسابين 💞'),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.secondary,
                              size: 22,
                            ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _copyStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
