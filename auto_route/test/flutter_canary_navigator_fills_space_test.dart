import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter issues https://github.com/flutter/flutter/issues/14803
// and https://github.com/flutter/flutter/issues/154914: a Navigator fills
// all the room it is given, whatever its page's size.
// Setup: a Navigator under a Center, whose page is a 100 x 200 box; the same
// with a nested AutoRouter under a Center.
// Steps: show the page and measure the navigator.
// Today the Navigator's Overlay takes the biggest size its loose constraints
// allow and lays every page out tight to that size (widgets/overlay.dart,
// _RenderTheater.performLayout). Overlay has an alwaysSizeToContent switch,
// but Navigator never passes it (widgets/navigator.dart, NavigatorState.build).
// So a nested router can't size itself to its page in a dialog or a bottom
// sheet, and a page in a Scaffold body is stretched where the same widget
// without a navigator is not.
// If this test fails after a Flutter upgrade, a Navigator can now size to its
// page: drop this canary and the note in the fork's Flutter list.
void main() {
  const page = SizedBox(width: 100, height: 200, child: Text('Page'));

  testWidgets('a plain navigator fills a Center', (tester) async {
    final pages = [const MaterialPage<void>(child: page)];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Navigator(pages: pages, onDidRemovePage: pages.remove),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Navigator).last), const Size(800, 600));
  });

  testWidgets('a nested AutoRouter fills a Center', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'ShellRoute',
            builder: (_) => const Center(child: AutoRouter()),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('PageRoute', builder: (_) => page),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(find.text('Page'), findsOneWidget);
    expect(tester.getSize(find.byType(Navigator).last), const Size(800, 600));
  });
}
