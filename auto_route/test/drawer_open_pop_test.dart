import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#82437: with a drawer open on the top page, removing the
// top pages from Navigator.pages left the old page on screen: the update
// popped the drawer, a local history entry of the page, and not the page.
// Steps: pages [P0, P1, P2], each a Scaffold with a drawer; open P2's
// drawer, then go back to P0 by popUntilRoot, by navigatePath('/') or by
// replaceAll.
// Should: P0 shows, the drawer is gone, and nothing throws.
void main() {
  final returns = <String, void Function(StackRouter)>{
    'popUntilRoot': (router) => router.popUntilRoot(),
    'navigatePath': (router) => unawaited(router.navigatePath('/')),
    'replaceAll': (router) =>
        unawaited(router.replaceAll([const PageRouteInfo('P0')])),
  };

  for (final MapEntry(key: name, value: goBack) in returns.entries) {
    testWidgets(
      '$name with a drawer open on the top page shows the first page',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            for (final page in ['P0', 'P1', 'P2'])
              AutoRoute(
                path: page == 'P0' ? '/' : '/${page.toLowerCase()}',
                page: PageInfo(
                  page,
                  builder: (_) => Scaffold(
                    appBar: AppBar(),
                    drawer: const Drawer(child: Text('Drawer')),
                    body: Text(page),
                  ),
                ),
              ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.pushPath('/p1'));
        await tester.pumpAndSettle();
        unawaited(router.pushPath('/p2'));
        await tester.pumpAndSettle();
        tester.state<ScaffoldState>(find.byType(Scaffold).last).openDrawer();
        await tester.pumpAndSettle();
        expect(find.text('Drawer'), findsOneWidget);

        goBack(router);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), ['P0']);
        expect(find.text('P0'), findsOneWidget);
        expect(find.text('P2'), findsNothing);
        expect(find.text('Drawer'), findsNothing);
      },
    );
  }
}
