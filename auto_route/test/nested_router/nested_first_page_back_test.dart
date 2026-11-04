import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#111861: on the first page of a shell route, the Android
// back button did nothing instead of closing the app.
// Steps: a host page with a nested router showing its initial page, press
// back.
// Should: nothing is left to pop, so the router lets the platform handle back
// (maybePop is false) and the page stays, as for any first page.
void main() {
  testWidgets('Back on the first page of a shell route is left to the platform', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(name: 'MainRoute', path: 'main', initial: true, builder: (_, _) => const Text('main')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('main'), findsOneWidget);
    expect(await router.maybePop(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('main'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
