import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

final _homePage = PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('HomeRoute')));

// A small card in the middle of the screen, so a tap in a corner hits the
// route's barrier.
final _cardPage = PageInfo(
  'CardRoute',
  builder: (_) => const Center(
    child: SizedBox.square(dimension: 100, child: Card(child: Text('CardRoute'))),
  ),
);

Future<RootStackRouter> _pumpWithCard(WidgetTester tester, CustomRoute cardRoute) async {
  final router = RootStackRouter.build(
    routes: [
      AutoRoute(path: '/', page: _homePage),
      cardRoute,
    ],
  );
  await pumpRouterApp(tester, router);
  unawaited(router.push(const NamedRoute('CardRoute')));
  await tester.pumpAndSettle();
  expect(find.text('CardRoute'), findsOneWidget);
  return router;
}

void main() {
  // Reproduces flutter/flutter#102289 in auto_route terms.
  // Steps: a CustomRoute with opaque: false, barrierDismissible: true and a
  // barrier color shows a small card over the home page. Tap outside the card.
  // Happens: nothing; the route ignores barrierDismissible.
  // Should: the route pops, as a PageRouteBuilder with the same flags does.
  testWidgets('Tapping the barrier of a barrierDismissible CustomRoute pops it (flutter/flutter#102289)', (
    tester,
  ) async {
    final router = await _pumpWithCard(
      tester,
      CustomRoute(
        path: '/card',
        page: _cardPage,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
      ),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
    expect(find.text('CardRoute'), findsNothing);
  });

  // A CustomRoute that doesn't ask for it keeps its page on a barrier tap,
  // as a PageRouteBuilder does by default.
  testWidgets('A CustomRoute is not barrierDismissible by default (flutter/flutter#102289)', (tester) async {
    final router = await _pumpWithCard(
      tester,
      CustomRoute(path: '/card', page: _cardPage, opaque: false, barrierColor: Colors.black54),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'CardRoute']);
  });
}
