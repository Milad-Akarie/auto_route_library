import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#135094, #140869, #136313: the only page of the app.
// Steps: (1) the only page has PopScope(canPop: false); press system back.
// (2) call maybePop() and pop() on a router with one page.
// Should: (1) the PopScope hears of the attempt and the page stays.
// (2) maybePop() answers true when a PopScope handled it, as documented,
// and false on a plain page; pop() throws nothing.
void main() {
  late RootStackRouter router;
  var attempts = <bool>[];
  setUp(() {
    attempts = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) => attempts.add(didPop),
              child: const Scaffold(body: Text('HomeRoute')),
            ),
          ),
        ),
      ],
    );
  });

  testWidgets('PopScope on the only page hears system back', (tester) async {
    await pumpRouterApp(tester, router);
    await systemBack(tester);
    expect(attempts, [false]);
    expectCurrentPage(router, 'HomeRoute');
  });

  testWidgets(
    'maybePop on the only page, handled by its PopScope, answers true',
    (tester) async {
      await pumpRouterApp(tester, router);
      expect(await router.maybePop(), isTrue);
      expect(attempts, [false]);
      expect(tester.takeException(), isNull);
      expectCurrentPage(router, 'HomeRoute');
    },
  );

  testWidgets('pop on the only page without a PopScope throws nothing', (
    tester,
  ) async {
    final plain = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'PlainRoute',
            builder: (_) => const Text('PlainRoute'),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, plain);
    expect(await plain.maybePop(), isFalse);
    plain.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
