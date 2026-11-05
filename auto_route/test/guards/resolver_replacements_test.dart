import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// NavigationResolver.reject() stops a push, reject(goBack: true) stops it and
// goes back, and next(), reject() and overrideNext(reevaluateNext: false)
// decide what a reevaluation leaves. Each call must leave the stack it
// documents, on a push and when reevaluateGuards runs the guard again.
// Steps: on HomeRoute, push GuardedRoute, then AboveRoute; the guard lets
// them through. Then reevaluateGuards, where the guard resolves with the call
// under test.
void main() {
  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  Future<List<String>> stackAfterReevaluation(
    WidgetTester tester,
    void Function(NavigationResolver resolver) onReevaluate,
  ) async {
    var reevaluating = false;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => page('HomeRoute'),
        ),
        NamedRouteDef(
          name: 'GuardedRoute',
          path: '/guarded',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (reevaluating) {
                onReevaluate(resolver);
              } else {
                resolver.next();
              }
            }),
          ],
          builder: (_, _) => page('GuardedRoute'),
        ),
        NamedRouteDef(
          name: 'AboveRoute',
          path: '/above',
          builder: (_, _) => page('AboveRoute'),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('GuardedRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('AboveRoute')));
    await tester.pumpAndSettle();
    reevaluating = true;
    unawaited(router.reevaluateGuards());
    await tester.pumpAndSettle();
    final names = router.stack.map((page) => page.routeData.name).toList();
    await tester.pumpWidget(const SizedBox());
    return names;
  }

  final expectedStacks = {
    'next()': (
      (NavigationResolver r) => r.next(),
      ['HomeRoute', 'GuardedRoute', 'AboveRoute'],
    ),
    'reject()': ((NavigationResolver r) => r.reject(), ['HomeRoute']),
    'overrideNext(reevaluateNext: false)': (
      (NavigationResolver r) => r.overrideNext(reevaluateNext: false),
      ['HomeRoute', 'GuardedRoute'],
    ),
    'reject(reevaluateNext: false)': (
      (NavigationResolver r) => r.reject(reevaluateNext: false),
      ['HomeRoute'],
    ),
  };

  for (final MapEntry(key: name, value: (call, expected))
      in expectedStacks.entries) {
    testWidgets('$name leaves the stack it documents', (tester) async {
      expect(await stackAfterReevaluation(tester, call), expected);
    });
  }

  testWidgets(
    'next() keeps the pages above, overrideNext(reevaluateNext: false) does '
    'not',
    (tester) async {
      expect(await stackAfterReevaluation(tester, (r) => r.next()), [
        'HomeRoute',
        'GuardedRoute',
        'AboveRoute',
      ]);
      expect(
        await stackAfterReevaluation(
          tester,
          (r) => r.overrideNext(reevaluateNext: false),
        ),
        ['HomeRoute', 'GuardedRoute'],
      );
      expect(await stackAfterReevaluation(tester, (r) => r.reject()), [
        'HomeRoute',
      ]);
    },
  );

  testWidgets('reject(goBack: true) stops the push and goes back, '
      'nextOrBack() lets it through', (tester) async {
    Future<List<String>> stackAfterPush(
      void Function(NavigationResolver resolver) decide,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => page('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'ListRoute',
            path: '/list',
            builder: (_, _) => page('ListRoute'),
          ),
          NamedRouteDef(
            name: 'GuardedRoute',
            path: '/guarded',
            guards: [AutoRouteGuard.simple((resolver, _) => decide(resolver))],
            builder: (_, _) => page('GuardedRoute'),
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('ListRoute')));
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('GuardedRoute')));
      await tester.pumpAndSettle();
      final names = router.stack.map((page) => page.routeData.name).toList();
      await tester.pumpWidget(const SizedBox());
      return names;
    }

    final expected = await stackAfterPush((r) => r.reject(goBack: true));
    expect(expected, ['HomeRoute']);
    expect(await stackAfterPush((r) => r.nextOrBack()), [
      'HomeRoute',
      'ListRoute',
      'GuardedRoute',
    ]);
    // On web, back() asks the browser to go back, which the headless test
    // page never follows; test/web/history_before_app_web_test.dart covers
    // back() there.
  }, skip: kIsWeb);
}
