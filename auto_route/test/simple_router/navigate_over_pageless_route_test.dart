import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#171962: a route pushed with Navigator.push over a page
// should go when the router goes to that page again.
// The reporter's steps: on Page1, the only page, push Page2 with
// Navigator.push(MaterialPageRoute(...)); then go to Page1 with the router.
// Page1 should show, and Page2 be gone. A comment's steps: Navigator.push
// Signup over Home, push Login and Password with the router, then go Home.
// Decided: a guard reevaluation keeps such routes, since a guard may be
// showing one, such as a login dialog.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Page1'), initial: true),
        AutoRoute(page: _page('Login')),
        AutoRoute(page: _page('Password')),
      ],
    );
  });

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  Future<void> pushPageless(WidgetTester tester, String name) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(builder: (_) => Scaffold(body: Text(name))),
        );
    await tester.pumpAndSettle();
    expect(find.text(name), findsOneWidget);
  }

  // Each way of going back to Page1.
  final goToPage1 = {
    'navigate': () => unawaited(router.navigate(const PageRouteInfo('Page1'))),
    'replaceAll': () =>
        unawaited(router.replaceAll(const [PageRouteInfo('Page1')])),
    'popUntilRoot': () => router.popUntilRoot(),
  };

  for (final MapEntry(key: name, value: go) in goToPage1.entries) {
    testWidgets(
      '$name to the page under a Navigator.push route removes that route',
      (tester) async {
        await pumpRouterApp(tester, router);
        await pushPageless(tester, 'Page2');

        go();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Page2'), findsNothing);
        expect(names(), ['Page1']);
        expectTopPage(router, 'Page1');
      },
    );

    testWidgets("$name from the comment's Password page shows Page1 alone", (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      await pushPageless(tester, 'Signup');
      unawaited(router.push(const PageRouteInfo('Login')));
      await tester.pumpAndSettle();
      unawaited(router.push(const PageRouteInfo('Password')));
      await tester.pumpAndSettle();

      go();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Signup'), findsNothing);
      expect(names(), ['Page1']);
      expectTopPage(router, 'Page1');
    });
  }

  testWidgets(
    'a guard reevaluation keeps a Navigator.push route over the page',
    (tester) async {
      final reevaluate = ChangeNotifier();
      addTearDown(reevaluate.dispose);
      router = RootStackRouter.build(
        guards: [AutoRouteGuardCallback((resolver, _) => resolver.next())],
        routes: [AutoRoute(page: _page('Page1'), initial: true)],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: reevaluate);
      await pushPageless(tester, 'Page2');

      reevaluate.notifyListeners();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Page2'), findsOneWidget);
      expect(names(), ['Page1']);
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
