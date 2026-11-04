import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/146045
  // In go_router, with a dialog open over a page pushed in a tab, Android
  // back popped the tab's page first and left the dialog open.
  // Steps: the app's first page holds an AutoTabsRouter with tab A and tab B;
  // tab A has DetailsA and DetailsC. Push DetailsC in tab A, open a dialog
  // from it with showDialog, which uses the root navigator, then press
  // system back twice.
  // Should: the first back closes the dialog and DetailsC stays; the second
  // pops DetailsC.
  for (final useRootNavigator in [true, false]) {
    testWidgets('System back closes a dialog over a tab page before the page, '
        'useRootNavigator: $useRootNavigator (flutter/flutter#146045)', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo('HomeRoute', builder: (_) => const AutoTabsRouter(routes: [_Route('TabA'), _Route('TabB')])),
            path: '/',
            children: [
              AutoRoute(
                page: const EmptyShellRoute('TabA'),
                path: 'a',
                children: [
                  AutoRoute(page: _page('DetailsA'), path: ''),
                  AutoRoute(page: _page('DetailsC'), path: 'c'),
                ],
              ),
              AutoRoute(page: _page('TabB'), path: 'b'),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final tabA = router.innerRouterOf<TabsRouter>('HomeRoute')!.stackRouterOfIndex(0)!;
      unawaited(tabA.push(const _Route('DetailsC')));
      await tester.pumpAndSettle();

      showDialog<void>(
        context: tester.element(find.text('DetailsC')),
        useRootNavigator: useRootNavigator,
        builder: (_) => const AlertDialog(content: Text('Dialog')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsOneWidget);

      await systemBack(tester);
      expect(find.text('Dialog'), findsNothing);
      expect(tabA.stack.map((page) => page.name), ['DetailsA', 'DetailsC']);
      expect(find.text('DetailsC'), findsOneWidget);

      await systemBack(tester);
      expect(tabA.stack.map((page) => page.name), ['DetailsA']);
    });
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
