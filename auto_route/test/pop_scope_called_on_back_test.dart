import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1377
// ("WillPopScope not working in v6", no code given; WillPopScope is replaced
// by PopScope in current Flutter, so the test uses PopScope).
// Assumed setup: a page wrapped in PopScope(canPop: false) that records each
// blocked pop, once as a plain pushed page and once as a tab of an
// AutoTabsRouter (the maintainer asked whether it was a tab route).
// Steps: open the page, press system back, call router.maybePop().
// Happened: the callback was never called.
// Should: it is called once per back with didPop false, and the page stays.
void main() {
  testWidgets('system back calls the PopScope of a pushed page', (
    tester,
  ) async {
    final heard = <bool>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home', null), path: '/', initial: true),
        AutoRoute(page: _page('Guarded', heard), path: '/guarded'),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('Guarded')));
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(heard, [false]);
    expectCurrentPage(router, 'Guarded');

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expect(heard, [false, false]);
    expectCurrentPage(router, 'Guarded');
  });

  testWidgets('system back calls the PopScope of the active tab', (
    tester,
  ) async {
    final heard = <bool>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('TabsRoute', builder: (_) => const AutoTabsScaffold()),
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _page('TabOne', heard), path: 'one', initial: true),
            AutoRoute(page: _page('TabTwo', null), path: 'two'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final shownBefore = find.text('TabOne').evaluate().length;

    await systemBack(tester);

    expect(heard, [false]);
    expect((shownBefore, find.text('TabOne').evaluate().length), (1, 1));
  });
}

PageInfo _page(String name, List<bool>? heard) => .new(
  name,
  builder: (_) => PopScope(
    canPop: heard == null,
    onPopInvokedWithResult: (didPop, _) => heard?.add(didPop),
    child: Scaffold(body: Text(name)),
  ),
);
