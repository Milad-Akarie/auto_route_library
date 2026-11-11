import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Of two buttons pressed at once with two fingers, only the first opens its
// page, as with Navigator.push.
// https://github.com/flutter/flutter/issues/160504
// Headless test: auto_route/test/simultaneous_taps_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('simultaneous taps', () {
    RootStackRouter buildRouter() => .build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(page: SecondRoute.page, path: '/a'),
        AutoRoute(page: ThirdRoute.page, path: '/b'),
      ],
    );

    for (final holdB in [false, true]) {
      // Steps: press 'Open A' and 'Open B' with two fingers, lift the finger on
      // A, then lift the finger on B, at once or once A has opened.
      // Should: SecondRoute (A) opens; ThirdRoute (B) does not open over it.
      testWidgets('Two buttons pressed at once open one page '
          '(${holdB ? 'B held while A opens' : 'lifted together'})', (
        tester,
      ) async {
        final router = buildRouter();
        await pumpRouterApp(tester, router);
        final a = await tester.startGesture(
          tester.getCenter(find.text('Open A')),
          pointer: 1,
        );
        final b = await tester.startGesture(
          tester.getCenter(find.text('Open B')),
          pointer: 2,
        );
        await a.up();
        if (holdB) await tester.pumpAndSettle();
        await b.up();
        await tester.pumpAndSettle();

        expect(router.stack.map((p) => p.name), [
          _HomeRoute.pageName,
          SecondRoute.name,
        ]);
        expectTopPage(router, SecondRoute.name);
      });
    }
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'HomeRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => context.router.push(const SecondRoute()),
              child: const Text('Open A'),
            ),
            ElevatedButton(
              onPressed: () => context.router.push(const ThirdRoute()),
              child: const Text('Open B'),
            ),
          ],
        ),
      ),
    ),
  );
}
