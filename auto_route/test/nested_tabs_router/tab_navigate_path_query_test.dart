import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2235
  // Steps: /dashboard holds AutoTabsRouter(routes: [SettingsTab()]), whose
  // page shows its query param 'query' (default 'none'). From the tab, call
  // context.router.navigatePath('/dashboard/settings?query=...'), then
  // context.navigateToPath(...), then navigate(buildPageRoute(...)).
  // Reported: the url changes but the page keeps showing the old query.
  // Should: the page shows each new query.
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
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('query: none'), findsOneWidget);

    await tester.tap(find.text('navigate'));
    await tester.pumpAndSettle();
    expect(find.text('query: working'), findsOneWidget);

    await tester.tap(find.text('navigatePath'));
    await tester.pumpAndSettle();
    expect(find.text('query: path_1'), findsOneWidget);
    expect(router.urlState.url, '/dashboard/settings?query=path_1');

    await tester.tap(find.text('navigateToPath'));
    await tester.pumpAndSettle();
    expect(find.text('query: path_2'), findsOneWidget);
    expect(router.urlState.url, '/dashboard/settings?query=path_2');

    await tester.tap(find.text('buildPageRoute'));
    await tester.pumpAndSettle();
    expect(find.text('query: path_3'), findsOneWidget);
    expect(router.urlState.url, '/dashboard/settings?query=path_3');
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => AutoTabsRouter(routes: [_SettingsTab()]));
}

@immutable
class _SettingsTabArgs {
  const new({this.query = 'none'});

  final String query;

  @override
  bool operator ==(Object other) => other is _SettingsTabArgs && other.query == query;

  @override
  int get hashCode => query.hashCode;
}

// What the generator makes for a page with `@queryParam String query = 'none'`.
class _SettingsTab extends PageRouteInfo<_SettingsTabArgs> {
  new({String query = 'none'})
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
  const new({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
              if (route != null) unawaited(context.router.navigate(route));
            },
            child: const Text('buildPageRoute'),
          ),
        ],
      ),
    );
  }
}
