import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/141267
// Setup: the app's first page holds tabs, a dev tab and a wallet tab, each
// with its own stack; the wallet tab's stack declares a banner page.
// Steps: on the dev tab's first page, push the wallet tab's banner page, go
// back, and push it again.
// Should: no assertion either time; the banner page opens on top, in a new
// tabs page on the wallet tab, and back returns to the dev tab's first page.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _homePage,
          path: '/',
          children: [
            AutoRoute(
              page: const EmptyShellRoute('DevTab'),
              path: 'dev',
              children: [AutoRoute(page: _page('DevRoute'), path: '')],
            ),
            AutoRoute(
              page: const EmptyShellRoute('WalletTab'),
              path: 'wallet',
              children: [
                AutoRoute(page: _page('WalletRoute'), path: ''),
                AutoRoute(page: _page('BannerRoute'), path: 'banner'),
              ],
            ),
          ],
        ),
      ],
    );
  });

  for (final (how, push) in [
    (
      'push(BannerRoute())',
      (StackRouter root) => root.push(const _Route('BannerRoute')),
    ),
    (
      "pushPath('/wallet/banner')",
      (StackRouter root) => root.pushPath('/wallet/banner'),
    ),
  ]) {
    testWidgets(
      "Pushing the other tab's page with $how twice opens it each time",
      (tester) async {
        await pumpRouterConfigApp(tester, router.config());
        expect(find.text('DevRoute'), findsOneWidget);

        for (var i = 0; i < 2; i++) {
          unawaited(push(router));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('BannerRoute'), findsOneWidget);
          // A new tabs page opens on top, on the wallet tab.
          expect(router.stack.map((page) => page.name), [
            'HomeRoute',
            'HomeRoute',
          ]);
          expect(router.urlState.url, '/wallet/banner');

          await router.maybePopTop();
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'after router.maybePopTop()',
          );
          expect(find.text('BannerRoute'), findsNothing);
          expect(find.text('DevRoute'), findsOneWidget);
          expect(router.stack.map((page) => page.name), ['HomeRoute']);
        }
      },
    );
  }
}

final _homePage = PageInfo(
  'HomeRoute',
  builder: (_) =>
      const AutoTabsRouter(routes: [_Route('DevTab'), _Route('WalletTab')]),
);

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
