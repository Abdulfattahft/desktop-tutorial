import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/onboarding_page_view.dart';

/// شاشة التعريف بالتطبيق — 3 صفحات تشرح الفكرة
/// تظهر مرة واحدة فقط عند أول تشغيل
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.favorite_rounded,
      title: 'المسافة تقرّبنا',
      description:
          'مهما بعدت المدن، "بيننا" يجمعكما في مكان واحد.\nتواصل يومي ممتع يقوّي علاقتكما خطوة بخطوة.',
      gradientColors: [AppColors.primary, AppColors.secondaryLight],
    ),
    OnboardingPageData(
      icon: Icons.videogame_asset_rounded,
      title: 'ألعاب وتحديات يومية',
      description:
          'اعرفني، لو خيروك، مين غالبًا؟ وأكثر…\nتحدٍ جديد كل يوم، ونقاط ومستويات ترفع علاقتكما.',
      gradientColors: [AppColors.secondary, AppColors.primary],
    ),
    OnboardingPageData(
      icon: Icons.photo_library_rounded,
      title: 'ذكرياتكما في مكان واحد',
      description:
          'صور، ملاحظات، وأول لحظاتكما الجميلة\nفي خط زمني يحكي قصتكما… وهدايا تفاجئ بها شريكك.',
      gradientColors: [AppColors.primaryDark, AppColors.secondaryLight],
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finish() async {
    await LocalStorageService.instance.setSeenOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // زر تخطي — يظهر فقط قبل الصفحة الأخيرة
              Align(
                alignment: AlignmentDirectional.topStart,
                child: AnimatedOpacity(
                  opacity: _isLastPage ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: TextButton(
                    onPressed: _isLastPage ? null : _finish,
                    child: Text(
                      'تخطي',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // الصفحات
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      OnboardingPageView(data: _pages[index]),
                ),
              ),

              // مؤشر الصفحات المتحرك
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // زر التالي / ابدأ رحلتكما
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_isLastPage ? 'ابدأ رحلتكما 💕' : 'التالي'),
                ).animate().fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
