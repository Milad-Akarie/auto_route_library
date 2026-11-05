import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// pushAndPopUntil removes the routes below the new page only once the new
// page's guards let it through. These tests pin what happens while a slow
// guard decides, the case flutter/flutter#193950 raises for go_router: a pop
// loop that something async interrupts.
// Steps: open Home, A and B, then call pushAndPopUntil(C, predicate:
// isHome), where C's guard decides only when the test completes its future.
void main() {
  // Made in each test, so it completes on the test's fake clock.
  late Completer<bool> decision;
  late RootStackRouter router;
  late List<String> observed;

  setUp(() {
    observed = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('A')),
        AutoRoute(page: _page('B')),
        AutoRoute(
          page: _page('C'),
          guards: [
            AutoRouteGuardCallback((resolver, _) async {
              if (await decision.future) {
                resolver.next();
              } else {
                resolver.reject();
              }
            }),
          ],
        ),
      ],
    );
  });

  bool isHome(Route<Object?> route) => route.settings.name == 'Home';

  List<String> names() => router.stack.map((page) => page.routeData.name).toList();

  // The pages on screen, bottom to top.
  List<String> shown() => ['Home', 'A', 'B', 'C'].where((name) => find.text(name).evaluate().isNotEmpty).toList();

  // Opens Home, A and B, then calls pushAndPopUntil(C), keeps its future in
  // [pushedC] and waits while C's guard decides.
  late Future<Object?> pushedC;
  Future<void> pushCWhileGuardDecides(WidgetTester tester) async {
    decision = Completer<bool>();
    await pumpRouterApp(tester, router, observers: () => [_NamesObserver(observed)]);
    unawaited(router.push(const PageRouteInfo('A')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('B')));
    await tester.pumpAndSettle();
    observed.clear();

    pushedC = router.pushAndPopUntil(const PageRouteInfo('C'), predicate: isHome);
    await tester.pumpAndSettle();
  }

  testWidgets('While the guard decides, pushAndPopUntil removes and shows nothing', (tester) async {
    await pushCWhileGuardDecides(tester);

    expect(names(), ['Home', 'A', 'B']);
    expect(shown(), ['B']);
    expect(observed, isEmpty);
  });

  testWidgets('A guard that rejects leaves the stack as it was and completes the push with null', (tester) async {
    await pushCWhileGuardDecides(tester);
    Object? resultOfC = 'unset';
    unawaited(pushedC.then((result) => resultOfC = result));

    decision.complete(false);
    await tester.pumpAndSettle();
    expect(resultOfC, isNull);
    expect(names(), ['Home', 'A', 'B']);
    expectCurrentPage(router, 'B');
    expect(observed, isEmpty);
  });

  testWidgets('A guard that accepts leaves Home and C', (tester) async {
    await pushCWhileGuardDecides(tester);

    decision.complete(true);
    await tester.pumpAndSettle();
    expect(names(), ['Home', 'C']);
    expectCurrentPage(router, 'C');
    expect(observed, containsAll(['push C', 'remove A', 'remove B']));

    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'Home');
  });

  // The predicate runs once the guard accepts, on the stack as it is then,
  // so a page popped while the guard decided is not asked about.
  testWidgets('A page popped while the guard decides is gone, and the rest go once it accepts', (tester) async {
    await pushCWhileGuardDecides(tester);
    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expect(names(), ['Home', 'A']);
    observed.clear();

    decision.complete(true);
    await tester.pumpAndSettle();
    expect(names(), ['Home', 'C']);
    expectCurrentPage(router, 'C');
    expect(observed, containsAll(['push C', 'remove A']));
    expect(observed.where((event) => event.endsWith(' B')), isEmpty);
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);

class _NamesObserver extends NavigatorObserver {
  new(this.events);

  final List<String> events;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('push ${route.settings.name ?? 'null'}');

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('pop ${route.settings.name ?? 'null'}');

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('remove ${route.settings.name ?? 'null'}');
}
