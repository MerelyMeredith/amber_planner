import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/theme_controller.dart';
import 'domain/models/task.dart';
import 'features/agenda/hourly_agenda_widget.dart';
import 'features/calendar/calendar_widget.dart';
import 'features/notes/notes_panel.dart';
import 'features/window/window_title_bar.dart';
import 'services/mock_planner_facade.dart';
import 'services/planner_facade.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide native titlebar and initialize window_manager on Windows
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(960, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {
      // In test environments or unsupported runner setups, proceed without error
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeController settings;
  late final PlannerFacade facade;

  @override
  void initState() {
    super.initState();
    settings = ThemeController();
    settings.load();
    facade = MockPlannerFacade();
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Amber Planner',
          theme: settings.theme,
          home: MyHomePage(
            controller: settings,
            facade: facade,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ThemeController controller;
  final PlannerFacade facade;

  const MyHomePage({
    super.key,
    required this.controller,
    required this.facade,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ThemeController get settings => widget.controller;
  PlannerFacade get facade => widget.facade;

  // Opens on the actual current day, month, year as requested
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = settings.getColor('rules').withValues(alpha: 0.4);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Title Bar (Only renders on Windows, hides on other platforms)
            const WindowTitleBar(title: 'Amber Planner'),

            // 3-Panel Main Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: Calendar (Top Left) & Hourly Agenda (Bottom Left)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          // Top-Left: 5-week non-overflowing Calendar with World Holidays
                          Expanded(
                            flex: 5,
                            child: StreamBuilder<Map<DateTime, double>>(
                              stream: facade.watchMonthDensities(
                                _selectedDate.year,
                                _selectedDate.month,
                              ),
                              builder: (context, snapshot) {
                                final densities = snapshot.data ?? const {};
                                return CalendarWidget(
                                  selectedDate: _selectedDate,
                                  densities: densities,
                                  themeController: settings,
                                  onDateSelected: _onDateSelected,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Bottom-Left: Hourly Agenda with live tasks stream
                          Expanded(
                            flex: 6,
                            child: StreamBuilder<List<Task>>(
                              stream: facade.watchTasks(_selectedDate),
                              builder: (context, snapshot) {
                                final tasks = snapshot.data ?? const [];
                                return HourlyAgendaWidget(
                                  selectedDate: _selectedDate,
                                  tasks: tasks,
                                  themeController: settings,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider between left panels and notes screen
                  Container(
                    width: 1,
                    color: dividerColor,
                  ),

                  // Right Column: Notes Screen with Chrono date highlight & AI Action Rail
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: NotesPanel(
                        selectedDate: _selectedDate,
                        facade: facade,
                        themeController: settings,
                        onJumpToDate: _onDateSelected,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
