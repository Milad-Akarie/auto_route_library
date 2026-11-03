import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2321
  // An EmptyShellRoute holds a second EmptyShellRoute. Navigate to child1,
  // then child3 and child4 inside the second shell. currentHierarchy() should
  // list child3 and child4 under parentShell2, not leave it empty.
  testWidgets('currentHierarchy() lists the children of a router nested twice', (tester) async {
    final router = RootStackRouter.build(routes: [
      AutoRoute(page: _page('landing'), initial: true),
      AutoRoute(page: const EmptyShellRoute('parentShell'), children: [
        AutoRoute(page: _page('child1'), initial: true),
        AutoRoute(page: _page('child2')),
        AutoRoute(page: const EmptyShellRoute('parentShell2'), children: [
          AutoRoute(page: _page('child3'), initial: true),
          AutoRoute(page: _page('child4')),
        ]),
      ]),
    ]);
    await pumpRouterConfigApp(tester, router.config());
    router.navigate(const NamedRoute('child1'));
    await tester.pumpAndSettle();
    router.navigate(const NamedRoute('child3'));
    await tester.pumpAndSettle();
    router.navigate(const NamedRoute('child4'));
    await tester.pumpAndSettle();

    expect(find.text('child4'), findsOneWidget);
    expect(router.currentPath, '/parent-shell/child4');
    expect(router.currentHierarchy(), const [
      HierarchySegment('landing'),
      HierarchySegment('parentShell', children: [
        HierarchySegment('child1'),
        HierarchySegment('parentShell2', children: [
          HierarchySegment('child3'),
          HierarchySegment('child4'),
        ]),
      ]),
    ]);
  });
}

PageInfo _page(String name) => PageInfo(name, builder: (_) => Text(name));
