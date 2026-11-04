import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1778
  // Reported: a tap returns to the home page when an ad is shown or when the
  // theme is changed in the settings page.
  // Setup, as reported: a '/dashboardView' initial page with an AutoTabsRouter
  // over the pages a to e, which live in a nested 'empty' router; '/f' and
  // '/g' are root pages. The app is built again with a new theme, for the ad
  // or the setting.
  // Should: the page on top stays, as long as the app keeps the same router
  // (the issue gives no app code; an app that creates its router inside
  // build() gets a new router, and so the initial page, on every rebuild).
  late RootStackRouter router;
  late RouterConfig<UrlState> config;
  setUp(() {
    router = RootStackRouter.build(
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
                AutoRoute(page: _page('C'), path: 'c'),
              ],
            ),
          ],
        ),
        AutoRoute(page: _page('F'), path: '/f'),
        AutoRoute(page: _page('G'), path: '/g'),
      ],
    );
    config = router.config();
  });

  Widget app(ThemeMode mode) {
    return MaterialApp.router(
      themeMode: mode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      routerConfig: config,
    );
  }

  testWidgets('Changing the theme keeps the page that is open on top of the tabs', (tester) async {
    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();
    router.pushPath('/f');
    await tester.pumpAndSettle();
    expect(find.text('F'), findsOneWidget);

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(router.topRoute.name, 'F');
    expect(router.currentPath, '/f');
    expect(find.text('F'), findsOneWidget);
  });

  testWidgets('Changing the theme keeps the tab that is open', (tester) async {
    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'A');
    router.navigatePath('/dashboardView/empty/b');
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'B');

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(router.topRoute.name, 'B');
    expect(find.text('B'), findsOneWidget);
  });
}

final _dashboardPage = PageInfo(
  'Dashboard',
  builder: (_) =>
      const Scaffold(body: AutoTabsRouter(routes: [PageRouteInfo('A'), PageRouteInfo('B'), PageRouteInfo('C')])),
);

PageInfo _page(String name) => PageInfo(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);
