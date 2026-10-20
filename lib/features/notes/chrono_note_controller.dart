import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/chrono_helper.dart';

class ChronoNoteController extends TextEditingController {
  final Color highlightColor;

  ChronoNoteController({
    super.text,
    this.highlightColor = AppColors.amber,
  });

  List<ParsedDateSpan> get detectedDates => ChronoHelper.parseDates(text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <InlineSpan>[];
    final parsed = ChronoHelper.parseDates(text);

    if (parsed.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    var currentIndex = 0;

    for (final item in parsed) {
      final start = item.startIndex.clamp(0, text.length);
      final end = item.endIndex.clamp(0, text.length);

      if (start < currentIndex) continue;

      // Normal text before the date mention
      if (start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, start),
          style: style,
        ));
      }

      // Highlighted date mention
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: style?.copyWith(
            backgroundColor: highlightColor.withValues(alpha: 0.22),
            color: highlightColor,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: highlightColor.withValues(alpha: 0.6),
            decorationStyle: TextDecorationStyle.dashed,
          ),
        ),
      );

      currentIndex = end;
    }

    // Remaining text after the last date mention
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return TextSpan(style: style, children: spans);
  }
}
