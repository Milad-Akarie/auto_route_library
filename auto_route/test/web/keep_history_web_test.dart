@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  // Apps pass either router.config() or only the delegate and parser, which
  // leaves Flutter's own route information provider in place.
  for (final withConfig in [true, false]) {
    group(withConfig ? 'With router.config()' : 'With the delegate and parser', () {
      late RootStackRouter router;
      setUp(() async {
        router = RootStackRouter.build(
          routes: [
            AutoRoute(page: FirstRoute.page, path: '/', keepHistory: false),
            AutoRoute(page: SecondRoute.page, path: '/second'),
            AutoRoute(page: ThirdRoute.page, path: '/third'),
          ],
        );
        await rewindBrowserHistory();
      });

      // https://github.com/Milad-Akarie/auto_route_library/issues/1678
      // FirstRoute has keepHistory: false. Push SecondRoute from it.
      // SecondRoute should take FirstRoute's browser entry, so the browser's back
      // button can't return to FirstRoute.
      testWidgets('Pushing from a page without history on web replaces its browser entry', (tester) async {
        await pumpApp(tester, router, withConfig: withConfig);
        await settleBrowser(tester);
        final start = browserSerialCount;

        unawaited(router.push(const SecondRoute()));
        await settleBrowser(tester);
        expect(router.stack.map((p) => p.name), [SecondRoute.name]);
        expect(browserPath, '/second');
        expect(browserSerialCount, start);

        unawaited(router.push(const ThirdRoute()));
        await settleBrowser(tester);
        expect(browserSerialCount, start + 1);

        await pressBrowserBack(tester);
        expectCurrentPage(router, SecondRoute.name);
        expect(browserSerialCount, start);
      });

      // https://github.com/Milad-Akarie/auto_route_library/issues/2068
      // FirstRoute, the initial page, has keepHistory: false and calls replaceAll
      // with SecondRoute, as a splash screen does.
      // SecondRoute should take FirstRoute's browser entry.
      testWidgets('replaceAll from a page without history on web replaces its browser entry', (tester) async {
        await pumpApp(tester, router, withConfig: withConfig);
        await settleBrowser(tester);
        final start = browserSerialCount;

        unawaited(router.replaceAll([const SecondRoute()]));
        await settleBrowser(tester);
        expectCurrentPage(router, SecondRoute.name);
        expect(browserPath, '/second');
        expect(browserSerialCount, start);
      });
    });
  }
}

Future<void> pumpApp(WidgetTester tester, RootStackRouter router, {required bool withConfig}) {
  if (withConfig) return pumpRouterConfigApp(tester, router.config());
  return pumpRouterApp(tester, router);
}
