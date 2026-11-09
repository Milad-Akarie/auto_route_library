import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/763
// Setup: a root page at '/' holds AutoRouter.declarative with the list at ''
// and the details at 'book/:id'. The routes callback reads
// handler.initialPendingRoutes, as the README says.
// Steps: open the app with a link to '/book/1'.
// Reported: after a refresh the app did not come back to book 1. The handler
// gave null, so the routes callback could not know the link's route.
// Should: the handler holds the routes of the link, once.
void main() {
  late List<List<String>?> reads;
  late RootStackRouter router;

  setUp(() {
    reads = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(
              routes: (handler) {
                final pending = handler.initialPendingRoutes;
                reads.add(pending?.map((route) => route.routeName).toList());
                return [
                  const PageRouteInfo('ListRoute'),
                  ...?pending?.where(
                    (route) => route.routeName == 'DetailsRoute',
                  ),
                ];
              },
            ),
          ),
          children: [
            AutoRoute(path: '', page: _page('ListRoute')),
            AutoRoute(path: 'book/:id', page: _page('DetailsRoute')),
          ],
        ),
      ],
    );
  });

  testWidgets('A declarative router opened by a link gets the routes of it', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, initialLink: '/book/1');
    expect(find.text('DetailsRoute 1'), findsOneWidget);
    // A DeepLink.path includes the page at '' as a prefix of the link.
    expect(reads.firstOrNull, ['ListRoute', 'DetailsRoute']);
  });

  testWidgets('A declarative router opened at its first page gets that page', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    expect(find.text('ListRoute'), findsOneWidget);
    expect(reads.firstOrNull, ['ListRoute']);
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (data) {
    final id = data.params.optString('id');
    return Text(id == null ? name : '$name $id');
  },
);
