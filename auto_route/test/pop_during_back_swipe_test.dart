import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#86459 and flutter/flutter#83087: a pop that lands while
// the user holds the iOS back swipe. In #86459 a timer called Navigator.pop
// during the swipe; the next swipe threw a RangeError in
// didStartUserGesture and the app froze. In #83087, on Android with the
// Cupertino transition, one swipe sometimes popped two pages.
// Steps: on iOS, stack [P1, P2, P3]; start a swipe from the left edge on
// P3 and hold it; the app pops (maybePop, pop, or a system back); let go of
// the swipe short of or past the middle; then swipe back once more.
// Should: the held swipe and the pop together pop one page, nothing
// throws, and the next swipe pops P2.
void main() {
  final pops = <String, void Function(WidgetTester, StackRouter)>{
    'maybePop': (_, router) => unawaited(router.maybePop()),
    'pop': (_, router) => router.pop(),
    'system back': (tester, _) => unawaited(tester.binding.handlePopRoute()),
  };

  for (final MapEntry(key: name, value: pop) in pops.entries) {
    for (final pastMiddle in [false, true]) {
      testWidgets('$name during a held back swipe let go ${pastMiddle ? 'past' : 'short of'} the middle '
          'pops one page', (tester) async {
        final router = RootStackRouter.build(
          routes: [
            for (final page in ['P1', 'P2', 'P3'])
              AutoRoute(
                path: page == 'P1' ? '/' : '/${page.toLowerCase()}',
                page: PageInfo(page, builder: (_) => Scaffold(body: Text(page))),
              ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(theme: iosTheme, routerConfig: router.config()));
        await tester.pumpAndSettle();
        unawaited(router.pushPath('/p2'));
        await tester.pumpAndSettle();
        unawaited(router.pushPath('/p3'));
        await tester.pumpAndSettle();

        final swipe = await tester.startGesture(const Offset(2, 300));
        await swipe.moveBy(const Offset(100, 0));
        await tester.pump();
        pop(tester, router);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await swipe.moveBy(Offset(pastMiddle ? 400 : 50, 0));
        await tester.pump();
        await swipe.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), ['P1', 'P2']);
        expect(find.text('P2'), findsOneWidget);

        await swipeBack(tester);
        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), ['P1']);
        expect(find.text('P1'), findsOneWidget);
      });
    }
  }
}
