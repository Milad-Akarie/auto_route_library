import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#137033: in go_router, a navigation that landed while the
// user held the iOS back swipe left the screen unresponsive.
// Steps: on iOS, with the stack [Feed, Details], start a swipe from the left
// edge on Details and hold it. The app opens Test with replace (which takes
// Details' place, as go does), navigate or push (which put it over Details).
// Let go of the swipe short of or past the middle.
// Should: nothing throws, Test ends on top and takes taps.
void main() {
  final opens = <String, (Future<void> Function(StackRouter), List<String>)>{
    'navigate': (
      (router) => router.navigate(const NamedRoute('TestRoute')),
      ['FeedRoute', 'DetailsRoute', 'TestRoute'],
    ),
    'replace': (
      (router) => router.replace(const NamedRoute('TestRoute')),
      ['FeedRoute', 'TestRoute'],
    ),
    'push': (
      (router) => router.push(const NamedRoute('TestRoute')),
      ['FeedRoute', 'DetailsRoute', 'TestRoute'],
    ),
  };

  for (final MapEntry(key: name, value: (open, stack)) in opens.entries) {
    for (final pastMiddle in [false, true]) {
      final release = pastMiddle ? 'past' : 'short of';
      testWidgets('$name during a back swipe let go $release the middle', (
        tester,
      ) async {
        var taps = 0;
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'FeedRoute',
              path: '/',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('Feed'))),
            ),
            NamedRouteDef(
              name: 'DetailsRoute',
              path: '/details',
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('Details'))),
            ),
            NamedRouteDef(
              name: 'TestRoute',
              path: '/test',
              builder: (_, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Test'),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
        );
        await tester.pumpAndSettle();
        unawaited(router.push(const NamedRoute('DetailsRoute')));
        await tester.pumpAndSettle();

        final swipe = await tester.startGesture(const Offset(2, 300));
        await swipe.moveBy(const Offset(100, 0));
        await tester.pump();
        unawaited(open(router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await swipe.moveBy(Offset(pastMiddle ? 400 : 50, 0));
        await tester.pump();
        await swipe.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), stack);
        await tester.tap(find.text('Test'));
        expect(taps, 1);
      });
    }
  }
}
