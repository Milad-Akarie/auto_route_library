import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Does a deep link to a child build the parent's page? Asked of go_router in
// https://github.com/flutter/flutter/issues/141281: on web, with routes '/'
// and '/:id', entering '/1' in the address bar built the '/' screen, a costly
// page that was never shown. On web the browser opens the app at the link;
// elsewhere the platform hands it over as the initial route.
// Headless tests: auto_route/test/deep_link_flat_build_test.dart and
// auto_route/test/deep_link_prefix_build_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final builds = <String, int>{};
  setUp(builds.clear);

  RootStackRouter buildRouter({bool maintainParentState = true}) => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: _countedPage('ParentRoute', builds),
        maintainState: maintainParentState,
      ),
      AutoRoute(path: '/:id', page: _countedPage('ChildRoute', builds)),
    ],
  );

  Future<void> openAt(
    WidgetTester tester,
    RootStackRouter router, {
    required bool includePrefixMatches,
  }) async {
    // The config reads the platform's initial route when it is first made,
    // so it is made inside the app, after pumpAppAtDeepLink sets the link,
    // as runApp would find it.
    await pumpAppAtDeepLink(
      tester,
      '/1',
      Builder(
        builder: (_) => MaterialApp.router(
          routerConfig: router.config(
            includePrefixMatches: includePrefixMatches,
          ),
        ),
      ),
    );
    expect(find.text('ChildRoute'), findsOneWidget);
    await expectBrowserUrl('/1');
  }

  // Steps: open the app at '/1' without prefix matches, the default on web.
  // Should: only the child is matched and built, once.
  testWidgets('A deep link to a sibling route builds only that page', (
    tester,
  ) async {
    final router = buildRouter();
    await openAt(tester, router, includePrefixMatches: false);
    expect(router.stack.map((page) => page.name), ['ChildRoute']);
    expect(builds, {'ChildRoute': 1});
  });

  // Steps: open the app at '/1' with prefix matches, the default elsewhere,
  // then go back.
  // Should: '/' is stacked under the child and Flutter builds it once,
  // offstage, since its route keeps its state; back shows it without building
  // it again.
  testWidgets(
    'With prefix matches, a deep link builds the covered parent once',
    (tester) async {
      final router = buildRouter();
      await openAt(tester, router, includePrefixMatches: true);
      expect(router.stack.map((page) => page.name), [
        'ParentRoute',
        'ChildRoute',
      ]);
      expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('ParentRoute'), findsOneWidget);
      expect(builds, {'ParentRoute': 1, 'ChildRoute': 1});
    },
  );

  // Steps: as above, with maintainState: false on the parent.
  // Should: the parent does not build until back shows it.
  testWidgets(
    'With prefix matches, a parent with maintainState false builds only on back',
    (tester) async {
      final router = buildRouter(maintainParentState: false);
      await openAt(tester, router, includePrefixMatches: true);
      expect(router.stack.map((page) => page.name), [
        'ParentRoute',
        'ChildRoute',
      ]);
      expect(builds, {'ChildRoute': 1});

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('ParentRoute'), findsOneWidget);
      expect(builds, {'ChildRoute': 1, 'ParentRoute': 1});
    },
  );
}

PageInfo _countedPage(String name, Map<String, int> builds) => .new(
  name,
  builder: (_) => Builder(
    builder: (_) {
      builds[name] = (builds[name] ?? 0) + 1;
      return Scaffold(body: Text(name));
    },
  ),
);
