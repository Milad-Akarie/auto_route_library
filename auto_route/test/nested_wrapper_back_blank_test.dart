import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1938
// (still happening after the fix for #1931, auto_route 8.1.1).
// Setup, from #1931: Home (initial), then '/detail', a wrapper page holding
// an AutoRouter with Detail (initial, itself with FirstTab and SecondTab
// children) and InsideDetail.
// Steps: push the wrapper from Home, go back (system back and the router's
// own pop).
// Happened: the screen went blank, Home was not shown.
// Should: Home shows again and the root stack holds only Home.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), path: '/', initial: true),
        AutoRoute(
          page: PageInfo('DetailWrapper', builder: (_) => const AutoRouter()),
          path: '/detail',
          children: [
            AutoRoute(
              page: PageInfo('Detail', builder: (_) => const AutoRouter()),
              path: '',
              initial: true,
              children: [
                AutoRoute(page: _page('FirstTab'), path: 'first'),
                AutoRoute(page: _page('SecondTab'), path: 'second'),
              ],
            ),
            AutoRoute(page: _page('InsideDetail'), path: 'insideDetail'),
          ],
        ),
      ],
    );
  });

  final backs = <String, Future<void> Function(WidgetTester)>{
    'system back': systemBack,
    'router.maybePop': (tester) async {
      unawaited(router.maybePop());
      await tester.pumpAndSettle();
    },
    'router.pop': (tester) async {
      router.pop();
      await tester.pumpAndSettle();
    },
  };
  for (final MapEntry(key: name, value: back) in backs.entries) {
    testWidgets('$name from the wrapper shows Home', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('DetailWrapper')));
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'Detail');

      await back(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(router.stack.map((page) => page.routeData.name), ['Home']);
    });
  }

  testWidgets('system back from InsideDetail returns to Detail, then Home', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('DetailWrapper')));
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/detail/insideDetail'));
    await tester.pumpAndSettle();
    expect(find.text('InsideDetail'), findsOneWidget);

    await systemBack(tester);
    expect(router.topRoute.name, 'Detail');

    await systemBack(tester);
    expect(find.text('Home'), findsOneWidget);
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
