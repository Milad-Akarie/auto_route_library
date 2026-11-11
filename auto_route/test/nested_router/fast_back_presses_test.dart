import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// flutter/flutter#118856: on Android, with a Router nested in a page of the
// root Router, pressing the hardware back button twice quickly gave another
// result than pressing it twice slowly.
// Steps: a host page whose nested router has [A, B, C]; press back
// twice, once with no frame between the presses (each press its own platform
// message, as Android sends them) and once letting each settle.
// Should: both pop B and C, leaving A in the nested router and the host page
// open.
void main() {
  Future<void> platformBack(WidgetTester tester) {
    final message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('popRoute'),
    );
    return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      null,
    );
  }

  final presses = <String, Future<void> Function(WidgetTester)>{
    'quickly': (tester) async {
      await tester.runAsync(() async {
        unawaited(platformBack(tester));
        await Future<void>.delayed(.zero);
        unawaited(platformBack(tester));
        await Future<void>.delayed(.zero);
      });
      await tester.pumpAndSettle();
    },
    'slowly': (tester) async {
      await systemBack(tester);
      await systemBack(tester);
    },
  };

  for (final MapEntry(key: pace, value: pressTwice) in presses.entries) {
    testWidgets('two back presses made $pace pop two nested pages', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Text('HomeRoute'),
            ),
          ),
          AutoRoute(
            path: '/host',
            page: PageInfo(
              'HostRoute',
              builder: (_) => const Scaffold(body: AutoRouter()),
            ),
            children: [
              for (final name in ['A', 'B', 'C'])
                AutoRoute(
                  path: name == 'A' ? '' : name.toLowerCase(),
                  page: PageInfo(name, builder: (_) => Text(name)),
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.pushPath('/host'));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
      unawaited(nested.pushPath('b'));
      await tester.pumpAndSettle();
      unawaited(nested.pushPath('c'));
      await tester.pumpAndSettle();

      await pressTwice(tester);

      expect(nested.stack.map((page) => page.name), ['A']);
      expect(router.stack.map((page) => page.name), ['HomeRoute', 'HostRoute']);
      expect(find.text('A'), findsOneWidget);
    });
  }
}
