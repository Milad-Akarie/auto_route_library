import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'no_op.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/178570,
// behind https://github.com/Milad-Akarie/auto_route_library/issues/2289 and
// https://github.com/Milad-Akarie/auto_route_library/issues/2290, and the
// reason auto_route needs no pop flicker workaround.
// Setup, as in the Flutter report, without auto_route: a Navigator built
// from a pages list that its parent keeps, removing a page in
// onDidRemovePage.
// Steps: push a second page, pop it, and rebuild the parent before the pop
// animation ends.
// On Flutter 3.38 to 3.41, Navigator called onDidRemovePage only when the
// popped route was disposed, after its animation. A parent rebuild in
// between handed the Navigator the popped page again, and it was pushed
// back: the flicker. auto_route worked around it by removing the page from
// its stack as soon as the pop was invoked, in AutoRoutePage.onPopInvoked
// (lib/src/router/auto_route_page.dart). Flutter fixed it in 3.44.0
// (flutter/flutter#182315): onDidRemovePage now runs during the pop
// itself, so the workaround is gone and AutoRouteNavigator's onDidRemovePage removes
// the page. This test pins that fix. If it fails after a Flutter upgrade, the
// bug is back: restore the workaround, calling `router.onPopPage(this)` from
// onPopInvoked when the router is a StackRouter.
void main() {
  testWidgets('popping a page calls onDidRemovePage before the pop animation ends, so a parent '
      'rebuild does not push the page again', (tester) async {
    final pushed = <String?>[];
    final removed = <String?>[];
    final pages = <Page<void>>[const MaterialPage(name: 'first', child: Text('first'))];
    late StateSetter setParentState;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setParentState = setState;
            return Navigator(
              observers: [_PushObserver(pushed)],
              pages: List.of(pages),
              onDidRemovePage: (page) => setState(() {
                removed.add(page.name);
                pages.remove(page);
              }),
            );
          },
        ),
      ),
    );
    setParentState(() => pages.add(const MaterialPage(name: 'second', child: Text('second'))));
    await tester.pumpAndSettle();
    expect(pushed, ['first', 'second']);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    expect(removed, ['second']);

    setParentState(noOp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('second'), findsOneWidget, reason: 'the pop animation is still running');
    await tester.pumpAndSettle();
    expect(pushed, ['first', 'second']);
    expect(find.text('second'), findsNothing);
  });
}

class _PushObserver extends NavigatorObserver {
  _PushObserver(this.pushed);

  final List<String?> pushed;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) => pushed.add(route.settings.name);
}
