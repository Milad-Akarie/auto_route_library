import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/182573:
// a SelectionArea above a navigator selects the text of a covered page.
// Setup: one SelectionArea around a Navigator, as a shell around a nested
// router; a list page, then a detail page pushed over it, each a column of
// rows at the same places. The same with a nested AutoRouter.
// Steps: drag with a mouse from the third detail row to the fifth.
// Today the selection holds the covered list's rows too ("List row 3",
// "List row 4"), in between the detail rows: a covered page stays mounted,
// its Text widgets stay registered with the SelectionArea, and the area
// orders them by their place on screen. On the web the reporter sees dead
// zones where a drag selects nothing. The go_router fix was closed for a
// framework fix that does not exist yet.
// If this test fails after a Flutter upgrade, a covered page's text no
// longer takes part in selection: drop this canary.
void main() {
  Widget rows(String name) => Scaffold(
    body: Column(
      children: [
        for (var i = 0; i < 6; i++)
          SizedBox(height: 40, child: Text('$name row $i')),
      ],
    ),
  );

  Future<void> dragOverDetail(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getTopLeft(find.text('Detail row 2')) + const Offset(2, 5),
      kind: .mouse,
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Detail row 4')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a plain covered page joins the selection', (tester) async {
    SelectedContent? selected;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          onSelectionChanged: (content) => selected = content,
          child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => rows('List')),
          ),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => rows('Detail')),
    );
    await tester.pumpAndSettle();
    await dragOverDetail(tester);

    expect(selected?.plainText, contains('List row 3'));
  });

  testWidgets('a covered auto_route page joins the selection', (tester) async {
    SelectedContent? selected;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'ShellRoute',
            builder: (_) => SelectionArea(
              onSelectionChanged: (content) => selected = content,
              child: const AutoRouter(),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('ListRoute', builder: (_) => rows('List')),
            ),
            AutoRoute(
              path: 'detail',
              page: PageInfo('DetailRoute', builder: (_) => rows('Detail')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.navigatePath('/detail'));
    await tester.pumpAndSettle();
    await dragOverDetail(tester);

    expect(selected?.plainText, contains('List row 3'));
  });
}
