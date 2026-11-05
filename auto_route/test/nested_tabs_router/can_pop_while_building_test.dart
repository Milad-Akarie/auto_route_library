import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#119677: canPop() called while the shell builds its app
// bar, on the first frame, threw "Unexpected null value".
// Steps: the first page is an AutoTabsScaffold whose appBarBuilder calls
// canPop on the tabs router and on the root router. canPop should return
// false on a lone tab page without throwing, and true once a page is pushed
// inside a tab.
void main() {
  testWidgets('canPop in the app bar builder answers on the first frame and after a push in a tab', (tester) async {
    final heard = <({bool tabs, bool root})>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'TabsScreen',
            builder: (_) => AutoTabsScaffold(
              routes: const [PageRouteInfo('FeedTab'), PageRouteInfo('Profile')],
              appBarBuilder: (context, tabsRouter) {
                heard.add((tabs: tabsRouter.canPop(), root: context.router.root.canPop()));
                return AppBar(title: const Text('Shell'));
              },
            ),
          ),
          path: '/',
          children: [
            AutoRoute(
              page: _feedTab,
              path: 'feed',
              children: [
                AutoRoute(page: _page('FeedList'), path: ''),
                AutoRoute(page: _page('FeedPost'), path: 'post'),
              ],
            ),
            AutoRoute(page: _page('Profile'), path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(tester.takeException(), isNull);
    expect(heard.firstOrNull, (tabs: false, root: false));

    unawaited(router.navigatePath('/feed/post'));
    await tester.pumpAndSettle();
    heard.clear();
    // The app bar builds again whenever the tabs router notifies.
    router.innerRouterOf<TabsRouter>('TabsScreen')!.notifyAll();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.topRoute.name, 'FeedPost');
    expect(heard.lastOrNull, (tabs: true, root: true));
  });
}

final _feedTab = PageInfo('FeedTab', builder: (_) => const AutoRouter());

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));
