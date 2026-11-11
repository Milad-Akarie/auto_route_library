import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/2049
// (auto_route 8.2.0; a comment says it should be fixed in the next version).
// Setup, as in the report: CupertinoRoutes Home (initial) and ARouter, an
// empty router page whose children are A and BRouter, and BRouter's only
// child is B.
// Steps: on Home, call replaceAll with Home, then ARouter holding A and
// BRouter (which holds B), then go back with the iOS swipe and with system
// back.
// Happened: back went all the way to Home.
// Should: back from B shows A, and only back from A shows Home.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        CupertinoRoute(page: _page('Home'), path: '/', initial: true),
        CupertinoRoute(
          page: PageInfo('ARouter', builder: (_) => const AutoRouter()),
          path: '/a-router',
          children: [
            CupertinoRoute(page: _page('A'), path: 'a'),
            CupertinoRoute(
              page: PageInfo('BRouter', builder: (_) => const AutoRouter()),
              path: 'b-router',
              children: [CupertinoRoute(page: _page('B'), path: 'b')],
            ),
          ],
        ),
      ],
    );
  });

  final backs = {
    'the iOS swipe': (swipeBack, iosTheme),
    'system back': (systemBack, androidTheme),
  };
  for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
    testWidgets('$name after replaceAll with nested routes shows A', (
      tester,
    ) async {
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: theme, routerConfig: router.config()),
      );
      await tester.pumpAndSettle();
      unawaited(
        router.replaceAll([
          const NamedRoute('Home'),
          const NamedRoute(
            'ARouter',
            children: [
              NamedRoute('A'),
              NamedRoute('BRouter', children: [NamedRoute('B')]),
            ],
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);

      await back(tester);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      await back(tester);

      expect(find.text('Home'), findsOneWidget);
    });
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
