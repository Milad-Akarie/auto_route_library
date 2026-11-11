import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// currentHierarchy() lists the children of a router nested twice.
// https://github.com/Milad-Akarie/auto_route_library/issues/2321
// Headless test: auto_route/test/nested_router/current_hierarchy_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('current hierarchy', () {
    // Steps: an EmptyShellRoute holds a second EmptyShellRoute. Navigate to
    // child1, then to child3 and child4 inside the second shell.
    // Should: currentHierarchy() lists child3 and child4 under parentShell2.
    testWidgets(
      'currentHierarchy() lists the children of a router nested twice',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(page: _page('landing'), initial: true),
            AutoRoute(
              page: const EmptyShellRoute('parentShell'),
              children: [
                AutoRoute(page: _page('child1'), initial: true),
                AutoRoute(page: _page('child2')),
                AutoRoute(
                  page: const EmptyShellRoute('parentShell2'),
                  children: [
                    AutoRoute(page: _page('child3'), initial: true),
                    AutoRoute(page: _page('child4')),
                  ],
                ),
              ],
            ),
          ],
        );
        await pumpRouterAppWithConfig(tester, router);
        for (final name in ['child1', 'child3', 'child4']) {
          unawaited(router.navigate(NamedRoute(name)));
          await tester.pumpAndSettle();
        }

        expect(find.text('child4'), findsOneWidget);
        expect(router.currentPath, '/parent-shell/child4');
        expect(router.currentHierarchy(), const [
          HierarchySegment('landing'),
          HierarchySegment(
            'parentShell',
            children: [
              HierarchySegment('child1'),
              HierarchySegment(
                'parentShell2',
                children: [
                  HierarchySegment('child3'),
                  HierarchySegment('child4'),
                ],
              ),
            ],
          ),
        ]);
        await expectBrowserUrl('/parent-shell/child4');
      },
    );
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);
