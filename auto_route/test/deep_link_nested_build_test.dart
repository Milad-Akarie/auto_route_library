import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'build_counts.dart';

// Does a deep link to a child build the parent's page? Asked of go_router in
// https://github.com/flutter/flutter/issues/141281: with routes '/' and
// '/:id', opening '/1' built the '/' screen, a costly page that was never shown.
// Here the child is nested: the parent's page holds the AutoRouter that shows
// it, so the parent must build. It should build once, and nothing twice.
void main() {
  final builds = <String, int>{};
  setUp(builds.clear);

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: countedPage('ParentRoute', builds, body: const AutoRouter()),
        children: [
          AutoRoute(path: '', page: countedPage('HomeRoute', builds)),
          AutoRoute(path: ':id', page: countedPage('ChildRoute', builds)),
        ],
      ),
    ],
  );

  // Steps: open the app at '/1', matched without prefix matches, the default
  // on web.
  // Should: the parent and the child build once each; the parent's home page
  // is not matched and does not build.
  testWidgets('A deep link to a nested child builds its parent once', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpAtDeepLink(
      tester,
      router,
      '/1',
      shouldIncludePrefixMatches: false,
    );
    expect(router.topRoute.name, 'ChildRoute');
    expect(find.text('ChildRoute'), findsOneWidget);
    expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});
  });

  // Steps: open the app at '/1', matched with prefix matches, the default
  // elsewhere.
  // Should: the parent and the child build once each. The nested router stacks
  // the parent's home page under the child, and Flutter builds that covered
  // page once, offstage, as it does at the root (see
  // deep_link_prefix_build_test.dart).
  testWidgets('A deep link with prefix matches builds each nested page once', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpAtDeepLink(
      tester,
      router,
      '/1',
      shouldIncludePrefixMatches: true,
    );
    expect(router.topRoute.name, 'ChildRoute');
    expect(find.text('ChildRoute'), findsOneWidget);
    expect(builds, {'ParentRoute': 1, 'HomeRoute': 1, 'ChildRoute': 1});
  });
}
