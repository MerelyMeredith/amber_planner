import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amber_planner/core/utils/chrono_helper.dart';
import 'package:amber_planner/features/notes/ruled_notes.dart';
import 'package:amber_planner/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Amber Planner prototype facade smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify Calendar panel (Mo/Tu/We weekdays)
    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);

    // Verify Role filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);

    // Verify Right action rail has AI bolt icon
    expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);

    // Test Settings Modal via Gear Icon
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'GENERAL'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'EDITOR'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'COLORS & THEMES'), findsOneWidget);

    // Close settings dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Test AI Extraction Flow via Lightning Bolt
    await tester.tap(find.byIcon(Icons.bolt_outlined));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Local AI Extraction Report'), findsOneWidget);
    expect(find.text('REVIEW & EDIT EXTRACTED TASKS'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
  });

  test('ChronoHelper parses natural language dates from note text', () {
    const noteText = 'Meeting with client tomorrow at 10am and project deadline next Friday 5pm';
    final parsed = ChronoHelper.parseDates(noteText);
    expect(parsed.length, greaterThanOrEqualTo(2));
    expect(parsed.first.matchedText.toLowerCase(), contains('tomorrow'));
  });

  test('RuledNotes.sanitizeTextForAi normalizes lines for AI', () {
    const raw = 'Task 1\n\n\n\n\nTask 2\n\n\n\nTask 3\n\n\n';
    final cleaned = RuledNotes.sanitizeTextForAi(raw);
    expect(cleaned, equals('Task 1\n\nTask 2\n\nTask 3'));
  });
}
