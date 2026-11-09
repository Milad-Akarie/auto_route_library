import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// onNavigate of a declarative router runs once per navigation.
// https://github.com/Milad-Akarie/auto_route_library/issues/763
// Headless test: auto_route/test/web/declarative_router_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('declarative onNavigate', () {
    // Steps: a page at '/' builds AutoRouter.declarative and counts each call
    // of onNavigate. Open book 1, then send the link '/' from the platform,
    // which reaches the declarative router through its parent, as a browser's
    // back does.
    // Should: onNavigate runs once for that navigation.
    testWidgets('a navigation through the parent reports once', (tester) async {
      final calls = ValueNotifier(0);
      addTearDown(calls.dispose);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo(
              'HostRoute',
              builder: (_) => AutoRouter.declarative(
                onNavigate: (_) => calls.value++,
                routes: (_) => const [PageRouteInfo('ListRoute')],
              ),
            ),
            children: [
              AutoRoute(path: '', page: _page('ListRoute')),
              AutoRoute(path: 'book/:id', page: _page('DetailsRoute')),
            ],
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.navigatePath('/book/1'));
      await tester.pumpAndSettle();
      final before = calls.value;

      const codec = JSONMethodCodec();
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        codec.encodeMethodCall(
          const MethodCall('pushRouteInformation', {
            'location': '/',
            'state': null,
          }),
        ),
        null,
      );
      await tester.pumpAndSettle();
      expect(calls.value - before, 1);
    });
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
