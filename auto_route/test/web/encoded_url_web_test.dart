@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _SecondsRoute.page, path: '/seconds/:id'),
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );
    addTearDown(router.dispose);
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1812
  // Push a page whose path param and query param are '123#456#789', then
  // refresh the browser. The address bar should hold '#' encoded, so the
  // refreshed page reads the whole '123#456#789', not '123'.
  testWidgets('On web, a "#" in a path param survives a refresh', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(_SecondsRoute(id: '123#456#789', query: '123#456#789')));
    await settleBrowser(tester);
    expect(find.text('id 123#456#789, query 123#456#789'), findsOneWidget);
    expect(browserPath, '/seconds/123%23456%23789?query=123%23456%23789');

    // A refresh opens the app at the url in the address bar.
    final refreshed = await router.defaultRouteParser().parseRouteInformation(
      RouteInformation(uri: Uri.parse(browserPath)),
    );
    expect(refreshed.topMatch?.params.rawMap, {'id': '123#456#789'});
    expect(refreshed.topMatch?.queryParams.rawMap, {'query': '123#456#789'});
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1812
  // The same with the app built from routerDelegate and routeInformationParser,
  // which leaves reporting urls to Flutter's own route information provider.
  testWidgets('On web, a "#" in a path param survives a refresh with Flutter\'s route information provider', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    await settleBrowser(tester);
    unawaited(router.push(_SecondsRoute(id: '123#456#789', query: '123#456#789')));
    await settleBrowser(tester);
    expect(browserPath, '/seconds/123%23456%23789?query=123%23456%23789');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2070#issuecomment-3808830262
  // Push a page whose query param holds '&', '=', '/', '?' and '#', push another
  // page, then press the browser's back button. The address bar should keep the
  // query param encoded, so it still reads back whole.
  testWidgets('On web, a query param keeps its reserved characters encoded after the back button', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(_SecondsRoute(id: '1', query: 'a&b=c/d?e#f')));
    await settleBrowser(tester);
    const encoded = '/seconds/1?query=a%26b%3Dc%2Fd%3Fe%23f';
    expect(browserPath, encoded);
    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);

    await pressBrowserBack(tester);
    expect(find.text('id 1, query a&b=c/d?e#f'), findsOneWidget);
    expect(browserPath, encoded);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1812
  // With Flutter's own route information provider, open the app at a deep
  // link whose path param holds an encoded '#'. The browser should keep one
  // history entry for it, as for a link without one; with a second entry, the
  // first back would show the same page again.
  testWidgets("On web, a deep link to an encoded url adds no history entry with Flutter's route information provider", (
    tester,
  ) async {
    for (final (link, id) in [('/seconds/12', '12'), ('/seconds/1%232', '1#2')]) {
      await rewindBrowserHistory();
      openBrowserAt(tester, link);
      final linkedRouter = RootStackRouter.build(routes: router.routes);
      addTearDown(linkedRouter.dispose);
      await pumpAsRunApp(
        tester,
        MaterialApp.router(
          routeInformationParser: linkedRouter.defaultRouteParser(),
          routerDelegate: linkedRouter.delegate(),
        ),
      );
      expect(find.text('id $id, query null'), findsOneWidget);
      expect(browserPath, link);
      expect(browserSerialCount, 0, reason: link);
      expect(appWroteBrowserEntry, isTrue);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

class _SecondsRoute extends PageRouteInfo<void> {
  _SecondsRoute({required String id, String? query})
    : super(name, rawPathParams: {'id': id}, rawQueryParams: {'query': query});

  static const String name = 'SecondsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) =>
        Text('id ${data.inheritedPathParams.getString('id')}, query ${data.queryParams.optString('query')}'),
  );
}
