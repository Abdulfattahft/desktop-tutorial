import 'package:flutter/material.dart';

/// Central responsive rules used across the web app.
abstract final class AppBreakpoints {
  static const double smallMobile = 360;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  static bool isSmallMobile(double width) => width < smallMobile;
  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  static double horizontalPadding(double width) {
    if (width < smallMobile) return 16;
    if (width < tablet) return 20;
    if (width < desktop) return 32;
    if (width < largeDesktop) return 48;
    return 64;
  }

  static double contentMaxWidth(double width) {
    if (width < tablet) return double.infinity;
    if (width < desktop) return 760;
    if (width < largeDesktop) return 1180;
    return 1360;
  }

  static int gridColumns(double width) {
    if (width < 520) return 1;
    if (width < desktop) return 2;
    if (width < largeDesktop) return 3;
    return 4;
  }
}

extension ResponsiveContext on BuildContext {
  Size get viewportSize => MediaQuery.sizeOf(this);
  double get viewportWidth => viewportSize.width;
  bool get isMobileLayout => AppBreakpoints.isMobile(viewportWidth);
  bool get isTabletLayout => AppBreakpoints.isTablet(viewportWidth);
  bool get isDesktopLayout => AppBreakpoints.isDesktop(viewportWidth);
  double get responsiveHorizontalPadding =>
      AppBreakpoints.horizontalPadding(viewportWidth);
}
