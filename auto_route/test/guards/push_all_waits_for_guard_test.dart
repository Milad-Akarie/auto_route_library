import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Found while moving the package to very_good_analysis; no upstream issue.
// Steps: start on HomeRoute, then `await router.pushAll([ListRoute(),
// CheckoutRoute()])`, where CheckoutRoute's guard decides later, such as
// after a sign-in check.
// Happens: the future completes at once, before the guard has decided, so
// code after the await sees the old stack and can't tell whether the routes
// were added. popAndPushAll did the same.
// Should: it completes once the guard has decided, with the routes on the
// stack when it let them through and the stack as it was when it did not.
void main() {
  // Made in each test, so it completes on the test's fake clock.
  late Completer<bool> decision;

  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => page('HomeRoute')),
      NamedRouteDef(name: 'ListRoute', path: '/list', builder: (_, _) => page('ListRoute')),
      NamedRouteDef(
        name: 'CheckoutRoute',
        path: '/checkout',
        guards: [
          AutoRouteGuardCallback((resolver, _) async {
            resolver.next(await decision.future);
          }),
        ],
        builder: (_, _) => page('CheckoutRoute'),
      ),
    ],
  );

  List<String> namesOf(StackRouter router) => router.stack.map((page) => page.routeData.name).toList();

  testWidgets('pushAll completes once an async guard lets the routes through', (tester) async {
    decision = Completer<bool>();
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    var completed = false;
    unawaited(
      router.pushAll(const [NamedRoute('ListRoute'), NamedRoute('CheckoutRoute')]).then((_) => completed = true),
    );
    await tester.pumpAndSettle();
    expect(completed, isFalse);

    decision.complete(true);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(namesOf(router), ['HomeRoute', 'ListRoute', 'CheckoutRoute']);
  });

  testWidgets('pushAll completes once an async guard rejects the routes', (tester) async {
    decision = Completer<bool>();
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    var completed = false;
    unawaited(
      router.pushAll(const [NamedRoute('ListRoute'), NamedRoute('CheckoutRoute')]).then((_) => completed = true),
    );
    await tester.pumpAndSettle();
    expect(completed, isFalse);

    decision.complete(false);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(namesOf(router).last, isNot('CheckoutRoute'));
  });

  testWidgets('popAndPushAll completes once an async guard has decided', (tester) async {
    decision = Completer<bool>();
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('ListRoute')));
    await tester.pumpAndSettle();
    var completed = false;
    unawaited(router.popAndPushAll(const [NamedRoute('CheckoutRoute')]).then((_) => completed = true));
    await tester.pumpAndSettle();
    expect(completed, isFalse);

    decision.complete(true);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(namesOf(router), ['HomeRoute', 'CheckoutRoute']);
  });
}
