import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

void main() {
  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: page('SignUpRoute'), initial: true),
      AutoRoute(page: page('ExternalRoute')),
      AutoRoute(page: page('SettingsRoute')),
      AutoRoute(
        page: const EmptyShellRoute('ShelfRoute'),
        children: [
          AutoRoute(page: page('ShelfListRoute'), initial: true),
          AutoRoute(path: 'item/:id', page: itemPage),
        ],
      ),
    ],
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2040
  // From the initial sign-up page, replace(ExternalRoute()), then push
  // ExternalRoute twice, then let the platform end and restore the app.
  // All three ExternalRoute pages should come back, so back returns to the
  // second, then the first, then leaves the app; not to the sign-up page.
  testWidgets('a stack of the same page comes back after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    var router = RestorableRouterApp.router;
    router.replace(const NamedRoute('ExternalRoute'));
    await tester.pumpAndSettle();
    router.push(const NamedRoute('ExternalRoute'));
    await tester.pumpAndSettle();
    router.push(const NamedRoute('ExternalRoute'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(RestorableRouterApp.router, isNot(same(router)));
    router = RestorableRouterApp.router;
    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), ['ExternalRoute', 'ExternalRoute', 'ExternalRoute']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['ExternalRoute', 'ExternalRoute']);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['ExternalRoute']);
    expect(find.text('SignUpRoute'), findsNothing);
    expect(router.canPop(), isFalse);
  }, skip: kIsWeb);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2040
  // A comment adds that it happens with different pages too: every page of
  // the stack should come back.
  testWidgets('a stack of different pages comes back after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    var router = RestorableRouterApp.router;
    router.push(const NamedRoute('SettingsRoute'));
    await tester.pumpAndSettle();
    router.push(const NamedRoute('ExternalRoute'));
    await tester.pumpAndSettle();

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    router = RestorableRouterApp.router;
    expect(router.stack.map((page) => page.name), ['SignUpRoute', 'SettingsRoute', 'ExternalRoute']);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('SettingsRoute'), findsOneWidget);
  }, skip: kIsWeb);

  // The same in a nested router, with path params: every page of every
  // stack comes back.
  testWidgets('every page of the stacks comes back after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    var router = RestorableRouterApp.router;
    router.push(const NamedRoute('SettingsRoute'));
    await tester.pumpAndSettle();
    router.push(const NamedRoute('ShelfRoute'));
    await tester.pumpAndSettle();
    router.pushPath('item/7');
    await tester.pumpAndSettle();
    router.pushPath('item/8');
    await tester.pumpAndSettle();
    expect(find.text('Item 8'), findsOneWidget);
    expect(router.currentPath, '/shelf-route/item/8');

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    router = RestorableRouterApp.router;
    expect(router.currentPath, '/shelf-route/item/8');
    expect(find.text('Item 8'), findsOneWidget);
    expect(router.currentHierarchy(ignoreParams: true), const [
      HierarchySegment('SignUpRoute'),
      HierarchySegment('SettingsRoute'),
      HierarchySegment(
        'ShelfRoute',
        children: [HierarchySegment('ShelfListRoute'), HierarchySegment('ItemRoute'), HierarchySegment('ItemRoute')],
      ),
    ]);

    for (final expected in ['Item 7', 'ShelfListRoute', 'SettingsRoute', 'SignUpRoute']) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    }
  }, skip: kIsWeb);
  // https://github.com/Milad-Akarie/auto_route_library/issues/2253
  // With restorationScopeId on the app and a restorationId on each page,
  // go Home, Products, ProductDetails, then let the platform end and
  // restore the app. ProductDetails should show, and back should return to
  // Products, then Home, instead of closing the app. The routes keep the
  // paths the generator gives them, which don't nest, so the restored url
  // alone can't bring the pages before it back.
  testWidgets('back after restoration returns through the pages before it', (tester) async {
    RootStackRouter buildShopRouter() => .build(
      routes: [
        AutoRoute(page: page('HomeRoute'), restorationId: (match) => match.name, initial: true),
        AutoRoute(page: page('ProductsRoute'), restorationId: (match) => match.name),
        AutoRoute(page: page('ProductDetailsRoute'), restorationId: (match) => match.name),
      ],
    );
    await tester.pumpWidget(RestorableRouterApp(buildShopRouter));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(const NamedRoute('ProductsRoute'));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(const NamedRoute('ProductDetailsRoute'));
    await tester.pumpAndSettle();

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    final router = RestorableRouterApp.router;
    expect(find.text('ProductDetailsRoute'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'ProductsRoute', 'ProductDetailsRoute']);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('ProductsRoute'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(router.canPop(), isFalse);
  }, skip: kIsWeb);
}

final itemPage = PageInfo('ItemRoute', builder: (data) => Text('Item ${data.inheritedPathParams.getString('id')}'));
