import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2066
  // At '/:businessCustomId' with business 'acme' open, call
  // context.navigateTo(FinishOrderingRoute()) from its page. The ordering
  // page should open under 'acme' and read its inherited 'businessCustomId',
  // not fail to parse it from null.
  testWidgets('navigateTo() a child keeps the path param its parent holds', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _BusinessRoute.page,
          path: '/:businessCustomId',
          children: [AutoRoute(page: _FinishOrderingRoute.page, path: 'new-order')],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/acme');
    unawaited(tester.element(find.text('Business acme')).navigateTo(const _FinishOrderingRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New order at acme'), findsOneWidget);
    expect(router.urlState.url, '/acme/new-order');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2066#issuecomment-3377859877
  // Under a shell at 'books/:id' sits BookRoute at '', whose page reads
  // @PathParam('id'), with tabs below it. Call
  // router.navigate(BookRoute(id: 1, someQueryParam: 1234)). The url should
  // be '/books/1/overview?someQueryParam=1234' and the page should read id 1,
  // not show '/books/:id/overview' and fail to parse 'id' from null.
  testWidgets("navigate() to a route fills its path param into its ancestor's path", (tester) async {
    final router = RootStackRouter.build(
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
                AutoRoute(page: _BookTabRoute.pageFor('BookOverviewRoute'), path: 'overview', initial: true),
                AutoRoute(page: _BookTabRoute.pageFor('BookPricingRoute'), path: 'pricing'),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigate(_BookRoute(id: 1, someQueryParam: 1234)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Book 1, query 1234'), findsOneWidget);
    expect(find.text('BookOverviewRoute'), findsOneWidget);
    expect(router.urlState.url, '/books/1/overview?someQueryParam=1234');
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(pageName);

  static const String pageName = 'HomeRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const Text('Home'));
}

class _BusinessRoute extends PageRouteInfo<void> {
  _BusinessRoute({required String businessCustomId, List<PageRouteInfo>? children})
    : super(pageName, rawPathParams: {'businessCustomId': businessCustomId}, initialChildren: children);

  static const String pageName = 'BusinessRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Column(
      children: [
        Text('Business ${data.inheritedPathParams.getString('businessCustomId')}'),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _FinishOrderingRoute extends PageRouteInfo<void> {
  const _FinishOrderingRoute() : super(pageName);

  static const String pageName = 'FinishOrderingRoute';
  static PageInfo page = PageInfo(
    pageName,
    // As generated for a constructor parameter marked @PathParam.inherit('businessCustomId').
    builder: (data) => Text('New order at ${data.inheritedPathParams.getString('businessCustomId')}'),
  );
}

class _BookShellRoute extends PageRouteInfo<void> {
  const _BookShellRoute({List<PageRouteInfo>? children}) : super(pageName, initialChildren: children);

  static const String pageName = 'BookShellRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _BookRoute extends PageRouteInfo<void> {
  // As generated for @PathParam('id') and @queryParam someQueryParam.
  _BookRoute({required int id, int? someQueryParam})
    : super(pageName, rawPathParams: {'id': id}, rawQueryParams: {'someQueryParam': someQueryParam});

  static const String pageName = 'BookRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Column(
      children: [
        Text(
          'Book ${data.inheritedPathParams.getInt('id')}, query ${data.queryParams.optInt('someQueryParam') ?? 'null'}',
        ),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _BookTabRoute {
  static PageInfo pageFor(String name) => .new(name, builder: (_) => Text(name));
}
