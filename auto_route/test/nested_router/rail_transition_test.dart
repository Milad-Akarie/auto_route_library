import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#112565: with a shell route around a NavigationRail, the
// page transition animated over the rail instead of beside it.
// Steps: a host page with a rail on the left and a nested router beside
// it; navigate from 'library' to 'settings' and look at the frames in between.
// Should: the nested navigator stays right of the rail and clips its pages
// there, and the rail doesn't move.
void main() {
  testWidgets('A nested page transition stays beside the navigation rail', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: ColoredBox(color: Colors.grey, child: Text('rail')),
                ),
                Expanded(child: AutoRouter()),
              ],
            ),
          ),
          children: [
            NamedRouteDef(
              name: 'LibraryRoute',
              path: 'library',
              initial: true,
              builder: (_, _) => const Text('library'),
            ),
            NamedRouteDef(
              name: 'SettingsRoute',
              path: 'settings',
              builder: (_, _) => const Text('settings'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final railRect = tester.getRect(find.text('rail'));

    unawaited(router.navigate(const NamedRoute('SettingsRoute')));
    await tester.pump();
    final navigator = find.descendant(
      of: find.byType(AutoRouter),
      matching: find.byType(Navigator),
    );
    final overlay = find.descendant(
      of: navigator,
      matching: find.byType(Overlay),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      // A page may slide out of its area, but the navigator clips it there.
      expect(tester.getRect(navigator).left, 80, reason: 'frame $i');
      expect(
        tester.widget<Overlay>(overlay).clipBehavior,
        isNot(Clip.none),
        reason: 'frame $i',
      );
      expect(tester.getRect(find.text('rail')), railRect);
    }
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
  });
}
