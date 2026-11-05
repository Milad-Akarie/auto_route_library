import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter issues https://github.com/flutter/flutter/issues/138209
// and https://github.com/flutter/flutter/issues/85603: a page in a nested
// navigator never sees the PrimaryScrollController above that navigator.
// Every ModalRoute wraps its page in a PrimaryScrollController of its own
// (widgets/routes.dart, _ModalScopeState.build), and auto_route pages are
// ModalRoutes.
// flutter/flutter#138209. Setup: a PrimaryScrollController around a nested
// Navigator, as NestedScrollView gives its body; the same around a nested
// AutoRouter. Steps: show the page and read PrimaryScrollController.maybeOf.
// Today the page reads its route's controller, so a NestedScrollView's inner
// controller is ignored and its header doesn't collapse.
// flutter/flutter#85603. Setup on iOS, with a status bar: a Scaffold with an
// AppBar whose body is a nested AutoRouter; its page is a Scaffold with a
// primary ListView. Steps: scroll the list, then tap the status bar. Today
// the list doesn't move: the outer Scaffold takes the tap but scrolls its own
// route's controller, and the inner Scaffold, below the AppBar, isn't at the
// top of the screen where Scaffold hit tests the tap (material_ui
// scaffold.dart, ScaffoldState.handleStatusBarTap). Since Flutter 3.42 a page
// Scaffold that reaches the top, as in a tab with its own app bar, scrolls
// (flutter/flutter#179643).
// If a test fails after a Flutter upgrade, Flutter changed that behavior:
// drop that test and its note in the fork's Flutter list.
void main() {
  testWidgets('a page in a plain nested navigator reads its own controller', (
    tester,
  ) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    ScrollController? found;
    final pages = [
      MaterialPage<void>(
        child: Builder(
          builder: (context) {
            found = PrimaryScrollController.maybeOf(context);
            return const Text('Page');
          },
        ),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: outer,
          child: Navigator(pages: pages, onDidRemovePage: pages.remove),
        ),
      ),
    );

    expect(found, isNotNull);
    expect(identical(found, outer), isFalse);
  });

  testWidgets('a page in a nested AutoRouter reads its own controller', (
    tester,
  ) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    ScrollController? found;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'ShellRoute',
            builder: (_) => PrimaryScrollController(
              controller: outer,
              child: const AutoRouter(),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'PageRoute',
                builder: (_) => Builder(
                  builder: (context) {
                    found = PrimaryScrollController.maybeOf(context);
                    return const Text('Page');
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(find.text('Page'), findsOneWidget);
    expect(found, isNotNull);
    expect(identical(found, outer), isFalse);
  });

  testWidgets('a status bar tap misses a list under an AppBar', (tester) async {
    debugDefaultTargetPlatformOverride = .iOS;
    tester.view.padding = const FakeViewPadding(top: 141);
    addTearDown(tester.view.resetPadding);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'ShellRoute',
            builder: (_) =>
                Scaffold(appBar: AppBar(), body: const AutoRouter()),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'ListRoute',
                builder: (_) => Scaffold(
                  body: ListView(
                    primary: true,
                    children: [
                      for (var i = 0; i < 100; i++)
                        SizedBox(height: 50, child: Text('Item $i')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    final scrolled = position.pixels;

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.statusBar.name,
      SystemChannels.statusBar.codec.encodeMethodCall(
        const MethodCall('handleScrollToTop'),
      ),
      null,
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(scrolled, greaterThan(0));
    expect(position.pixels, scrolled);
  });
}
