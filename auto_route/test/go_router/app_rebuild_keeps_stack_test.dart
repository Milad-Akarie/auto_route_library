import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Rebuilding MaterialApp.router with other debug flags or another builder
// keeps the page stack and the pages' state.
// The same scenario as flutter/flutter#115427 in go_router, where the
// rebuild closed the pages over the root one.
void main() {
  final changes = {
    'showPerformanceOverlay': const _AppSettings(showPerformanceOverlay: true),
    'showSemanticsDebugger': const _AppSettings(showSemanticsDebugger: true),
    'builder': const _AppSettings(wrap: true),
  };

  for (final MapEntry(key: change, value: settings) in changes.entries) {
    // Steps: MaterialApp.router(routerConfig:) shows ARoute; push BRoute;
    // rebuild the app with $change changed, then back again.
    // Should: the stack stays [ARoute, BRoute], ARoute's state is not
    // created again, and going back shows ARoute.
    testWidgets('changing MaterialApp.router $change keeps the stack', (tester) async {
      var created = 0;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('ARoute', builder: (_) => _CountingPage(onCreate: () => created++)),
          ),
          AutoRoute(
            path: '/b',
            page: PageInfo('BRoute', builder: (_) => const Text('BRoute')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final config = router.config();
      final app = ValueNotifier(const _AppSettings());
      addTearDown(app.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: app,
          builder: (_, appSettings, _) => MaterialApp.router(
            routerConfig: config,
            showPerformanceOverlay: appSettings.showPerformanceOverlay,
            showSemanticsDebugger: appSettings.showSemanticsDebugger,
            builder: appSettings.wrap ? (_, child) => ColoredBox(color: Colors.white, child: child) : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/b'));
      await tester.pumpAndSettle();
      expect(created, 1);

      for (final next in [settings, const _AppSettings()]) {
        app.value = next;
        await tester.pumpAndSettle();
        expect(router.stack.map((page) => page.name), ['ARoute', 'BRoute']);
        expect(find.text('BRoute'), findsOneWidget);
      }

      await router.maybePop();
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), ['ARoute']);
      expect(find.text('ARoute'), findsOneWidget);
      expect(created, 1);
    });
  }
}

class _AppSettings {
  const _AppSettings({this.showPerformanceOverlay = false, this.showSemanticsDebugger = false, this.wrap = false});

  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool wrap;
}

class _CountingPage extends StatefulWidget {
  const _CountingPage({required this.onCreate});

  final VoidCallback onCreate;

  @override
  State<_CountingPage> createState() => _CountingPageState();
}

class _CountingPageState extends State<_CountingPage> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const Text('ARoute');
}
