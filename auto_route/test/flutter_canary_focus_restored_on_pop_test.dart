import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/48464.
// Setup: HomeRoute has a TextField; SecondRoute has none. Plain Flutter
// behaves the same.
// Steps: tap the field, hide the keyboard while the field keeps focus (as
// Android's back key does), push SecondRoute, then pop it.
// Today the pop gives the field its focus back, and the field asks for the
// keyboard again, so it opens over a page the user only came back to. Giving
// focus back on a pop is by design in Flutter; showing the keyboard and
// scrolling the field into view with it is the open part. auto_route keeps
// Flutter's focus handling; an app that wants no keyboard calls
// `FocusManager.instance.primaryFocus?.unfocus()` before it pushes.
// If this test fails after a Flutter upgrade, Flutter no longer opens the
// keyboard when it gives focus back on a pop: drop this canary.
void main() {
  testWidgets('popping back to a page whose field had focus opens the keyboard again', (tester) async {
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
          page: PageInfo('SecondRoute', builder: (_) => const Scaffold(body: Text('SecondRoute'))),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.tap(find.byKey(const Key('home')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.hide();
    expect(_focusedField(), const Key('home'));

    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();
    expect(_focusedField(), isNull);
    expect(tester.testTextInput.isVisible, isFalse);

    router.pop();
    await tester.pumpAndSettle();
    expect(_focusedField(), const Key('home'), reason: 'after router.pop()');
    expect(tester.testTextInput.isVisible, isTrue, reason: 'after router.pop()');
  });
}

Key? _focusedField() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key;
