import 'package:flutter/material.dart';

/// Centralized, strongly-typed color definitions and theme palettes.
class AppColors {
  // Brand & Accent Colors
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color cyan = Color(0xFF55C8E8);
  static const Color emerald = Color(0xFF10B981);
  static const Color neonPink = Color(0xFFFF4FD8);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color coral = Color(0xFFFF6B6B);

  // Neutral Bases
  static const Color obsidian = Color(0xFF12151B);
  static const Color charcoal = Color(0xFF1E242E);
  static const Color deepSurface = Color(0xFF242B36);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color warmParchment = Color(0xFFF5F2EB);

  // Functional & Semantic
  static const Color clockLine = Color(0xFFEF4444);
  static const Color holiday = Color(0xFFF43F5E);
  static const Color selectedDay = Color(0xFF007AFF);
  static const Color selectedBorder = Color(0xFFFF2222);
  static const Color dateHighlightBg = Color(0x33F59E0B);
  static const Color dateHighlightBorder = Color(0xFFF59E0B);

  // Windows Titlebar Controls
  static const Color windowCloseHover = Color(0xFFE81123);
  static const Color windowButtonHover = Color(0x22FFFFFF);

  // Default Theme Color Map
  static const Map<String, Color> defaultPalette = {
    'background': Color(0xFF14171E),
    'surface': Color(0xFF1F2530),
    'accent': Color(0xFFF59E0B),
    'text': Color(0xFFE6EAF0),
    'muted': Color(0xFF8B98A9),
    'rules': Color(0xFF2C3442),
  };

  // Curated Preset Palettes
  static const Map<String, Map<String, Color>> presets = {
    'Amber Dark': defaultPalette,
    'Cyber Cyan': {
      'background': Color(0xFF10141D),
      'surface': Color(0xFF1B2330),
      'accent': Color(0xFF55C8E8),
      'text': Color(0xFFE3EDF7),
      'muted': Color(0xFF7E92A7),
      'rules': Color(0xFF273445),
    },
    'Terminal Green': {
      'background': Color(0xFF0D140F),
      'surface': Color(0xFF152219),
      'accent': Color(0xFF10B981),
      'text': Color(0xFFD1FAE5),
      'muted': Color(0xFF6EE7B7),
      'rules': Color(0xFF243B2D),
    },
    'Synthwave': {
      'background': Color(0xFF160D22),
      'surface': Color(0xFF261438),
      'accent': Color(0xFFFF4FD8),
      'text': Color(0xFFFCE7F8),
      'muted': Color(0xFFC084FC),
      'rules': Color(0xFF432261),
    },
    'Nordic Light': {
      'background': Color(0xFFF4F6F8),
      'surface': Color(0xFFFFFFFF),
      'accent': Color(0xFF2563EB),
      'text': Color(0xFF1E293B),
      'muted': Color(0xFF64748B),
      'rules': Color(0xFFE2E8F0),
    },
    'Warm Parchment': {
      'background': Color(0xFFF6F3EC),
      'surface': Color(0xFFFFFFFF),
      'accent': Color(0xFFD97706),
      'text': Color(0xFF292524),
      'muted': Color(0xFF78716C),
      'rules': Color(0xFFE7E0D3),
    },
  };
}
