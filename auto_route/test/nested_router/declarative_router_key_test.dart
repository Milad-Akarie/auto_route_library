import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Found by DCM's avoid-unused-parameters while moving the package to
// very_good_analysis; no upstream issue.
// Steps: a page builds `AutoRouter.declarative(key: hostKey, routes: ...)`
// with a GlobalKey, then looks the router up through the key.
// Happens: the key is accepted and dropped, so `hostKey.currentWidget` is null
// and `find.byKey(hostKey)` finds nothing. A ValueKey meant to reset the
// router's state does nothing either.
// Should: the declarative router carries the key it was given, as
// AutoRouter() does.
void main() {
  testWidgets('AutoRouter.declarative carries the key it is given', (
    tester,
  ) async {
    final hostKey = GlobalKey();
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(
              key: hostKey,
              routes: (_) => [const NamedRoute('HomeRoute')],
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const Text('HomeRoute'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(find.byKey(hostKey), findsOneWidget);
    expect(hostKey.currentWidget, isNotNull);
  });
}
