import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'build_counts.dart';
import 'router_test_utils.dart';

// Does a deep link to a child build the parent's page? Asked of go_router in
// https://github.com/flutter/flutter/issues/141281: with routes '/' and
// '/:id', opening '/1' built the '/' screen, a costly page that was never shown.
// With includePrefixMatches, the default off the web, '/1' stacks '/' under
// '/:id', so back leads to it. Flutter builds a covered page whose route
// keeps its state (maintainState, true by default) offstage, so its state is
// ready when it shows. That build is Flutter's, not auto_route's; a parent
// with maintainState: false is built only when back shows it.
void main() {
  final builds = <String, int>{};
  setUp(builds.clear);

  RootStackRouter buildRouter({required bool maintainParentState}) => .build(
    routes: [
      AutoRoute(path: '/', page: countedPage('ParentRoute', builds), maintainState: maintainParentState),
      AutoRoute(path: '/:id', page: countedPage('ChildRoute', builds)),
    ],
  );

  // Steps: open the app at '/1', then go back.
  // Should: the parent builds once, offstage, while the child shows, and back
  // shows it without building it again.
  testWidgets('A deep link builds the covered parent once, and back reuses it', (tester) async {
    final router = buildRouter(maintainParentState: true);
    await pumpAtDeepLink(tester, router, '/1', includePrefixMatches: true);
    expect(router.stack.map((page) => page.name), ['ParentRoute', 'ChildRoute']);
    expectTopPage(router, 'ChildRoute');
    expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});

    router.pop();
    await tester.pumpAndSettle();
    expectTopPage(router, 'ParentRoute');
    expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});
  });

  // Steps: with maintainState: false on the parent, open the app at
  // '/1', then go back.
  // Should: the parent is in the stack but does not build until back shows
  // it, then builds once.
  testWidgets('A deep link does not build a parent with maintainState false until back shows it', (tester) async {
    final router = buildRouter(maintainParentState: false);
    await pumpAtDeepLink(tester, router, '/1', includePrefixMatches: true);
    expect(router.stack.map((page) => page.name), ['ParentRoute', 'ChildRoute']);
    expectTopPage(router, 'ChildRoute');
    expect(builds, {'ChildRoute': 1});

    router.pop();
    await tester.pumpAndSettle();
    expectTopPage(router, 'ParentRoute');
    expect(builds, {'ChildRoute': 1, 'ParentRoute': 1});
  });
}
