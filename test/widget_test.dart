import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_palette.dart';

void main() {
  test('AppPalette falls back to electric indigo for unknown storage values', () {
    expect(
      AppPaletteX.fromStorage('unknown-value'),
      AppPalette.electricIndigo,
    );
  });
}
