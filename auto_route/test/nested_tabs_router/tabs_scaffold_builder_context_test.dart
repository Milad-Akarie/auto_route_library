import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Steps: an AutoTabsScaffold whose bottomNavigationBuilder looks up the
  // Scaffold from the context it is given.
  // Should: that context is below the Scaffold, so the lookup finds it.
  testWidgets('bottomNavigationBuilder gets a context below the Scaffold', (
    tester,
  ) async {
    ScaffoldState? found;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HostRoute',
          path: '/',
          builder: (_, _) => AutoTabsScaffold(
            routes: const [NamedRoute('Tab1Route')],
            bottomNavigationBuilder: (context, _) {
              found = Scaffold.maybeOf(context);
              return const SizedBox(height: 10);
            },
          ),
          children: [
            NamedRouteDef(
              name: 'Tab1Route',
              path: 'tab1',
              builder: (_, _) => const Text('tab'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    await tester.pumpAndSettle();

    expect(found, isNotNull);
  });
}
