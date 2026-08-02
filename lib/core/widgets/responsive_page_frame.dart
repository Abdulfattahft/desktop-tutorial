import 'package:flutter/material.dart';

/// إطار عام للتطبيق.
///
/// يجب أن يملأ Flutter مساحة المتصفح كاملة دائمًا. تقييد العرض هنا كان يجعل
/// Safari على iPhone وiPad يعرض التطبيق في جزء من الشاشة عندما يبلّغ Flutter
/// بقياس تخطيط أكبر من قياس الجهاز. ضبط العرض الأقصى يتم داخل كل صفحة عند
/// الحاجة، مثل صفحات تسجيل الدخول والتسجيل، وليس على جذر التطبيق كله.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(child: child),
    );
  }
}
