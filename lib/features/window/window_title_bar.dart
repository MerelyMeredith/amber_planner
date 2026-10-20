import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_colors.dart';

class WindowTitleBar extends StatefulWidget {
  final String title;

  const WindowTitleBar({
    super.key,
    this.title = 'Amber Planner',
  });

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_isWindows) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (_isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final max = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = max;
      });
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    // Only display on Windows per user request
    if (!_isWindows) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rulesColor = theme.dividerColor.withValues(alpha: 0.35);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: rulesColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Drag to move window area
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Windows-style Square Window Buttons (46px wide x 32px high)
          _WindowSquareButton(
            icon: Icons.remove,
            tooltip: 'Minimize',
            onTap: () => windowManager.minimize(),
          ),
          _WindowSquareButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: _isMaximized ? 12 : 14,
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            onTap: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WindowSquareButton(
            icon: Icons.close,
            tooltip: 'Close',
            isClose: true,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowSquareButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool isClose;
  final VoidCallback onTap;

  const _WindowSquareButton({
    required this.icon,
    this.iconSize = 14,
    required this.tooltip,
    this.isClose = false,
    required this.onTap,
  });

  @override
  State<_WindowSquareButton> createState() => _WindowSquareButtonState();
}

class _WindowSquareButtonState extends State<_WindowSquareButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color iconColor = Theme.of(context).colorScheme.onSurface;

    if (_isHovered) {
      if (widget.isClose) {
        bg = AppColors.windowCloseHover;
        iconColor = Colors.white;
      } else {
        bg = AppColors.windowButtonHover;
      }
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: 46,
            height: 32,
            color: bg,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
