import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_palette.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.palette,
    required this.locale,
    required this.loaded,
    required this.hideLastName,
    required this.hideExactLocation,
  });

  const SettingsState.initial()
    : themeMode = ThemeMode.system,
      palette = AppPalette.electricIndigo,
      locale = null,
      loaded = false,
      hideLastName = false,
      hideExactLocation = false;

  final ThemeMode themeMode;
  final AppPalette palette;
  final Locale? locale;
  final bool loaded;
  final bool hideLastName;
  final bool hideExactLocation;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppPalette? palette,
    Locale? locale,
    bool clearLocale = false,
    bool? loaded,
    bool? hideLastName,
    bool? hideExactLocation,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      locale: clearLocale ? null : (locale ?? this.locale),
      loaded: loaded ?? this.loaded,
      hideLastName: hideLastName ?? this.hideLastName,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._prefs) : super(const SettingsState.initial()) {
    Future<void>.microtask(load);
  }

  final AppPreferences _prefs;

  Future<void> load() async {
    final themeRaw = _prefs.getString(PrefKeys.themeMode);
    final paletteRaw = _prefs.getString(PrefKeys.palette);
    final languageCode = _prefs.getString(PrefKeys.localeLanguageCode);
    final countryCode = _prefs.getString(PrefKeys.localeCountryCode);

    state = state.copyWith(
      themeMode: switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      palette: AppPaletteX.fromStorage(paletteRaw),
      locale: languageCode == null ? null : Locale(languageCode, countryCode),
      hideLastName: _prefs.getBool(PrefKeys.hideLastName),
      hideExactLocation: _prefs.getBool(PrefKeys.hideExactLocation),
      loaded: true,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(PrefKeys.themeMode, raw);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updatePalette(AppPalette palette) async {
    await _prefs.setString(PrefKeys.palette, palette.storageValue);
    state = state.copyWith(palette: palette);
  }

  Future<void> updateLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(PrefKeys.localeLanguageCode);
      await _prefs.remove(PrefKeys.localeCountryCode);
      state = state.copyWith(clearLocale: true);
      return;
    }

    await _prefs.setString(PrefKeys.localeLanguageCode, locale.languageCode);
    if (locale.countryCode != null) {
      await _prefs.setString(PrefKeys.localeCountryCode, locale.countryCode!);
    }
    state = state.copyWith(locale: locale);
  }

  Future<void> updateHideLastName(bool value) async {
    await _prefs.setBool(PrefKeys.hideLastName, value);
    state = state.copyWith(hideLastName: value);
  }

  Future<void> updateHideExactLocation(bool value) async {
    await _prefs.setBool(PrefKeys.hideExactLocation, value);
    state = state.copyWith(hideExactLocation: value);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
      (ref) => SettingsController(ref.watch(appPreferencesProvider)),
    );
