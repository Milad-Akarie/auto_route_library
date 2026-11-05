import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/161893
  // In go_router, a DropdownMenu on a page inside a ShellRoute whose builder
  // put a 300 px side nav beside the shell's navigator opened its menu 300 px
  // to the left of the field.
  // Steps: ShellRoute shows a 300 px side nav beside its nested
  // AutoRouter; the nested router's page holds a DropdownMenu; open it.
  // Should: the menu opens under the field, aligned with its left edge.
  testWidgets(
    'A DropdownMenu in a nested router beside a side nav opens under its field (flutter/flutter#161893)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo(
              'ShellRoute',
              builder: (_) => const Row(
                children: [
                  SizedBox(width: 300, child: ColoredBox(color: Colors.grey)),
                  Expanded(child: AutoRouter()),
                ],
              ),
            ),
            path: '/',
            children: [
              AutoRoute(
                page: PageInfo(
                  'FormRoute',
                  builder: (_) => const Scaffold(
                    body: Padding(
                      padding: .all(16),
                      child: DropdownMenu<String>(
                        key: ValueKey('field'),
                        dropdownMenuEntries: [
                          DropdownMenuEntry(value: 'one', label: 'One'),
                          DropdownMenuEntry(value: 'two', label: 'Two'),
                        ],
                      ),
                    ),
                  ),
                ),
                path: '',
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final field = tester.getRect(find.byKey(const ValueKey('field')));
      expect(field.left, 316);

      await tester.tap(find.byKey(const ValueKey('field')));
      await tester.pumpAndSettle();

      // The menu item a tap reaches; the field also lays out its items offstage.
      final menuItem = find.widgetWithText(MenuItemButton, 'One').hitTestable();
      expect(menuItem, findsOneWidget);
      final item = tester.getRect(menuItem);
      expect(item.left, moreOrLessEquals(field.left, epsilon: 1));
      expect(item.top, greaterThanOrEqualTo(field.bottom - 1));
    },
  );
}
