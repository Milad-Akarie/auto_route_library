import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#129878: in go_router's StatefulShellRoute, the path param of
// the route above the shell was lost after goBranch.
// Setup: '/list/:id' holds tabs 'a' and 'b'; the page of each tab shows the
// id it inherits.
// Steps: open '/list/7/a?q=1', switch to tab B.
// Should: tab B shows id 7 and the url is '/list/7/b'.
PageInfo _tabPage(String name) =>
    PageInfo(name, builder: (data) => Text('$name ${data.inheritedPathParams.getString('id')}'));

void main() {
  testWidgets('The path param of the route above the tabs stays after a tab switch', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/list/:id',
          page: PageInfo(
            'ListRoute',
            builder: (_) => const AutoTabsScaffold(routes: [NamedRoute('ARoute'), NamedRoute('BRoute')]),
          ),
          children: [
            AutoRoute(path: 'a', page: _tabPage('ARoute')),
            AutoRoute(path: 'b', page: _tabPage('BRoute')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/list/7/a?q=1'));
    await tester.pumpAndSettle();
    expect(find.text('ARoute 7'), findsOneWidget);

    router.innerRouterOf<TabsRouter>('ListRoute')!.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('BRoute 7'), findsOneWidget);
    expect(router.currentUrl, '/list/7/b');
  });
}
