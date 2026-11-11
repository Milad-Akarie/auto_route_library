import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../named_page.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/963
  // Reported: with restorationScopeId on MaterialApp.router, navigating to a
  // nested route threw "Multiple owners claimed child RestorationBuckets
  // with the same IDs"; a later comment saw it with a tabs router.
  // Steps: an app with restorationScopeId 'root'; navigate between pages of
  // a shell and of a tabs router, and push the same nested routes twice.
  // Should: no error; each page claims its own restoration id.
  testWidgets(
    'Navigating nested routes with state restoration on claims no restoration '
    'id twice',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const NamedPage('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'TabsRoute',
            path: '/tabs',
            builder: (_, _) => const AutoTabsScaffold(
              routes: [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')],
            ),
            children: [
              NamedRouteDef.shell(
                name: 'Tab1Route',
                path: 'tab1',
                children: [
                  NamedRouteDef(
                    name: 'ARoute',
                    path: '',
                    builder: (_, _) => const NamedPage('ARoute'),
                  ),
                  NamedRouteDef(
                    name: 'BRoute',
                    path: 'b',
                    builder: (_, _) => const NamedPage('BRoute'),
                  ),
                ],
              ),
              NamedRouteDef.shell(
                name: 'Tab2Route',
                path: 'tab2',
                children: [
                  NamedRouteDef(
                    name: 'CRoute',
                    path: '',
                    builder: (_, _) => const NamedPage('CRoute'),
                  ),
                ],
              ),
            ],
          ),
          NamedRouteDef.shell(
            name: 'ShellRoute',
            path: '/shell',
            children: [
              NamedRouteDef(
                name: 'S1Route',
                path: '',
                builder: (_, _) => const NamedPage('S1Route'),
              ),
              NamedRouteDef(
                name: 'S2Route',
                path: 's2',
                builder: (_, _) => const NamedPage('S2Route'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          restorationScopeId: 'root',
          routerConfig: router.config(),
        ),
      );
      await tester.pumpAndSettle();

      for (final path in [
        '/shell/s2',
        '/tabs/tab1/b',
        '/tabs/tab2',
        '/shell',
        '/tabs/tab1',
      ]) {
        unawaited(router.navigatePath(path));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      for (final path in [
        '/shell/s2',
        '/shell/s2',
        '/tabs/tab1/b',
        '/tabs/tab1/b',
      ]) {
        unawaited(router.pushPath(path));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'push $path');
      }
      expect(find.text('BRoute'), findsOneWidget);
    },
  );
}
