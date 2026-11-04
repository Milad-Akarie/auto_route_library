import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'back_test_utils.dart';
import 'build_counts.dart';
import 'router_test_utils.dart';

void main() {
  // Reproduces flutter/flutter#99577 in auto_route terms.
  // Steps: open Home, push Modal1, then Modal2, both full screen dialogs;
  // press Android back.
  // Happens in go_router: Modal1 and Modal2 build again on the back.
  // Should: Modal2 closes; Home and Modal1 don't build again.
  testWidgets('System back over two modal pages builds none of them again (flutter/flutter#99577)', (tester) async {
    final builds = <String, int>{};
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: countedPage('Home', builds), path: '/'),
        AutoRoute(page: countedPage('Modal1', builds), path: '/modal1', fullscreenDialog: true),
        AutoRoute(page: countedPage('Modal2', builds), path: '/modal2', fullscreenDialog: true),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('Modal1')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('Modal2')));
    await tester.pumpAndSettle();
    expect(builds, {'Home': 1, 'Modal1': 1, 'Modal2': 1});

    await systemBack(tester);

    expectTopPage(router, 'Modal1');
    expect(builds, {'Home': 1, 'Modal1': 1, 'Modal2': 1});
  });
}
