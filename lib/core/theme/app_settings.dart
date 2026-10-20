import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppSettings {
  final Map<String, Color> colors;
  final bool ruledLines;
  final bool compactMode;
  final double fontSize;
  final double rulerPadding;

  AppSettings({
    Map<String, Color>? colors,
    this.ruledLines = true,
    this.compactMode = false,
    this.fontSize = 16,
    this.rulerPadding = 0.01,
  }) : colors = Map<String, Color>.from(colors ?? AppColors.defaultPalette);

  Color color(String key) => colors[key] ?? AppColors.defaultPalette[key] ?? Colors.white;

  AppSettings copyWith({
    Map<String, Color>? colors,
    bool? ruledLines,
    bool? compactMode,
    double? fontSize,
    double? rulerPadding,
  }) {
    return AppSettings(
      colors: colors ?? this.colors,
      ruledLines: ruledLines ?? this.ruledLines,
      compactMode: compactMode ?? this.compactMode,
      fontSize: fontSize ?? this.fontSize,
      rulerPadding: rulerPadding ?? this.rulerPadding,
    );
  }

  Map<String, dynamic> toJson() => {
    'colors': colors.map(
      (key, value) => MapEntry(
        key,
        '#${value.toARGB32().toRadixString(16).padLeft(8, '0')}',
      ),
    ),
    'ruledLines': ruledLines,
    'compactMode': compactMode,
    'fontSize': fontSize,
    'rulerPadding': rulerPadding,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final parsedColors = <String, Color>{};
    final rawColors = json['colors'];

    if (rawColors is Map) {
      for (final entry in rawColors.entries) {
        final key = entry.key.toString();
        final value = entry.value.toString().replaceFirst('#', '');
        try {
          parsedColors[key] = Color(int.parse(value, radix: 16));
        } catch (_) {}
      }
    }

    return AppSettings(
      colors: {...AppColors.defaultPalette, ...parsedColors},
      ruledLines: json['ruledLines'] as bool? ?? true,
      compactMode: json['compactMode'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      rulerPadding: (json['rulerPadding'] as num?)?.toDouble() ?? 0.01,
    );
  }
}
