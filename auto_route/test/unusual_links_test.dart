import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

RootStackRouter _router() => RootStackRouter.build(
  routes: [
    AutoRoute(page: _page('HomeRoute'), path: '/'),
    AutoRoute(page: _page('ReportRoute'), path: '/report'),
    AutoRoute(page: _page('StoreCartRoute'), path: '/store/cart'),
    AutoRoute(page: _page('FooRoute'), path: '/foo'),
    AutoRoute(page: _page('NotFoundRoute'), path: '*'),
  ],
);

// Starts the app at [link], as the platform hands it over.
Future<RootStackRouter> _openAt(WidgetTester tester, String link) async {
  final router = _router();
  final provider = PlatformRouteInformationProvider(initialRouteInformation: RouteInformation(uri: Uri.parse(link)));
  addTearDown(router.dispose);
  addTearDown(provider.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationProvider: provider,
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

// Links go-router-style apps crashed on: a custom scheme, a link without a
// path, a link without a '/', an empty path and a path of the wrong case. In
// auto_route a page is matched by the path alone, and a link no route
// matches ends on the '*' route.
void main() {
  // flutter/flutter#148389: Uri.origin throws for a scheme other than http(s).
  testWidgets('A link with a custom scheme opens the page of its path (flutter/flutter#148389)', (tester) async {
    await _openAt(tester, 'anyapp://redirect/report');
    expect(tester.takeException(), isNull);
    expect(find.text('ReportRoute'), findsOneWidget);
  });

  // flutter/flutter#174249: https://example.com, without a path, lost its
  // scheme and host and was read as a relative route.
  testWidgets('A link without a path opens the root page (flutter/flutter#174249)', (tester) async {
    await _openAt(tester, 'https://example.com');
    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsOneWidget);
  });

  // flutter/flutter#181629: geo:51.5,0.0 has no '/', so go_router found no match.
  testWidgets('A link without a "/" ends on the not-found page (flutter/flutter#181629)', (tester) async {
    await _openAt(tester, 'geo:51.5,0.0');
    expect(tester.takeException(), isNull);
    expect(find.text('NotFoundRoute'), findsOneWidget);
  });

  // flutter/flutter#184109: the browser's '#foo' reaches the router as 'foo',
  // which tripped an assertion in go_router's matcher.
  testWidgets('A path without a leading "/" does not assert (flutter/flutter#184109)', (tester) async {
    await _openAt(tester, 'foo');
    expect(tester.takeException(), isNull);
    expect(find.text('NotFoundRoute'), findsOneWidget);
  });

  // flutter/flutter#186992: an empty path raised a RangeError in the matcher.
  testWidgets('An empty path opens the root page (flutter/flutter#186992)', (tester) async {
    await _openAt(tester, '');
    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsOneWidget);
  });

  // flutter/flutter#162487: an upper-case last segment asserted in go_router.
  testWidgets('A path of the wrong case ends on the not-found page (flutter/flutter#162487)', (tester) async {
    await _openAt(tester, '/store/CART');
    expect(tester.takeException(), isNull);
    expect(find.text('NotFoundRoute'), findsOneWidget);
  });

  testWidgets('A path whose first segment has the wrong case ends on the not-found page (flutter/flutter#162487)', (
    tester,
  ) async {
    await _openAt(tester, '/STORE/cart');
    expect(tester.takeException(), isNull);
    expect(find.text('NotFoundRoute'), findsOneWidget);
  });
}
