import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class RuledNotes extends StatefulWidget {
  final ThemeController themeController;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const RuledNotes({
    super.key,
    required this.themeController,
    this.controller,
    this.onChanged,
    this.hintText = 'Write your thoughts, journal, or todos here...',
  });

  /// Normalizes note content before passing to AI:
  /// Collapses multiple empty lines inserted for visual spacing into clean single breaks,
  /// and trims leading/trailing empty lines.
  static String sanitizeTextForAi(String raw) {
    return raw
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  State<RuledNotes> createState() => _RuledNotesState();
}

class _RuledNotesState extends State<RuledNotes> {
  late TextEditingController _textController;
  late ScrollController _scrollController;

  bool _ownsTextController = false;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(20, 16, 20, 16);

  double get _fontSize => widget.themeController.settings.fontSize;
  double get _lineHeight => _fontSize * 1.8;

  TextStyle get _textStyle => TextStyle(
    color: widget.themeController.getColor('text'),
    fontSize: _fontSize,
    height: 1.8,
  );

  StrutStyle get _strutStyle => StrutStyle(
    fontSize: _fontSize,
    height: 1.8,
    forceStrutHeight: true,
  );

  @override
  void initState() {
    super.initState();
    _initTextController();
    _scrollController = ScrollController();
  }

  void _initTextController() {
    _ownsTextController = widget.controller == null;
    _textController = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(covariant RuledNotes oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (_ownsTextController) {
        _textController.dispose();
      }
      _initTextController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsTextController) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event, double width) {
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final localY = event.localPosition.dy + scrollOffset - _padding.top;

    if (localY < 0) return;

    final targetLine = (localY / _lineHeight).floor();

    final painter = TextPainter(
      text: TextSpan(
        text: _textController.text.isEmpty ? ' ' : _textController.text,
        style: _textStyle,
      ),
      strutStyle: _strutStyle,
      textDirection: Directionality.of(context),
    );

    painter.layout(maxWidth: (width - _padding.horizontal).clamp(10.0, double.infinity));
    final currentLines = painter.computeLineMetrics().length;
    painter.dispose();

    if (targetLine < currentLines) return;

    // Fast-jump writing: Append blank lines so user can write on the tapped line
    final extraLines = targetLine - currentLines + 1;
    final newText = _textController.text + List.filled(extraLines, '\n').join();

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    widget.onChanged?.call(newText);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final backgroundColor = widget.themeController.getColor('background');
        final lineColor = widget.themeController.getColor('rules');
        final textColor = widget.themeController.getColor('text');
        final fontSize = widget.themeController.settings.fontSize;
        final rulerPadding = widget.themeController.settings.rulerPadding;
        final lineHeight = fontSize * 1.8;

        final textStyle = TextStyle(
          color: textColor,
          fontSize: fontSize,
          height: 1.8,
        );

        final strutStyle = StrutStyle(
          fontSize: fontSize,
          height: 1.8,
          forceStrutHeight: true,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              color: backgroundColor,
              child: Listener(
                onPointerDown: (event) {
                  _handlePointerDown(event, constraints.maxWidth);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.themeController.settings.ruledLines)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            final offset = _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                            return CustomPaint(
                              painter: _RuledPaperPainter(
                                lineColor: lineColor,
                                lineHeight: lineHeight,
                                topPadding: _padding.top,
                                scrollOffset: offset,
                                rulerPadding: rulerPadding,
                              ),
                            );
                          },
                        ),
                      ),
                    TextField(
                      controller: _textController,
                      scrollController: _scrollController,
                      onChanged: widget.onChanged,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: textStyle,
                      strutStyle: strutStyle,
                      cursorColor: theme.colorScheme.primary,
                      selectionControls: materialTextSelectionControls,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: textStyle.copyWith(
                          color: textColor.withValues(alpha: 0.35),
                        ),
                        border: InputBorder.none,
                        contentPadding: _padding,
                        isCollapsed: false,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;
  final double topPadding;
  final double scrollOffset;
  final double rulerPadding;

  const _RuledPaperPainter({
    required this.lineColor,
    required this.lineHeight,
    required this.topPadding,
    required this.scrollOffset,
    required this.rulerPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final firstLine = ((scrollOffset - topPadding) / lineHeight).floor().clamp(
      0,
      100000,
    );

    final lastLine = ((scrollOffset + size.height) / lineHeight).ceil() + 1;

    for (var i = firstLine; i <= lastLine; i++) {
      final y = topPadding + (i * lineHeight) - scrollOffset;

      if (y >= 0 && y <= size.height) {
        canvas.drawLine(
          Offset(size.width * rulerPadding, y),
          Offset(size.width - (size.width * rulerPadding), y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.rulerPadding != rulerPadding;
  }
}
