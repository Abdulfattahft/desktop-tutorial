import 'dart:ui';

import 'package:flutter/material.dart';

/// Root frame shared by every route.
///
/// The Flutter surface always fills the browser. Width constraints belong to
/// page content, never to the application root.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.35,
        ),
      ),
      child: ScrollConfiguration(
        behavior: const _BaynanaScrollBehavior(),
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class _BaynanaScrollBehavior extends MaterialScrollBehavior {
  const _BaynanaScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const ClampingScrollPhysics();
  }
}
