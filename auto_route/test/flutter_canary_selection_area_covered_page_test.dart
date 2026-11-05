import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/119772.
// Setup: ShellRoute wraps a nested AutoRouter in a SelectionArea. Plain
// Flutter, with a SelectableRegion around a Navigator given two pages at
// once, fails the same way.
// Steps: open the app on the deep link /foreground, which stacks
// ForegroundRoute on BackgroundRoute in the nested router at once.
// Today BackgroundRoute is built but never laid out, since it is covered from
// the start. The SelectionArea sorts every selectable by its place on screen,
// including BackgroundRoute's Text, and asserts "RenderBox was not laid out"
// when it measures it. auto_route cannot lay out a covered page without
// building it on screen.
// If this test fails after a Flutter upgrade, the selection area no longer
// measures a page that was never laid out: drop this canary.
void main() {
  testWidgets('a selection area over a page never laid out asserts when it sorts its selectables', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('ShellRoute', builder: (_) => const SelectionArea(child: AutoRouter())),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('BackgroundRoute', builder: (_) => const Scaffold(body: Text('background'))),
            ),
            AutoRoute(
              path: 'foreground',
              page: PageInfo('ForegroundRoute', builder: (_) => const Scaffold(body: Text('foreground'))),
            ),
          ],
        ),
      ],
    );
    final errors = <Object>[];
    await runZonedGuarded(
      () => pumpRouterApp(tester, router, initialLink: '/foreground'),
      (error, _) => errors.add(error),
    );
    expect(router.innerRouterOf<StackRouter>('ShellRoute')!.stack.map((page) => page.name), [
      'BackgroundRoute',
      'ForegroundRoute',
    ]);
    expect(find.text('foreground'), findsOneWidget);
    expect(errors, isNotEmpty);
    expect(errors.firstOrNull?.toString(), contains('RenderBox was not laid out'));
  });
}
