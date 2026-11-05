import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/restorable_app.dart';

// A link that starts an app the platform ended in the background opens over
// the restored pages.
// flutter/flutter#161858
// Headless test: auto_route/test/restoration/restore_with_link_test.dart
//
// WidgetTester.restartAndRestore starts the app again from the data Flutter
// saved for restoration; the platform's initial route is set to the link, as
// Android sets it when a link starts the ended app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: namedPage('HomeRoute'), initial: true),
      AutoRoute(path: '/settings', page: namedPage('SettingsRoute')),
      AutoRoute(path: '/offer', page: namedPage('OfferRoute')),
    ],
  );

  // Steps: push SettingsRoute, then restore the app started at the link
  // /offer.
  // Should: OfferRoute shows, opened over the restored pages.
  testWidgets(
    'A link that starts a restored app opens its page (flutter/flutter#161858)',
    (tester) async {
      await pumpRestorableApp(tester, buildRouter);
      unawaited(
        RestorableRouterApp.router.push(const NamedRoute('SettingsRoute')),
      );
      await tester.pumpAndSettle();

      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      dispatcher.defaultRouteNameTestValue = '/offer';
      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      final router = RestorableRouterApp.router;
      expect(tester.takeException(), isNull);
      expect(router.topRoute.name, 'OfferRoute');
      expect(find.text('OfferRoute'), findsOneWidget);
      expect(router.currentUrl, '/offer');
    },
    skip: kIsWeb,
  );
}
