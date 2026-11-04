import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'build_counts.dart';
import 'router_test_utils.dart';

// Does a deep link to a child build the parent's page? Asked of go_router in
// https://github.com/flutter/flutter/issues/141281: with routes '/' and
// '/:id', opening '/1' built the '/' screen, a costly page that was never shown.
// Here '/' and '/:id' are siblings, matched without prefix matches, the default
// on web (see deep_link_prefix_build_test.dart for the default elsewhere).
// Should: only the child is matched and built, once.
void main() {
  final builds = <String, int>{};
  setUp(builds.clear);

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: countedPage('ParentRoute', builds)),
      AutoRoute(path: '/:id', page: countedPage('ChildRoute', builds)),
    ],
  );

  // Steps: open the app at '/1'.
  testWidgets('A deep link to a sibling route builds only that page, once', (tester) async {
    final router = buildRouter();
    await pumpAtDeepLink(tester, router, '/1', includePrefixMatches: false);
    expect(router.stack.map((page) => page.name), ['ChildRoute']);
    expect(builds, {'ChildRoute': 1});
  });

  // The go_router issue's comments add that pushing a child, and popping it,
  // rebuilt the page under it.
  // Steps: open the app at '/', push '/1', pop it.
  // Should: the parent builds once in all, the child once.
  testWidgets('Pushing and popping a page does not rebuild the page under it', (tester) async {
    final router = buildRouter();
    await pumpAtDeepLink(tester, router, '/', includePrefixMatches: false);
    expect(builds, {'ParentRoute': 1});

    unawaited(router.pushPath('/1'));
    await tester.pumpAndSettle();
    expectTopPage(router, 'ChildRoute');
    expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});

    router.pop();
    await tester.pumpAndSettle();
    expectTopPage(router, 'ParentRoute');
    expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});
  });
}
