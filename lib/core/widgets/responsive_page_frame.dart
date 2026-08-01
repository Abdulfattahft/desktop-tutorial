import 'package:flutter/material.dart';

/// Keeps mobile screens comfortable while preventing content from stretching
/// excessively on tablets, laptops and wide desktop displays.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxWidth = width >= 1440
            ? 1280.0
            : width >= 1024
                ? 1120.0
                : width >= 720
                    ? 760.0
                    : width;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: maxWidth, child: child),
          ),
        );
      },
    );
  }
}
