import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/95656.
// Setup, as in the Flutter report, on iOS: HomeRoute has a TextField;
// SecondRoute and NextRoute have none. Plain Flutter behaves the same.
// Steps: tap the field, push SecondRoute, push NextRoute, then swipe back
// from the left edge to SecondRoute.
// Today, once the swipe starts, the top route stops accepting focus, and
// Flutter hands focus to the field that had it last in the navigator, on
// HomeRoute, two pages down. The keyboard opens during the swipe and stays
// open over SecondRoute. auto_route keeps Flutter's back swipe and focus
// handling.
// If this test fails after a Flutter upgrade, the swipe no longer gives
// focus to a page that does not show: drop this canary.
void main() {
  testWidgets('swiping back gives focus to a field two pages down and opens the keyboard', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => const Scaffold(body: TextField(key: Key('home'))),
          ),
        ),
        AutoRoute(
          path: '/second',
          page: PageInfo(
            'SecondRoute',
            builder: (_) => const Scaffold(body: Center(child: Text('SecondRoute'))),
          ),
        ),
        AutoRoute(
          path: '/next',
          page: PageInfo(
            'NextRoute',
            builder: (_) => const Scaffold(body: Center(child: Text('NextRoute'))),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.tap(find.byKey(const Key('home')));
    await tester.pump();
    unawaited(router.pushPath('/second'));
    await tester.pumpAndSettle();
    unawaited(router.pushPath('/next'));
    await tester.pumpAndSettle();
    expect(_focusedField(), isNull);

    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(_focusedField(), const Key('home'));
    expect(tester.testTextInput.isVisible, isTrue);

    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'SecondRoute');
    expect(_focusedField(), const Key('home'));
    expect(tester.testTextInput.isVisible, isTrue);
  }, variant: TargetPlatformVariant.only(.iOS));
}

Key? _focusedField() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key;
