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
        AutoRoute(page: _CafeRoute.page, path: '/café'),
      ],
    );
    await rewindBrowserHistory();
  });

  // Found while fixing https://github.com/Milad-Akarie/auto_route_library/issues/2070
  // Push a page whose path is '/café', then press the browser's back button.
  // The url should follow each page; it stayed at '/', since comparing urls
  // threw on the 'é'.
  testWidgets('On web, a url with a letter outside ASCII follows the pages', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(const _CafeRoute()));
    await settleBrowser(tester);
    expect(tester.takeException(), isNull);
    expect(router.urlState.uri.toString(), '/caf%C3%A9');
    expect(browserPath, '/caf%C3%A9');

    await pressBrowserBack(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/');
  });
}

class _CafeRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'CafeRoute';
  static final PageInfo page = PageInfo(pageName, builder: (_) => const Text('Café'));
}
