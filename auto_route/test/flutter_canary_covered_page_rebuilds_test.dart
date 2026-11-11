import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter proposal https://github.com/flutter/flutter/issues/96044:
// covered pages rebuild on every MediaQuery change they read.
// Setup: a first page whose widget reads MediaQuery.viewInsetsOf, as a
// Scaffold does; a second page pushed over it. The same in an auto_route app.
// Steps: open the keyboard (bottom view inset 300) while the second page
// shows.
// Today the covered page builds again: a covered route stays mounted
// (maintainState), so its MediaQuery dependents rebuild like any other, on
// every frame of a keyboard animation. Since Flutter 3.10 a page that reads
// no viewInsets doesn't rebuild. The proposal is to wait until the page shows
// again; its pull request (flutter/flutter#116090) never landed. auto_route
// stacks are one Navigator, so a deep stack pays the same; maintainState:
// false on an AutoRoute drops covered pages instead.
// If this test fails after a Flutter upgrade, covered pages no longer
// rebuild while covered: drop this canary and the note in the fork's Flutter
// list.
void main() {
  Widget insetsReader(List<String> builds) => Builder(
    builder: (context) {
      MediaQuery.viewInsetsOf(context);
      builds.add('covered');
      return const Text('Covered');
    },
  );

  testWidgets('a covered plain page rebuilds when the keyboard opens', (
    tester,
  ) async {
    final builds = <String>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: insetsReader(builds)),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('Top')),
    );
    await tester.pumpAndSettle();
    builds.clear();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(builds, ['covered']);
  });

  testWidgets('a covered auto_route page rebuilds when the keyboard opens', (
    tester,
  ) async {
    final builds = <String>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('CoveredRoute', builder: (_) => insetsReader(builds)),
        ),
        AutoRoute(
          path: '/top',
          page: PageInfo('TopRoute', builder: (_) => const Text('Top')),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/top'));
    await tester.pumpAndSettle();
    builds.clear();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(find.text('Top'), findsOneWidget);
    expect(builds, ['covered']);
  });
}
