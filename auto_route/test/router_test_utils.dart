import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpRouterApp(
  WidgetTester tester,
  RootStackRouter router, {
  String? initialLink,
  Listenable? reevaluationNotifier,
  NavigatorObserversBuilder observers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
}) {
  return tester
      .pumpWidget(
        MaterialApp.router(
          routeInformationParser: router.defaultRouteParser(),
          routerDelegate: router.delegate(
            reevaluateListenable: reevaluationNotifier,
            deepLinkBuilder: (link) => initialLink == null ? link : DeepLink.path(initialLink),
            navigatorObservers: observers,
          ),
        ),
      )
      .then((_) => tester.pumpAndSettle());
}

Future<void> pumpRouterConfigApp(
  WidgetTester tester,
  RouterConfig<UrlState> config, {
  NavigatorObserversBuilder observers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
}) {
  return tester.pumpWidget(MaterialApp.router(routerConfig: config)).then((_) => tester.pumpAndSettle());
}

void expectCurrentPage(StackRouter router, String name) {
  expect(router.current.name, name);
  expect(find.text(name), findsOneWidget);
}

void expectTopPage(StackRouter router, String name) {
  expect(router.topRoute.name, name);
  expect(find.text(name), findsOneWidget);
}
