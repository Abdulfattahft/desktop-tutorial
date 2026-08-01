import 'package:flutter/material.dart';

/// إطار عام يضمن أن كل شاشة تأخذ كامل ارتفاع المتصفح، مع إبقاء المحتوى
/// مريحًا على الجوال وعدم تمدده بشكل مبالغ فيه على الشاشات الواسعة.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({required this.child, super.key});

  final Widget child;

  static double contentMaxWidth(double width) {
    if (width >= 1600) return 1320;
    if (width >= 1200) return 1180;
    if (width >= 900) return 960;
    if (width >= 600) return 760;
    return width;
  }

  static double pagePadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 16;
    if (width < 900) return 24;
    return 28;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final maxWidth = contentMaxWidth(width);

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxWidth,
              height: height,
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
