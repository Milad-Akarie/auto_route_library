import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _RedirectingRoute.pageFor('RandomRoute'),
          path: '/random-page',
          initial: true,
        ),
        AutoRoute(
          page: _RedirectingRoute.pageFor('FirstRoute'),
          path: '/first-page',
        ),
        AutoRoute(
          page: _RedirectingRoute.pageFor('SecondRoute'),
          path: '/second-page',
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1925
  // At '/random-page', replace the page with FirstRoute(redirectTo: currentUrl),
  // then with SecondRoute(redirectTo: currentUrl). currentUrl should keep the
  // '=' inside the query value encoded, so opening it again gives SecondRoute
  // the whole '/first-page?redirectTo=/random-page', not a url with two
  // query strings.
  testWidgets('currentUrl keeps a url passed in a query param intact', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    expect(router.currentUrl, '/random-page');

    unawaited(
      router.replace(
        _RedirectingRoute('FirstRoute', redirectTo: router.currentUrl),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/first-page?redirectTo=/random-page');

    unawaited(
      router.replace(
        _RedirectingRoute('SecondRoute', redirectTo: router.currentUrl),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.currentUrl,
      '/second-page?redirectTo=/first-page?redirectTo%3D/random-page',
    );
    expect(
      find.text('SecondRoute to /first-page?redirectTo=/random-page'),
      findsOneWidget,
    );

    final url = router.currentUrl;
    unawaited(router.navigatePath(url));
    await tester.pumpAndSettle();
    expect(router.current.queryParams.rawMap, {
      'redirectTo': '/first-page?redirectTo=/random-page',
    });
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1925#issuecomment-2059750718
  // Replace the page with FirstRoute(redirectTo: '?=:http://&'). currentUrl
  // should keep the '=' and '&' encoded, so the value reads back whole.
  testWidgets('currentUrl keeps "=" and "&" in a query param encoded', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(
      router.replace(
        _RedirectingRoute('FirstRoute', redirectTo: '?=:http://&'),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/first-page?redirectTo=?%3D:http://%26');

    final url = router.currentUrl;
    unawaited(router.navigatePath(url));
    await tester.pumpAndSettle();
    expect(router.current.queryParams.rawMap, {'redirectTo': '?=:http://&'});
  });

  // currentUrl still reads as text: letters outside ASCII and spaces show as
  // they are.
  testWidgets('currentUrl shows letters outside ASCII and spaces decoded', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(
      router.replace(
        _RedirectingRoute('FirstRoute', redirectTo: 'café au lait'),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/first-page?redirectTo=café+au+lait');
  });
}

class _RedirectingRoute extends PageRouteInfo<void> {
  new(super.name, {required String redirectTo})
    : super(rawQueryParams: {'redirectTo': redirectTo});

  static PageInfo pageFor(String name) => .new(
    name,
    builder: (data) =>
        Text('$name to ${data.queryParams.optString('redirectTo') ?? 'null'}'),
  );
}
