import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/194364
  // In go_router, a page closed with Navigator.pop or system back came back
  // when refreshListenable fired before the next frame.
  // Steps: push the unguarded DetailsRoute; in one callback close it, with
  // Navigator.pop() or the AppBar back button, and fire reevaluateListenable.
  // Should: DetailsRoute stays closed; HomeRoute shows.
  final closes = <String, FutureOr<void> Function(WidgetTester tester)>{
    'Navigator.pop()': (tester) => Navigator.of(tester.element(find.text('DetailsRoute'))).pop(),
    // A tap runs the button's callback at once, without a frame.
    'the AppBar back button': (tester) => tester.tap(find.byType(BackButton)),
  };
  for (final MapEntry(key: name, value: close) in closes.entries) {
    testWidgets('A page closed with $name as reevaluateListenable fires stays closed (flutter/flutter#194364)', (
      tester,
    ) async {
      final user = ValueNotifier(0);
      addTearDown(user.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'DetailsRoute',
            path: '/details',
            builder: (_, _) => Scaffold(appBar: AppBar(), body: const Text('DetailsRoute')),
          ),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: user);
      unawaited(router.pushPath('/details'));
      await tester.pumpAndSettle();

      await close(tester);
      user.value++;
      await tester.pumpAndSettle();

      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(find.text('DetailsRoute'), findsNothing);
    });
  }
}
