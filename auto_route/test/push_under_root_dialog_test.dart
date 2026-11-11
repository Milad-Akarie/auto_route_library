import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/782
// Documents intended behavior; there is no bug to fix here.
// Setup, as in the reporter's repo: 'HomeRoute' is a shell with the children
// 'NestedRoute' (a shell, initial, whose first child is 'FirstRoute') and
// 'SecondRoute', and 'SecondRoute' is declared inside 'NestedRoute' too.
// Steps: on FirstRoute open a dialog, then push SecondRoute.
// Reported: with the dialog on the root navigator, SecondRoute showed behind
// the dialog.
// Why it is intended, as the maintainer explained in the issue: push finds the
// deepest router that can handle the route, whatever opened it and whether or
// not a dialog is open, so a route two routers can handle goes to the nested
// one. And a page of a nested router can't show above a dialog of the root
// navigator: the dialog covers everything below it, nested navigators included.
// Ways to get the page on top, each tested below: open the dialog in the
// navigator the page goes to, name the parent with navigate, which also closes
// the dialog, or declare the route only at the root.
void main() {
  RootStackRouter buildRouter({List<AutoRoute> rootRoutes = const []}) =>
      .build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo('HomeRoute', builder: (_) => const AutoRouter()),
            children: [
              AutoRoute(
                path: 'nested',
                initial: true,
                page: PageInfo(
                  'NestedRoute',
                  builder: (_) => const AutoRouter(),
                ),
                children: [
                  AutoRoute(
                    path: 'first',
                    initial: true,
                    page: PageInfo(
                      'FirstRoute',
                      builder: (_) => const Text('First page'),
                    ),
                  ),
                  if (rootRoutes.isEmpty)
                    AutoRoute(path: 'second', page: _secondPage),
                ],
              ),
              if (rootRoutes.isEmpty)
                AutoRoute(path: 'second-home', page: _secondPage),
            ],
          ),
          ...rootRoutes,
        ],
      );

  StackRouter homeOf(RootStackRouter router) =>
      router.innerRouterOf('HomeRoute')!;

  StackRouter nestedOf(RootStackRouter router) =>
      homeOf(router).innerRouterOf('NestedRoute')!;

  Future<void> showTheDialog(
    WidgetTester tester, {
    required BuildContext context,
    required bool useRootNavigator,
  }) async {
    showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (_) => const Text('The dialog'),
    );
    await tester.pumpAndSettle();
    expect(find.text('The dialog'), findsOneWidget);
  }

  testWidgets('A dialog on the root navigator stays above a page pushed in a '
      'nested router', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    await showTheDialog(
      tester,
      context: router.navigatorKey.currentContext!,
      useRootNavigator: true,
    );

    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nestedOf(router).stack.lastOrNull?.name, 'SecondRoute');
    expect(find.text('The dialog'), findsOneWidget);
    expect(find.text('Second page'), findsOneWidget);
    expect(find.text('Second page').hitTestable(), findsNothing);
  });

  testWidgets('A dialog in the nested navigator goes under the pushed page', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    await showTheDialog(
      tester,
      context: nestedOf(router).navigatorKey.currentContext!,
      useRootNavigator: false,
    );

    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Second page').hitTestable(), findsOneWidget);
  });

  testWidgets('navigate with the parent route picks its router and closes the '
      'dialog', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    await showTheDialog(
      tester,
      context: router.navigatorKey.currentContext!,
      useRootNavigator: true,
    );

    unawaited(
      router.navigate(
        const NamedRoute('HomeRoute', children: [NamedRoute('SecondRoute')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(homeOf(router).stack.lastOrNull?.name, 'SecondRoute');
    expect(find.text('The dialog'), findsNothing);
    expect(find.text('Second page').hitTestable(), findsOneWidget);
  });

  testWidgets('A route declared only at the root goes above the dialog', (
    tester,
  ) async {
    final router = buildRouter(
      rootRoutes: [AutoRoute(path: '/second', page: _secondPage)],
    );
    await pumpRouterApp(tester, router);
    await showTheDialog(
      tester,
      context: router.navigatorKey.currentContext!,
      useRootNavigator: true,
    );

    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(router.stack.lastOrNull?.name, 'SecondRoute');
    expect(find.text('Second page').hitTestable(), findsOneWidget);
  });
}

final _secondPage = PageInfo(
  'SecondRoute',
  builder: (_) => const Scaffold(body: Text('Second page')),
);
