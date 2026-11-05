import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigate() to a route fills its path param into its ancestor's path.
// https://github.com/Milad-Akarie/auto_route_library/issues/2066
// Headless test: auto_route/test/nested_router/ancestor_path_params_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _BookShellRoute.page,
          path: '/books/:id',
          children: [
            AutoRoute(
              page: _BookRoute.page,
              path: '',
              children: [
                AutoRoute(
                  page: _BookTabRoute.pageFor('BookOverviewRoute'),
                  path: 'overview',
                  initial: true,
                ),
                AutoRoute(
                  page: _BookTabRoute.pageFor('BookPricingRoute'),
                  path: 'pricing',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // Steps: under a shell at 'books/:id' sits BookRoute at '', whose page
  // reads @PathParam('id'). Call router.navigate(BookRoute(id: 1,
  // someQueryParam: 1234)).
  // Should: the book page reads id 1 over its overview tab, and the url, and
  // on web the address bar, is '/books/1/overview?someQueryParam=1234', not
  // '/books/:id/overview'.
  testWidgets(
    "navigate() to a route fills its path param into its ancestor's path",
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.navigate(_BookRoute(id: 1, someQueryParam: 1234)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Book 1, query 1234'), findsOneWidget);
      expect(find.text('BookOverviewRoute'), findsOneWidget);
      expect(router.urlState.url, '/books/1/overview?someQueryParam=1234');
      await expectBrowserUrl('/books/1/overview?someQueryParam=1234');
    },
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(pageName);

  static const String pageName = 'HomeRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const Text('Home'));
}

class _BookShellRoute extends PageRouteInfo<void> {
  const _BookShellRoute({List<PageRouteInfo>? children})
    : super(pageName, initialChildren: children);

  static const String pageName = 'BookShellRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _BookRoute extends PageRouteInfo<void> {
  _BookRoute({required int id, int? someQueryParam})
    : super(
        pageName,
        rawPathParams: {'id': id},
        rawQueryParams: {'someQueryParam': someQueryParam},
      );

  static const String pageName = 'BookRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Column(
      children: [
        Text(
          'Book ${data.inheritedPathParams.getInt('id')}, query ${data.queryParams.optInt('someQueryParam')}',
        ),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _BookTabRoute {
  static PageInfo pageFor(String name) =>
      .new(name, builder: (_) => Text(name));
}
