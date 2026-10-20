import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_controller.dart';

class SettingsPanel extends StatelessWidget {
  final ThemeController controller;
  final double? aspectRatio;

  const SettingsPanel({
    super.key,
    required this.controller,
    this.aspectRatio,
  });

  static Future<void> show(BuildContext context, ThemeController controller) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 560,
            height: 520,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Preferences'),
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                elevation: 0,
              ),
              body: SettingsPanel(controller: controller),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: Theme.of(context).colorScheme.surface,
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              tabs: const [
                Tab(text: 'GENERAL'),
                Tab(text: 'EDITOR'),
                Tab(text: 'COLORS & THEMES'),
                Tab(text: 'ABOUT'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  GeneralSettingsTab(controller: controller),
                  EditorSettingsTab(controller: controller),
                  ColorSettingsTab(controller: controller),
                  const AboutSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: aspectRatio!,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}

class GeneralSettingsTab extends StatelessWidget {
  final ThemeController controller;

  const GeneralSettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('INTERFACE OPTIONS', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compact mode'),
              subtitle: const Text('Reduce interface padding and margins'),
              value: controller.settings.compactMode,
              onChanged: controller.setCompactMode,
            ),
          ],
        );
      },
    );
  }
}

class EditorSettingsTab extends StatelessWidget {
  final ThemeController controller;

  const EditorSettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('TYPOGRAPHY & RULING', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ruled paper lines'),
              subtitle: const Text('Draw notebook guide lines beneath text'),
              value: settings.ruledLines,
              onChanged: controller.setRuledLines,
            ),
            const SizedBox(height: 12),
            Text('Font size: ${settings.fontSize.round()} px'),
            Slider(
              min: 12,
              max: 26,
              divisions: 14,
              value: settings.fontSize,
              onChanged: controller.setFontSize,
            ),
            const SizedBox(height: 8),
            Text('Ruled lines inset: ${(settings.rulerPadding * 100).round()}%'),
            Slider(
              min: 0.0,
              max: 0.2,
              divisions: 20,
              value: settings.rulerPadding,
              onChanged: controller.setRulerPadding,
            ),
          ],
        );
      },
    );
  }
}

class ColorSettingsTab extends StatelessWidget {
  final ThemeController controller;

  const ColorSettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('PRESET THEMES', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.presets.keys.map((presetName) {
                final palette = AppColors.presets[presetName]!;
                final accent = palette['accent'] ?? Colors.blue;
                final bg = palette['background'] ?? Colors.black;

                return ActionChip(
                  avatar: CircleAvatar(radius: 6, backgroundColor: accent),
                  label: Text(presetName),
                  backgroundColor: bg.withValues(alpha: 0.3),
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                  onPressed: () => controller.applyPreset(presetName),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text('CUSTOM COLOR PALETTE', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),

            for (final entry in _colorChoices.entries) ...[
              Text(
                entry.key.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in entry.value)
                    _ColorChoice(
                      color: color,
                      selected: controller.getColor(entry.key) == color,
                      onTap: () => controller.setColor(entry.key, color),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  static const Map<String, List<Color>> _colorChoices = {
    'background': [
      Color(0xFF14171E),
      Color(0xFF0D140F),
      Color(0xFF160D22),
      Color(0xFF10141D),
      Color(0xFFF4F6F8),
      Color(0xFFF6F3EC),
    ],
    'surface': [
      Color(0xFF1F2530),
      Color(0xFF152219),
      Color(0xFF261438),
      Color(0xFF1B2330),
      Color(0xFFFFFFFF),
      Color(0xFFEDE8DE),
    ],
    'accent': [
      AppColors.amber,
      AppColors.cyan,
      AppColors.emerald,
      AppColors.neonPink,
      AppColors.violet,
      AppColors.coral,
    ],
    'text': [
      Color(0xFFE6EAF0),
      Color(0xFFD1FAE5),
      Color(0xFFFCE7F8),
      Color(0xFFE3EDF7),
      Color(0xFF1E293B),
      Color(0xFF292524),
    ],
    'muted': [
      Color(0xFF8B98A9),
      Color(0xFF6EE7B7),
      Color(0xFFC084FC),
      Color(0xFF7E92A7),
      Color(0xFF64748B),
      Color(0xFF78716C),
    ],
    'rules': [
      Color(0xFF2C3442),
      Color(0xFF243B2D),
      Color(0xFF432261),
      Color(0xFF273445),
      Color(0xFFE2E8F0),
      Color(0xFFE7E0D3),
    ],
  };
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 17, color: Colors.white)
            : null,
      ),
    );
  }
}

class AboutSettingsTab extends StatelessWidget {
  const AboutSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text('Amber Planner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('Local-first, offline-capable AI planner facade.'),
        SizedBox(height: 12),
        Text('Features:'),
        Text('• Dynamic 5-week non-overflowing calendar with World Holidays'),
        Text('• Chrono-powered real-time natural language date detection'),
        Text('• Live clock timeline with multi-column overlapping tasks'),
        Text('• Windows desktop custom chrome with square hitboxes'),
      ],
    );
  }
}
