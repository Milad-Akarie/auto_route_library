import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#123369: go_router 6.5.0 threw "Bad state: Future already
// completed" the second time a dialog was closed with pop.
// Setup: a page 'Settings' with a button that shows a dialog.
// Steps: open Settings, show the dialog, close it with router.pop(), show it
// again, close it with router.pop() again.
// Should: no error, and the dialog is gone each time.
void main() {
  testWidgets('A dialog shown and closed twice with router.pop closes both times without an error', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/settings',
          page: PageInfo(
            'SettingsRoute',
            builder: (_) => Builder(
              builder: (context) => TextButton(
                onPressed: () => unawaited(showDialog<void>(context: context, builder: (_) => const Text('Dialog'))),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('SettingsRoute')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsNothing);
      expect(find.text('Show'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(router.currentUrl, '/settings');
  });
}
