import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../universal_link_test.dart' show sendPlatformLink;
import 'restoration_test_utils.dart';

// flutter/flutter#161858: a link that reached an app the platform had ended
// in the background was ignored: the app came back with its restored pages.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: page('HomeRoute'), path: '/', initial: true),
      AutoRoute(page: page('SettingsRoute'), path: '/settings'),
      AutoRoute(page: page('OfferRoute'), path: '/offer'),
    ],
  );

  // Starts the app at [launchLink], as the platform does, until the test ends.
  void launchAt(WidgetTester tester, String launchLink) {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    dispatcher.defaultRouteNameTestValue = launchLink;
  }

  Future<RootStackRouter> openSettingsThenRestore(
    WidgetTester tester, {
    required String restartedAt,
  }) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(
      RestorableRouterApp.router.push(const NamedRoute('SettingsRoute')),
    );
    await tester.pumpAndSettle();

    launchAt(tester, restartedAt);
    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return RestorableRouterApp.router;
  }

  // Open the app, push SettingsRoute, then let the platform end it and start
  // it again with the link /offer: the link opens over the restored pages as
  // it does in the running app, which navigates to HomeRoute, then OfferRoute.
  testWidgets('A link that starts a restored app opens as in the running app', (
    tester,
  ) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(
      RestorableRouterApp.router.push(const NamedRoute('SettingsRoute')),
    );
    await tester.pumpAndSettle();
    await sendPlatformLink(tester, '/offer');
    final running = RestorableRouterApp.router.stack
        .map((p) => p.name)
        .toList();
    await tester.pumpWidget(const SizedBox());

    final router = await openSettingsThenRestore(tester, restartedAt: '/offer');
    expect(router.stack.map((p) => p.name), running);
    expect(router.topRoute.name, 'OfferRoute');
    expect(router.currentUrl, '/offer');
  }, skip: kIsWeb);

  // The same, started again without a link: the restored pages only.
  testWidgets(
    'A restored app started without a link shows the restored pages',
    (tester) async {
      final router = await openSettingsThenRestore(tester, restartedAt: '/');
      expect(router.stack.map((p) => p.name), ['HomeRoute', 'SettingsRoute']);
      expect(router.currentUrl, '/settings');
    },
    skip: kIsWeb,
  );

  // Open the app at the link /offer, push SettingsRoute, then let the platform
  // end it and start it again with /offer, as Android does from the recent
  // apps: the link was already opened, so the restored pages stay as they were.
  testWidgets(
    'A restored app started again with the link that first opened it shows the restored pages',
    (tester) async {
      launchAt(tester, '/offer');
      await tester.pumpWidget(RestorableRouterApp(buildRouter));
      await tester.pumpAndSettle();
      expect(RestorableRouterApp.router.topRoute.name, 'OfferRoute');
      unawaited(
        RestorableRouterApp.router.push(const NamedRoute('SettingsRoute')),
      );
      await tester.pumpAndSettle();

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      final router = RestorableRouterApp.router;
      expect(router.stack.map((p) => p.name), [
        'HomeRoute',
        'OfferRoute',
        'SettingsRoute',
      ]);
      expect(router.currentUrl, '/settings');
    },
    skip: kIsWeb,
  );
}
