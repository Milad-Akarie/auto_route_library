import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Shows [router] in a [MaterialApp] and waits for its first page. The router
/// is disposed when the test ends.
Future<void> pumpRouterApp(
  WidgetTester tester,
  RootStackRouter router, {
  String? initialLink,
  Listenable? reevaluationNotifier,
  NavigatorObserversBuilder observers =
      AutoRouterDelegate.defaultNavigatorObserversBuilder,
}) {
  addTearDown(router.dispose);
  return tester
      .pumpWidget(
        MaterialApp.router(
          routeInformationParser: router.defaultRouteParser(),
          routerDelegate: router.delegate(
            reevaluateListenable: reevaluationNotifier,
            deepLinkBuilder: (link) =>
                initialLink == null ? link : DeepLink.path(initialLink),
            navigatorObservers: observers,
          ),
        ),
      )
      .then((_) => tester.pumpAndSettle());
}

/// Shows [config] in a [MaterialApp] and waits for its first page. The
/// config's delegate, with its router, is disposed when the test ends.
Future<void> pumpRouterConfigApp(
  WidgetTester tester,
  RouterConfig<UrlState> config,
) {
  if (config.routerDelegate case final AutoRouterDelegate delegate) {
    addTearDown(delegate.dispose);
  }
  return tester
      .pumpWidget(MaterialApp.router(routerConfig: config))
      .then((_) => tester.pumpAndSettle());
}

void expectCurrentPage(StackRouter router, String name) {
  expect(router.current.name, name);
  expect(find.text(name), findsOneWidget);
}

void expectTopPage(StackRouter router, String name) {
  expect(router.topRoute.name, name);
  expect(find.text(name), findsOneWidget);
}
