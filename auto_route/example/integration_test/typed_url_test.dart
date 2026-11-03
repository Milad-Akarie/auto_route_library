import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A path typed into the address bar opens its page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2030 (reported for Wasm)
// Headless test: auto_route/test/web/typed_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('HomeRoute'))),
          path: '/',
        ),
        AutoRoute(
          page: PageInfo('TestRoute', builder: (data) => Text('Test ${data.params.getString('id')}')),
          path: '/test/:id',
        ),
      ],
    );
  });

  // Steps: open the app, type '/test/42' into the address bar.
  // Should: the page for '/test/:id' shows with id 42.
  testWidgets('A path typed into the address bar opens its page', (tester) async {
    await pumpRouterAppWithConfig(tester, router);

    typeBrowserUrl('/test/42');
    await expectBrowserUrl('/test/42');
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'TestRoute');
    expect(find.text('Test 42'), findsOneWidget);
  }, skip: !kIsWeb);

  // Steps: open the app on '/test/7', as entering that url does on web or a
  // deep link does elsewhere.
  // Should: the page for '/test/:id' shows with id 7.
  testWidgets('The app opens on the path it is given', (tester) async {
    await pumpRouterConfigApp(
      tester,
      router.config(deepLinkBuilder: (link) => link.initial ? DeepLink.path('/test/7') : link),
    );
    expect(router.topRoute.name, 'TestRoute');
    expect(find.text('Test 7'), findsOneWidget);
    await expectBrowserUrl('/test/7');
  });
}
