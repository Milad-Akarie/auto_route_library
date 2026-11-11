import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Canary for Flutter proposals https://github.com/flutter/flutter/issues/93958
// and https://github.com/flutter/flutter/issues/109535: when the pages given
// to a Navigator are reordered, the page that comes to the top shows at once,
// with no transition, and an app has no way to ask for one.
// Setup, without auto_route: a Navigator built from pages [A, B].
// Steps: rebuild it with [B, A].
// Today, on Flutter 3.47.9: A is on top in the next frame, its route's
// animation already complete and not running. Navigator._updatePages keeps
// the existing routes and only reorders them; a TransitionDelegate is asked
// about pages that enter or leave, never about pages that move
// (flutter/lib/src/widgets/navigator.dart, `NavigatorState._updatePages` and
// `TransitionDelegate.resolve`).
// auto_route keeps one route per page key, so reordering its stack (for
// example a declarative router's list) shows the page the same way. If this
// test fails after a Flutter upgrade, Flutter now animates a reorder: drop
// this canary.
void main() {
  testWidgets(
    'a page moved to the top of Navigator.pages shows without a transition, '
    'until Flutter takes up flutter/flutter#93958 and #109535',
    (tester) async {
      final routes = <String, ModalRoute<Object?>>{};
      Page<void> page(String name) => MaterialPage(
        key: ValueKey(name),
        child: Builder(
          builder: (context) {
            routes[name] = ModalRoute.of(context)!;
            return Text(name);
          },
        ),
      );
      final pages = ValueNotifier([page('A'), page('B')]);
      addTearDown(pages.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: pages,
            builder: (context, current, _) => Navigator(
              pages: current,
              onDidRemovePage: (removed) =>
                  pages.value = [...current]..remove(removed),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final routeA = routes['A']!;

      pages.value = pages.value.reversed.toList();
      await tester.pump();
      expect(routeA.isCurrent, isTrue);
      expect(routeA.animation!.isCompleted, isTrue);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
