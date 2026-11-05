import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A tabs host opened without a tab in its url names its first tab in the url,
// and going back to that entry shows the first tab.
// Found while settling the web issues; no upstream report.
// Headless tests:
// auto_route/test/nested_tabs_router/tab_url_without_initial_test.dart and
// auto_route/test/web/tabs_url_without_initial_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: a tabs host at '/tabs' whose tabs have no '' path and none is
  // initial. Navigate to it from '/', tap the second tab, then go back: the
  // browser's back button on web, router.back() elsewhere.
  // Should: the url is '/tabs/tab-1' on the first tab, and going back shows it.
  for (final includePrefixMatches in [false, true]) {
    testWidgets('going back to a tabs host opened without a tab in its url '
        'shows its first tab, includePrefixMatches: $includePrefixMatches', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _HomeRoute.page, path: '/'),
          AutoRoute(
            page: _TabsRoute.page,
            path: '/tabs',
            children: [
              AutoRoute(page: _Tab1Route.page, path: 'tab-1'),
              AutoRoute(page: _Tab2Route.page, path: 'tab-2'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(
          includePrefixMatches: includePrefixMatches,
          deepLinkBuilder: (link) => link.initial ? DeepLink.defaultPath : link,
        ),
      );
      unawaited(router.navigate(const _TabsRoute()));
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);
      expect(router.currentUrl, '/tabs/tab-1');
      await expectBrowserUrl('/tabs/tab-1');
      await tester.tap(find.text('Show tab 2'));
      await tester.pumpAndSettle();
      expect(router.currentUrl, '/tabs/tab-2');
      await expectBrowserUrl('/tabs/tab-2');

      if (kIsWeb) {
        pressBrowserBack();
        await expectBrowserUrl('/tabs/tab-1');
      } else {
        router.back();
      }
      await tester.pumpAndSettle();
      expect(find.text('Tab 1'), findsOneWidget);
      expect(router.currentUrl, '/tabs/tab-1');
      expect(router.stack.map((p) => p.name), [
        _HomeRoute.name,
        _TabsRoute.name,
      ]);
    });
  }
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
}

class _TabsRoute extends PageRouteInfo<void> {
  const _TabsRoute() : super(name);

  static const String name = 'TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: AutoTabsRouter(
        routes: const [_Tab1Route(), _Tab2Route()],
        builder: (context, child) => Column(
          children: [
            TextButton(
              onPressed: () => context.tabsRouter.setActiveIndex(1),
              child: const Text('Show tab 2'),
            ),
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
