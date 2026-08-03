import 'package:baynana/core/responsive/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoints', () {
    test('classifies supported widths', () {
      expect(AppBreakpoints.isSmallMobile(320), isTrue);
      expect(AppBreakpoints.isMobile(430), isTrue);
      expect(AppBreakpoints.isTablet(768), isTrue);
      expect(AppBreakpoints.isDesktop(1366), isTrue);
      expect(AppBreakpoints.isLargeDesktop(1920), isTrue);
    });

    test('padding grows progressively', () {
      final values = [
        AppBreakpoints.horizontalPadding(320),
        AppBreakpoints.horizontalPadding(390),
        AppBreakpoints.horizontalPadding(768),
        AppBreakpoints.horizontalPadding(1366),
        AppBreakpoints.horizontalPadding(1920),
      ];

      for (var index = 1; index < values.length; index++) {
        expect(values[index], greaterThanOrEqualTo(values[index - 1]));
      }
    });

    test('grid columns scale from mobile to large desktop', () {
      expect(AppBreakpoints.gridColumns(320), 1);
      expect(AppBreakpoints.gridColumns(600), 2);
      expect(AppBreakpoints.gridColumns(1200), 3);
      expect(AppBreakpoints.gridColumns(1600), 4);
    });
  });
}
