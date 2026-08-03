import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Keeps the page background full-width while constraining only its content.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final resolvedMaxWidth = maxWidth ?? AppBreakpoints.contentMaxWidth(width);
        final resolvedPadding = padding ?? EdgeInsets.symmetric(
          horizontal: AppBreakpoints.horizontalPadding(width),
        );

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
            child: Padding(
              padding: resolvedPadding,
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}
