import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/51672: a
// CupertinoNavigationBar on a fullscreenDialog route never flies to the next
// page's bar, so pushing a page over a full-screen dialog page swaps the bars
// without the iOS title and back label animation; native iOS animates the
// bars inside a modally presented navigation stack.
// Setup, without auto_route: a CupertinoPageRoute with fullscreenDialog true
// and a CupertinoNavigationBar, and one without.
// Today, on Flutter 3.47.9 with cupertino_ui 1.1.6: the bar wraps itself in
// its transition Hero only when its route is not a fullscreenDialog
// (cupertino_ui lib/src/nav_bar.dart:269-278, `_isTransitionable`, used at
// line 860), so the bar has no Hero on such a route.
// auto_route passes a route's fullscreenDialog to its Cupertino page route,
// so an auto_route app with a full-screen dialog page sees the same. If this
// test fails after a Flutter upgrade, the bar now flies from such routes:
// drop this canary.
void main() {
  Future<int> navBarHeroes(
    WidgetTester tester, {
    required bool isFullscreenDialog,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CupertinoApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );
    navigatorKey.currentState!.push(
      CupertinoPageRoute<void>(
        fullscreenDialog: isFullscreenDialog,
        builder: (_) => const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Dialog')),
          child: SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return find
        .descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.byType(Hero),
        )
        .evaluate()
        .length;
  }

  testWidgets(
    'the nav bar of a fullscreenDialog route has no transition Hero, until '
    'Flutter fixes flutter/flutter#51672',
    (tester) async {
      expect(await navBarHeroes(tester, isFullscreenDialog: true), 0);
    },
  );

  testWidgets('the control: the nav bar of a plain page route has its Hero', (
    tester,
  ) async {
    expect(await navBarHeroes(tester, isFullscreenDialog: false), 1);
  });
}
