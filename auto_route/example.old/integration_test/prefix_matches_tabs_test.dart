import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// With includePrefixMatches, the browser's back and forward buttons switch tabs.
// https://github.com/Milad-Akarie/auto_route_library/issues/1669
// Headless test: auto_route/test/web/prefix_matches_tabs_web_test.dart
//
// Runs only on web, the one platform with browser buttons.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps, as in the reporter's app: navigate from '/' to the tabs page, tap
  // the second tab, press the browser's back button, then its forward button.
  // Should: each button shows the tab its url names.
  testWidgets('With includePrefixMatches, the browser back and forward buttons switch tabs', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(
          page: _TabsRoute.page,
          path: '/tabs',
          children: [
            AutoRoute(page: _Tab1Route.page, path: 'tab-1', initial: true),
            AutoRoute(page: _Tab2Route.page, path: 'tab-2'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        includePrefixMatches: true,
        deepLinkBuilder: (link) => link.initial ? DeepLink.defaultPath : link,
      ),
    );
    unawaited(router.navigate(const _TabsRoute()));
    await tester.pumpAndSettle();
    await expectBrowserUrl('/tabs/tab-1');
    await tester.tap(find.text('Show tab 2'));
    await tester.pumpAndSettle();
    await expectBrowserUrl('/tabs/tab-2');

    pressBrowserBack();
    await expectBrowserUrl('/tabs/tab-1');
    await tester.pumpAndSettle();
    expect(find.text('Tab 1'), findsOneWidget);
    expect(router.stack.map((p) => p.name), [_HomeRoute.name, _TabsRoute.name]);

    pressBrowserForward();
    await expectBrowserUrl('/tabs/tab-2');
    await tester.pumpAndSettle();
    expect(find.text('Tab 2'), findsOneWidget);
  }, skip: !kIsWeb);
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _TabsRoute extends PageRouteInfo<void> {
  const _TabsRoute() : super(name);

  static const String name = 'TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: AutoTabsRouter.tabBar(
        routes: const [_Tab1Route(), _Tab2Route()],
        builder: (context, child, tabController) => Column(
          children: [
            TextButton(onPressed: () => tabController.animateTo(1), child: const Text('Show tab 2')),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _Tab1Route extends PageRouteInfo<void> {
  const _Tab1Route() : super(name);

  static const String name = 'Tab1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Tab 1'));
}

class _Tab2Route extends PageRouteInfo<void> {
  const _Tab2Route() : super(name);

  static const String name = 'Tab2Route';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Tab 2'));
}
