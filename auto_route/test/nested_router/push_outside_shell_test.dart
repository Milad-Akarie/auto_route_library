import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _pushing(String name, {String? to}) => .new(
  name,
  builder: (_) => Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          Text(name),
          if (to != null)
            TextButton(onPressed: () => unawaited(context.router.push(NamedRoute(to))), child: Text('push $to')),
        ],
      ),
    ),
  ),
);

// flutter/flutter#156585: go_router asserted "!keyReservation.contains(key)"
// when a page in a shell pushed a page outside the shell, and that page
// pushed itself again.
// Steps: a tab page pushes SearchRoute, which lives outside the tabs; the
// search page pushes SearchRoute again.
// Should: both searches are in the root stack above the tabs, no
// exception, and back returns to the tabs.
void main() {
  testWidgets('A tab page pushes a page outside the tabs, which pushes itself again (flutter/flutter#156585)', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HostRoute', builder: (_) => const AutoTabsRouter(routes: [_ATab(), _BTab()])),
          children: [
            AutoRoute(
              path: 'a',
              page: _pushing('ATab', to: 'SearchRoute'),
            ),
            AutoRoute(path: 'b', page: _pushing('BTab')),
          ],
        ),
        AutoRoute(
          path: '/search',
          page: _pushing('SearchRoute', to: 'SearchRoute'),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('ATab'), findsOneWidget);

    await tester.tap(find.text('push SearchRoute'));
    await tester.pumpAndSettle();
    expect(find.text('SearchRoute'), findsOneWidget);

    await tester.tap(find.text('push SearchRoute'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), ['HostRoute', 'SearchRoute', 'SearchRoute']);

    for (var i = 0; i < 2; i++) {
      router.pop();
    }
    await tester.pumpAndSettle();
    expect(find.text('ATab'), findsOneWidget, reason: 'after router.pop()');
  });
}

class _ATab extends PageRouteInfo<void> {
  const new() : super('ATab');
}

class _BTab extends PageRouteInfo<void> {
  const new() : super('BTab');
}
