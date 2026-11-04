@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/'),
        AutoRoute(
          page: PageInfo('TestRoute', builder: (data) => Text('Test ${data.params.getString('id')}')),
          path: '/test/:id',
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2030
  // In a Wasm build, a path typed in the address bar was ignored; the app
  // stayed where it was. Run this file with `--wasm` too.
  // Steps: open the app, type '/test/42' into the address bar.
  // Should: the page for '/test/:id' shows with id 42.
  testWidgets('On web, a path typed into the address bar opens its page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);

    await browserMove(tester, () => window.location.hash = '/test/42');
    expect(router.topRoute.name, 'TestRoute');
    expect(find.text('Test 42'), findsOneWidget);
    expect(browserPath, '/test/42');
  });

  // Steps: open the app on '/test/7', as entering that url in a new tab does.
  // Should: the page for '/test/:id' shows with id 7.
  testWidgets('On web, the app opens on the path in the address bar', (tester) async {
    router.routeInfoProvider(initialRouteInformation: RouteInformation(uri: Uri.parse('/test/7')));
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);

    expect(router.topRoute.name, 'TestRoute');
    expect(find.text('Test 7'), findsOneWidget);
    expect(browserPath, '/test/7');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
