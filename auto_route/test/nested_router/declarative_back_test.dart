import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1120
// Steps: a page builds AutoRouter.declarative with the routes [A, B] from the
// app's own state; press the system back button.
// Reported: the app closed, and onPopRoute never fired.
// Should: onPopRoute is called with the route on top, and the app stays open
// while the app's state drops it.
void main() {
  testWidgets('system back calls onPopRoute of a declarative router with the top route', (tester) async {
    final depth = ValueNotifier(2);
    addTearDown(depth.dispose);
    final popped = <String>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => ValueListenableBuilder<int>(
              valueListenable: depth,
              builder: (_, value, _) => AutoRouter.declarative(
                routes: (_) => [const PageRouteInfo('ARoute'), if (value > 1) const PageRouteInfo('BRoute')],
                onPopRoute: (route, _) {
                  popped.add(route.name);
                  depth.value = 1;
                },
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('ARoute', builder: (_) => const Text('A')),
            ),
            AutoRoute(
              path: 'b',
              page: PageInfo('BRoute', builder: (_) => const Text('B')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('B'), findsOneWidget);

    await systemBack(tester);
    expect(popped, ['BRoute']);
    expect(find.text('B'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
