import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoSheetRoute;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/172010
  // In go_router, a CupertinoSheetRoute pushed in a branch of a stateful
  // shell, closed by dragging it down, popped the root navigator and with it
  // every page. Flutter fixed it (flutter/flutter#173103): the drag pops the
  // sheet's own navigator.
  // Steps: Home pushes TabsHost, whose AutoTabsRouter shows TabA with its own
  // stack; push SheetRoute, a CustomRoute whose customRouteBuilder makes a
  // CupertinoSheetRoute, in TabA's stack; drag the sheet down.
  // Should: only the sheet closes; TabA's first page, TabsHost and Home stay.
  testWidgets('Dragging down a CupertinoSheetRoute pushed in a tab closes only the sheet (flutter/flutter#172010)', (
    tester,
  ) async {
    PageInfo page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: page('Home'), path: '/'),
        AutoRoute(
          page: PageInfo('TabsHost', builder: (_) => const AutoTabsRouter(routes: [_Route('TabA'), _Route('TabB')])),
          path: '/tabs',
          children: [
            AutoRoute(
              page: const EmptyShellRoute('TabA'),
              path: 'a',
              children: [
                AutoRoute(page: page('TabAHome'), path: ''),
                CustomRoute(
                  page: page('SheetRoute'),
                  path: 'sheet',
                  customRouteBuilder: <T>(_, child, page) =>
                      CupertinoSheetRoute<T>(settings: page, scrollableBuilder: (_, _) => child),
                ),
              ],
            ),
            AutoRoute(page: page('TabB'), path: 'b'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const _Route('TabsHost')));
    await tester.pumpAndSettle();
    final tabA = router.innerRouterOf<TabsRouter>('TabsHost')!.stackRouterOfIndex(0)!;
    unawaited(tabA.push(const _Route('SheetRoute')));
    await tester.pumpAndSettle();
    expect(find.text('SheetRoute'), findsOneWidget);

    await tester.drag(find.text('SheetRoute'), const Offset(0, 600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SheetRoute'), findsNothing);
    expect(tabA.stack.map((page) => page.name), ['TabAHome']);
    expect(router.stack.map((page) => page.name), ['Home', 'TabsHost']);
    expect(find.text('TabAHome'), findsOneWidget);
  });
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
