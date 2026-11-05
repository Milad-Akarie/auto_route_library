import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1088
// Steps: push a native route with router.pushNativeRoute over the root
// page, then call navigate to the root page.
// Reported: nothing happens, and the native route stays.
// Should: the native route goes and the root page shows. popTop pops it too.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('RootRoute', builder: (_) => const Text('RootRoute')),
        ),
        AutoRoute(
          path: '/other',
          page: PageInfo('OtherRoute', builder: (_) => const Text('OtherRoute')),
        ),
      ],
    );
  });

  Future<void> pushNative(WidgetTester tester) async {
    unawaited(
      router.pushNativeRoute<void>(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Native')))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Native'), findsOneWidget);
  }

  testWidgets('navigate to the root page removes a pushed native route', (tester) async {
    await pumpRouterApp(tester, router);
    await pushNative(tester);
    unawaited(router.navigate(const PageRouteInfo('RootRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Native'), findsNothing);
    expectCurrentPage(router, 'RootRoute');
  });

  testWidgets('popTop pops a pushed native route', (tester) async {
    await pumpRouterApp(tester, router);
    await pushNative(tester);
    router.popTop();
    await tester.pumpAndSettle();
    expect(find.text('Native'), findsNothing);
    expectCurrentPage(router, 'RootRoute');
  });

  testWidgets('navigate to another page removes a pushed native route', (tester) async {
    await pumpRouterApp(tester, router);
    await pushNative(tester);
    unawaited(router.navigate(const PageRouteInfo('OtherRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Native'), findsNothing);
    expectCurrentPage(router, 'OtherRoute');
  });
}
