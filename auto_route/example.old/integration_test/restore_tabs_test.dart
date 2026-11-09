import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// Every tab keeps its own stack after state restoration.
// https://github.com/Milad-Akarie/auto_route_library/issues/2041
// https://github.com/Milad-Akarie/auto_route_library/issues/2099
// Headless test: auto_route/test/restoration/restore_tabs_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('restore tabs', () {
    // Flutter's state restoration doesn't run on the web, so the routers save
    // their pages only off the web.

    RootStackRouter buildRouter() => .build(
      routes: [
        AutoRoute(path: '/', page: namedPage('SignUpRoute'), initial: true),
        AutoRoute(
          path: '/bottom',
          page: _bottomNavigationPage,
          children: [
            AutoRoute(
              path: 'home',
              page: const EmptyShellRoute('HomeTabRoute'),
              initial: true,
              children: [
                AutoRoute(path: '', page: namedPage('HomeRoute')),
                AutoRoute(path: 'internal', page: namedPage('InternalRoute')),
              ],
            ),
            AutoRoute(
              path: 'transitions',
              page: const EmptyShellRoute('TransitionsTabRoute'),
              children: [
                AutoRoute(path: '', page: namedPage('TransitionsRoute')),
                AutoRoute(
                  path: 'details',
                  page: namedPage('TransitionDetailsRoute'),
                ),
              ],
            ),
            AutoRoute(path: 'settings', page: namedPage('SettingsRoute')),
          ],
        ),
      ],
    );

    Future<void> tapTab(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    // Steps: replace(BottomNavigationRoute()), push(InternalRoute()) in the
    // home tab, tap the transitions tab, then restore the app and tap the
    // home tab.
    // Should: the transitions tab shows after the restore, and the home tab
    // still shows InternalRoute, with HomeRoute under it.
    testWidgets('a tab that is not active keeps its stack after restoration', (
      tester,
    ) async {
      await pumpRestorableApp(tester, buildRouter);
      unawaited(
        RestorableRouterApp.router.replace(
          const NamedRoute('BottomNavigationRoute'),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        RestorableRouterApp.router.push(const NamedRoute('InternalRoute')),
      );
      await tester.pumpAndSettle();
      final earlier1 = find.text('InternalRoute').evaluate().length;
      await tapTab(tester, 'transitions');

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.text('TransitionsRoute'), findsOneWidget);
      await expectBrowserUrl('/bottom/transitions');
      await tapTab(tester, 'home');
      expect(find.text('HomeRoute'), findsNothing);
      expect((earlier1, find.text('InternalRoute').evaluate().length), (1, 1));
      await systemBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
    }, skip: kIsWeb);

    // Steps: push InternalRoute in the home tab, tap the transitions tab and
    // push TransitionDetailsRoute there, tap the settings tab, then restore
    // the app and tap each tab.
    // Should: every tab shows the page it showed before the restore.
    testWidgets('every tab keeps its stack after restoration', (tester) async {
      await pumpRestorableApp(tester, buildRouter);
      unawaited(
        RestorableRouterApp.router.replace(
          const NamedRoute('BottomNavigationRoute'),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        RestorableRouterApp.router.push(const NamedRoute('InternalRoute')),
      );
      await tester.pumpAndSettle();
      await tapTab(tester, 'transitions');
      unawaited(
        RestorableRouterApp.router.push(
          const NamedRoute('TransitionDetailsRoute'),
        ),
      );
      await tester.pumpAndSettle();
      await tapTab(tester, 'settings');

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.text('SettingsRoute'), findsOneWidget);
      await tapTab(tester, 'transitions');
      expect(find.text('TransitionDetailsRoute'), findsOneWidget);
      await tapTab(tester, 'home');
      expect(find.text('InternalRoute'), findsOneWidget);
    }, skip: kIsWeb);
  });
}

final _bottomNavigationPage = PageInfo(
  'BottomNavigationRoute',
  builder: (_) => AutoTabsRouter(
    routes: const [
      NamedRoute('HomeTabRoute'),
      NamedRoute('TransitionsTabRoute'),
      NamedRoute('SettingsRoute'),
    ],
    builder: (context, child) {
      final tabsRouter = AutoTabsRouter.of(context);
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          type: .fixed,
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.move_up),
              label: 'transitions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'settings',
            ),
          ],
        ),
      );
    },
  ),
);
