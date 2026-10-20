import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import 'app_settings.dart';

class ThemeController extends ChangeNotifier {
  static const _storageKey = 'application_settings';

  AppSettings settings = AppSettings();
  Timer? _saveDebounce;

  Color getColor(String key) => settings.color(key);

  ThemeData get theme {
    final bg = getColor('background');
    final surface = getColor('surface');
    final accent = getColor('accent');
    final text = getColor('text');
    final muted = getColor('muted');
    final rules = getColor('rules');

    // Auto-detect light vs dark mode from background luminance
    final isDark = bg.computeLuminance() < 0.5;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: muted,
      onSecondary: text,
      surface: surface,
      onSurface: text,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      outline: rules,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      dividerColor: rules,
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      try {
        settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        settings = AppSettings();
      }
    }
    notifyListeners();
  }

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(settings.toJson()));
    });
  }

  void setColor(String key, Color color) {
    settings = settings.copyWith(colors: {...settings.colors, key: color});
    notifyListeners();
    _debouncedSave();
  }

  void setRuledLines(bool value) {
    settings = settings.copyWith(ruledLines: value);
    notifyListeners();
    _debouncedSave();
  }

  void setCompactMode(bool value) {
    settings = settings.copyWith(compactMode: value);
    notifyListeners();
    _debouncedSave();
  }

  void setFontSize(double value) {
    settings = settings.copyWith(fontSize: value);
    notifyListeners();
    _debouncedSave();
  }

  void setRulerPadding(double value) {
    settings = settings.copyWith(rulerPadding: value);
    notifyListeners();
    _debouncedSave();
  }

  void applyPreset(String name) {
    final palette = AppColors.presets[name] ?? AppColors.defaultPalette;
    settings = settings.copyWith(colors: palette);
    notifyListeners();
    _debouncedSave();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
