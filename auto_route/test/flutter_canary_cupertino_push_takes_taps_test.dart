import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Canary for Flutter proposal https://github.com/flutter/flutter/issues/54090:
// a Cupertino page takes taps while it is still sliding in (iOS before 26
// ignored touches during a push; the last comment says iOS 26 no longer
// does).
// Setup, without auto_route: a CupertinoApp; a second CupertinoPageRoute
// with a button.
// Steps: push the second page and tap its button 100 ms into the 500 ms
// slide.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the tap lands. A route
// ignores pointers only while it is popping or a user's back gesture is in
// progress (flutter/lib/src/widgets/routes.dart:1154-1157 and 1215-1222,
// `_ModalScopeState`); Flutter's fix (flutter/flutter#104520) was reverted.
// auto_route's RouteType.cupertino pages behave the same. If this test fails
// after a Flutter upgrade, Flutter now blocks taps during the transition:
// drop this canary.
void main() {
  testWidgets(
    'a button on a Cupertino page takes a tap during its slide in, until '
    'Flutter decides flutter/flutter#54090',
    (tester) async {
      final taps = ValueNotifier(0);
      addTearDown(taps.dispose);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        CupertinoApp(navigatorKey: navigatorKey, home: const SizedBox()),
      );
      navigatorKey.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => CupertinoPageScaffold(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                onPressed: () => taps.value++,
                child: const Text('tap'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      expect(taps.value, 1);
    },
  );
}
