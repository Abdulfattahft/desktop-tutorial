import 'package:flutter/material.dart';

/// إطار عام يضمن أن التطبيق يملأ كامل مساحة المتصفح دائمًا.
/// تقييد عرض المحتوى يتم داخل كل شاشة، وليس على جذر التطبيق؛ لأن Safari
/// قد يبلّغ Flutter بعرض سطح مكتب حتى على الجوال في بعض الحالات.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({required this.child, super.key});

  final Widget child;

  static double pagePadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 16;
    if (width < 900) return 24;
    return 28;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ClipRect(child: child),
      ),
    );
  }
}
