import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// A back in the frame replaceAll lands never removes the router's last page.
// Steps: open Home, then Second; call replaceAll([Home]), and in the same
// frame press system back, or call maybePop or pop. Home should show alone.
// The pop applies to what the navigator has built, as it did before the fix
// for flutter/flutter#145573, which removed the not yet built Home and left
// the router with no page.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('Second')),
      ],
    );
  });

  final backs = <String, FutureOr<void> Function(WidgetTester)>{
    'system back': (tester) => tester.binding.handlePopRoute(),
    'maybePop': (_) => router.maybePop(),
    'pop': (_) => router.pop(),
  };

  for (final MapEntry(key: name, value: back) in backs.entries) {
    testWidgets('$name in the frame replaceAll lands keeps the new page', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const PageRouteInfo('Second')));
      await tester.pumpAndSettle();

      unawaited(router.replaceAll(const [PageRouteInfo('Home')]));
      // Home is added a microtask later; the navigator builds it next frame.
      await Future<void>.value();
      expect(router.stack.map((page) => page.routeData.name), ['Home']);
      await back(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.routeData.name), [
        'Home',
      ], reason: 'after back(tester)');
      expectTopPage(router, 'Home');
    });
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
