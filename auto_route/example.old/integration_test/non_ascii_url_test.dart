import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// On web, a url with a letter outside ASCII follows the pages.
// Found while fixing https://github.com/Milad-Akarie/auto_route_library/issues/2070
// Headless test: auto_route/test/web/non_ascii_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _CafeRoute.page, path: '/café'),
      ],
    );
  });

  // Steps: push a page whose path is '/café', then pop it.
  // Should: the url, and on web the address bar, is '/caf%C3%A9', then '/'.
  testWidgets('A url with a letter outside ASCII follows the pages', (
    tester,
  ) async {
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(const _CafeRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.urlState.uri.toString(), '/caf%C3%A9');
    await expectBrowserUrl('/caf%C3%A9');

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    await expectBrowserUrl('/');
  });
}

class _CafeRoute extends PageRouteInfo<void> {
  const _CafeRoute() : super(pageName);

  static const String pageName = 'CafeRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const Text('Café'));
}
