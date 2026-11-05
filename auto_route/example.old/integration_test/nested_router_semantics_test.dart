import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Widgets laid out before a nested router stay in the semantics tree.
// Reproduces https://github.com/flutter/flutter/issues/150978 in auto_route.
// Headless test: auto_route/test/nested_router_semantics_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: with semantics on, open HostRoute, a Row of Text('Left 1'),
  // Text('Left 2'), a nested AutoRouter showing Text('Center'), and
  // Text('Right').
  // Should: a screen reader finds every Text.
  testWidgets('widgets before a nested router stay in the semantics tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => const Scaffold(
              body: SafeArea(
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text('Left 1'),
                    Padding(padding: .all(8)),
                    Text('Left 2'),
                    Expanded(child: AutoRouter()),
                    Expanded(child: Text('Right')),
                  ],
                ),
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'ChildRoute',
                builder: (_) => const Text('Center'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    for (final label in ['Left 1', 'Left 2', 'Center', 'Right']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });
}
