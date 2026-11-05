import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2115
  // Asked: UI testing tools such as Appium and Maestro find a screen by its
  // semantics identifier, and an auto_route page has none.
  // Steps: push a page of every route type, then look for it in the semantics
  // tree by its route name.
  // Should: each page's semantics carry `identifier: routeData.name`, so
  // `find.bySemanticsIdentifier` finds the page shown.
  final routes = [
    AutoRoute(path: '/', page: _page('HomeRoute')),
    MaterialRoute(path: '/material', page: _page('MaterialPageRoute')),
    CupertinoRoute(path: '/cupertino', page: _page('CupertinoPageRoute')),
    AdaptiveRoute(path: '/adaptive', page: _page('AdaptivePageRoute')),
    CustomRoute(path: '/custom', page: _page('CustomPageRoute'), transitionsBuilder: TransitionsBuilders.fadeIn),
    CustomRoute(
      path: '/built',
      page: _page('BuiltPageRoute'),
      customRouteBuilder: <T>(context, child, page) =>
          PageRouteBuilder<T>(settings: page, pageBuilder: (_, _, _) => child),
    ),
    CustomRoute(
      path: '/dialog',
      page: _page('DialogPageRoute'),
      customRouteBuilder: <T>(context, child, page) =>
          DialogRoute<T>(context: context, settings: page, builder: (_) => child),
    ),
  ];

  for (final name in [
    'HomeRoute',
    'MaterialPageRoute',
    'CupertinoPageRoute',
    'AdaptivePageRoute',
    'CustomPageRoute',
    'BuiltPageRoute',
    'DialogPageRoute',
  ]) {
    testWidgets('$name is found by its route name in semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final router = RootStackRouter.build(routes: routes);
      await pumpRouterApp(tester, router);
      if (name != 'HomeRoute') {
        unawaited(router.push(NamedRoute(name)));
        await tester.pumpAndSettle();
      }

      final page = find.bySemanticsIdentifier(name);
      expect(page, findsOneWidget);
      // The identifier is on the page itself, so the page's text is below it.
      expect(find.descendant(of: page, matching: find.text(name)), findsOneWidget);
      // UI testing tools read the semantics tree, not the widgets.
      expect(find.semantics.byPredicate((node) => node.identifier == name), findsOne);
      handle.dispose();
    }, variant: const TargetPlatformVariant({.android, .iOS}));
  }

  testWidgets('A page in a nested router and its host are both found', (tester) async {
    final handle = tester.ensureSemantics();
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HostRoute',
          path: '/',
          builder: (_, _) => const AutoRouter(),
          children: [NamedRouteDef(name: 'ChildRoute', path: '', builder: (_, _) => const Text('ChildRoute'))],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(find.bySemanticsIdentifier('HostRoute'), findsOneWidget);
    expect(
      find.descendant(of: find.bySemanticsIdentifier('HostRoute'), matching: find.bySemanticsIdentifier('ChildRoute')),
      findsOneWidget,
    );
    expect(find.semantics.byPredicate((node) => node.identifier == 'ChildRoute'), findsOne);
    handle.dispose();
  });
}
