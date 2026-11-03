import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(routes: [
      AutoRoute(page: _page('MenuRoute'), initial: true),
      AutoRoute(page: _page('RecordRoute')),
      AutoRoute(page: _page('FormRoute')),
      AutoRoute(page: _page('LoginRoute')),
    ]);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2008
  // With MenuRoute -> RecordRoute in the stack, and with
  // MenuRoute -> RecordRoute -> FormRoute, call replaceAll([LoginRoute()])
  // from the top page, with no nested navigation. Both times LoginRoute
  // should be the only page, never a blank screen with an empty stack.
  for (final pushed in [
    ['RecordRoute'],
    ['RecordRoute', 'FormRoute'],
  ]) {
    testWidgets('replaceAll from ${pushed.last} leaves only the new page', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      for (final name in pushed) {
        router.push(PageRouteInfo(name));
        await tester.pumpAndSettle();
      }
      expectCurrentPage(router, pushed.last);

      final topContext = tester.element(find.text(pushed.last));
      topContext.router.replaceAll([const PageRouteInfo('LoginRoute')]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), ['LoginRoute']);
      expectCurrentPage(router, 'LoginRoute');
    });
  }
}

PageInfo _page(String name) => PageInfo(name, builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)));
