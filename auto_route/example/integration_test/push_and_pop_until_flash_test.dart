import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pushAndPopUntil no longer shows the pages it removes while the new page
// slides in.
// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// Headless test: auto_route/test/simple_router/push_and_pop_until_flash_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    // Cupertino pages slide on every platform, web included.
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.cupertino(),
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
        AutoRoute(page: _page('BRoute')),
        AutoRoute(page: _page('CRoute')),
        AutoRoute(page: _page('DRoute')),
      ],
    );
  });

  // The pages on screen, bottom to top.
  List<String> shown() =>
      ['HomeRoute', 'BRoute', 'CRoute', 'DRoute'].where((name) => find.text(name).evaluate().isNotEmpty).toList();

  // Steps: open HomeRoute, BRoute and CRoute, then call pushAndPopUntil(DRoute)
  // with a predicate that keeps HomeRoute, and look at every frame while DRoute
  // slides in.
  // Should: only CRoute shows under DRoute, then DRoute alone; back goes to HomeRoute.
  testWidgets('pushAndPopUntil never shows the pages it removes', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('BRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('CRoute')));
    await tester.pumpAndSettle();

    unawaited(
      router.pushAndPopUntil(
        const PageRouteInfo('DRoute'),
        predicate: (route) => route.settings.name == 'HomeRoute',
      ),
    );
    final frames = <List<String>>[];
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      frames.add(shown());
    }
    expect(
      frames.where((frame) => frame.contains('HomeRoute') || frame.contains('BRoute')),
      isEmpty,
      reason: 'frames: $frames',
    );
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'DRoute']);

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'HomeRoute');
  });
}

PageInfo _page(String name) => PageInfo(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);
