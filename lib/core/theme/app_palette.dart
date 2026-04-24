import 'package:flutter/material.dart';

enum AppPalette { electricIndigo, emberCoral, monsoonTeal }

extension AppPaletteX on AppPalette {
  Color get seedColor {
    switch (this) {
      case AppPalette.electricIndigo:
        return const Color(0xFF5F46FF);
      case AppPalette.emberCoral:
        return const Color(0xFFFF6B4A);
      case AppPalette.monsoonTeal:
        return const Color(0xFF147D78);
    }
  }

  String get storageValue {
    switch (this) {
      case AppPalette.electricIndigo:
        return 'electric_indigo';
      case AppPalette.emberCoral:
        return 'ember_coral';
      case AppPalette.monsoonTeal:
        return 'monsoon_teal';
    }
  }

  String get label {
    switch (this) {
      case AppPalette.electricIndigo:
        return 'Electric Indigo';
      case AppPalette.emberCoral:
        return 'Ember Coral';
      case AppPalette.monsoonTeal:
        return 'Monsoon Teal';
    }
  }

  static AppPalette fromStorage(String? value) {
    return AppPalette.values.firstWhere(
      (palette) => palette.storageValue == value,
      orElse: () => AppPalette.electricIndigo,
    );
  }
}
