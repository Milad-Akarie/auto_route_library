import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// Changing the theme keeps the page that is open.
// https://github.com/Milad-Akarie/auto_route_library/issues/1778
// Headless test: auto_route/test/nested_tabs_router/theme_change_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open a dashboard with an AutoTabsRouter, push a root page on top of
  // it, then build the app again with the other theme, as an ad or the
  // settings page does.
  // Should: the pushed page is still on top.
  testWidgets(
    'Changing the theme keeps the page that is open on top of the tabs',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _dashboardPage,
            path: '/dashboardView',
            initial: true,
            children: [
              AutoRoute(
                page: const PageInfo.emptyShell('EmptyRouter'),
                path: 'empty',
                children: [
                  AutoRoute(page: _page('A'), path: 'a'),
                  AutoRoute(page: _page('B'), path: 'b'),
                ],
              ),
            ],
          ),
          AutoRoute(page: _page('F'), path: '/f'),
        ],
      );
      final config = router.config(
        deepLinkBuilder: (_) => const DeepLink.path('/dashboardView'),
      );
      Widget app(ThemeMode mode) => MaterialApp.router(
        themeMode: mode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        routerConfig: config,
      );
      await tester.pumpWidget(app(.light));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/f'));
      await tester.pumpAndSettle();
      expect(find.text('F'), findsOneWidget);

      await tester.pumpWidget(app(.dark));
      await tester.pumpAndSettle();

      expect(router.topRoute.name, 'F');
      expect(find.text('F'), findsOneWidget);
    },
  );
}

final _dashboardPage = PageInfo(
  'Dashboard',
  builder: (_) => const Scaffold(
    body: AutoTabsRouter(routes: [PageRouteInfo('A'), PageRouteInfo('B')]),
  ),
);

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);
