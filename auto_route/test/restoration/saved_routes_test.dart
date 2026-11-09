import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.
  late RootStackRouter router;
  late List<Object?> platformStates;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: _page('HomeRoute'), initial: true),
        AutoRoute(path: '/books/:id', page: _page('BookRoute')),
        AutoRoute(
          path: '/shelf',
          page: const EmptyShellRoute('ShelfRoute'),
          children: [
            AutoRoute(path: '', page: _page('ShelfListRoute')),
            AutoRoute(path: 'item', page: _page('ShelfItemRoute')),
          ],
        ),
        AutoRoute(
          path: '/tabs',
          page: _tabsPage,
          children: [
            AutoRoute(
              path: 'feed',
              page: const EmptyShellRoute('FeedTabRoute'),
              children: [
                AutoRoute(path: '', page: _page('FeedRoute')),
                AutoRoute(path: 'post', page: _page('PostRoute')),
              ],
            ),
            AutoRoute(path: 'settings', page: _page('SettingsTabRoute')),
          ],
        ),
      ],
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    platformStates = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      // ignore: function-always-returns-null
      (call) async {
        if (call.method == 'routeInformationUpdated') {
          platformStates.add((call.arguments as Map)['state']);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );
    await pumpRouterConfigApp(tester, router.config());
  }

  // The saved pages, which the configuration keeps next to the launch link.
  List<Object?> savedRoutes() =>
      (router.delegate().currentConfiguration!.savedRoutes! as Map)['routes']
          as List<Object?>;

  // Groundwork for restoring every page of the app, for
  // https://github.com/Milad-Akarie/auto_route_library/issues/2040 and
  // https://github.com/Milad-Akarie/auto_route_library/issues/2041:
  // the router's configuration holds the pages of every stack, with their
  // path and query params, even when the url doesn't change.
  testWidgets('the configuration holds every page of the stacks', (
    tester,
  ) async {
    await pumpApp(tester);
    unawaited(router.pushPath('/books/7?edition=2'));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('ShelfRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('ShelfItemRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('ShelfItemRoute')));
    await tester.pumpAndSettle();
    expect(router.currentPath, '/shelf/item');

    expect(savedRoutes(), [
      {'name': 'HomeRoute'},
      {
        'name': 'BookRoute',
        'path': {'id': '7'},
        'query': {'edition': '2'},
      },
      {
        'name': 'ShelfRoute',
        'children': [
          {'name': 'ShelfListRoute'},
          {'name': 'ShelfItemRoute'},
          {'name': 'ShelfItemRoute'},
        ],
      },
    ]);
  }, skip: kIsWeb);

  testWidgets('a tabs router saves every tab, the active one last', (
    tester,
  ) async {
    await pumpApp(tester);
    unawaited(
      router.navigate(
        const NamedRoute('TabsRoute', children: [NamedRoute('FeedTabRoute')]),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('PostRoute')));
    await tester.pumpAndSettle();
    router.innerRouterOf<TabsRouter>('TabsRoute')!.setActiveIndex(1);
    await tester.pumpAndSettle();

    expect(savedRoutes(), [
      {'name': 'HomeRoute'},
      {
        'name': 'TabsRoute',
        'children': [
          {
            'name': 'FeedTabRoute',
            'children': [
              {'name': 'FeedRoute'},
              {'name': 'PostRoute'},
            ],
          },
          {'name': 'SettingsTabRoute'},
        ],
      },
    ]);
  }, skip: kIsWeb);

  testWidgets('the saved pages are not sent to the platform', (tester) async {
    await pumpApp(tester);
    unawaited(router.pushPath('/books/7'));
    await tester.pumpAndSettle();
    expect(platformStates, isNotEmpty);
    expect(platformStates, everyElement(isNull));
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

final _tabsPage = PageInfo(
  'TabsRoute',
  builder: (_) => AutoTabsRouter(
    routes: const [NamedRoute('FeedTabRoute'), NamedRoute('SettingsTabRoute')],
    builder: (_, child) => child,
  ),
);
