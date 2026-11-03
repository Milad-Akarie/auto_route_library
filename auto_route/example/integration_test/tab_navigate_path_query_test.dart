import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Navigating to a tab's path with a new query param shows the new query.
// https://github.com/Milad-Akarie/auto_route_library/issues/2235
// Headless test: auto_route/test/nested_tabs_router/tab_navigate_path_query_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: /dashboard holds AutoTabsRouter(routes: [SettingsTab()]), whose
  // page shows its query param. Tap 'navigatePath', 'navigateToPath', then
  // 'buildPageRoute'.
  // Should: the page shows each new query, and the url, in the browser's
  // address bar too on web, carries it.
  testWidgets('navigating to a tab path with a new query shows the new query', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/dashboard',
          initial: true,
          children: [AutoRoute(page: _SettingsTab.page, path: 'settings')],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('query: none'), findsOneWidget);

    for (final (button, query) in [
      ('navigatePath', 'path_1'),
      ('navigateToPath', 'path_2'),
      ('buildPageRoute', 'path_3'),
    ]) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.text('query: $query'), findsOneWidget, reason: button);
      expect(router.urlState.url, '/dashboard/settings?query=$query');
      await expectBrowserUrl('/dashboard/settings?query=$query');
    }
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const _DashboardRoute() : super(name);

  static const String name = '_DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => AutoTabsRouter(routes: [_SettingsTab()]));
}

class _SettingsTabArgs {
  const _SettingsTabArgs({this.query = 'none'});

  final String query;

  @override
  bool operator ==(Object other) => other is _SettingsTabArgs && other.query == query;

  @override
  int get hashCode => query.hashCode;
}

// What the generator makes for a page with `@queryParam String query = 'none'`.
class _SettingsTab extends PageRouteInfo<_SettingsTabArgs> {
  _SettingsTab({String query = 'none'})
    : super(
        name,
        args: _SettingsTabArgs(query: query),
        rawQueryParams: {'query': query},
      );

  static const String name = '_SettingsTab';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SettingsTabArgs>(
        orElse: () => _SettingsTabArgs(query: data.queryParams.getString('query', 'none')),
      );
      return _SettingsPage(query: args.query);
    },
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('query: $query'),
            TextButton(
              onPressed: () => context.router.navigate(_SettingsTab(query: 'working')),
              child: const Text('navigate'),
            ),
            TextButton(
              onPressed: () => context.router.navigatePath('/dashboard/settings?query=path_1'),
              child: const Text('navigatePath'),
            ),
            TextButton(
              onPressed: () => context.navigateToPath('/dashboard/settings?query=path_2'),
              child: const Text('navigateToPath'),
            ),
            TextButton(
              onPressed: () {
                final route = context.router.buildPageRoute(
                  '/dashboard/settings?query=path_3',
                  includePrefixMatches: false,
                );
                if (route != null) context.router.navigate(route);
              },
              child: const Text('buildPageRoute'),
            ),
          ],
        ),
      ),
    );
  }
}
