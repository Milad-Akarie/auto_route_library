import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/893
  // Reported on 3.2.0: a declarative router that returned, from the start, a
  // shell route whose child has the path '' (signed in at once) put that
  // child on the stack twice, so the main page showed a back button.
  // Today a declarative router is AutoRouter.declarative in a page.
  // Steps: a host page whose AutoRouter.declarative returns
  // [EmptyMainRouter()] at once; EmptyMainRouter is a shell holding MainRoute
  // at ''; AuthRoute sits beside it. Open the app at '/'.
  // Should: the shell holds MainRoute once and nothing can pop.
  testWidgets(
    'A declarative router returning a shell at once builds its empty-path '
    'child once',
    (tester) async {
      var mainBuilds = 0;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HostRoute',
            path: '/',
            builder: (_, _) => AutoRouter.declarative(
              routes: (_) => const [NamedRoute('EmptyMainRouter')],
            ),
            children: [
              NamedRouteDef.shell(
                name: 'EmptyMainRouter',
                path: '',
                children: [
                  NamedRouteDef(
                    name: 'MainRoute',
                    path: '',
                    builder: (_, _) {
                      mainBuilds++;
                      return const Text('MainRoute');
                    },
                  ),
                ],
              ),
              NamedRouteDef(
                name: 'AuthRoute',
                path: 'auth',
                builder: (_, _) => const Text('AuthRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      expect(tester.takeException(), isNull);
      expect(find.text('MainRoute'), findsOneWidget);
      final shell = tester.element(find.text('MainRoute')).router;
      expect(shell.routeData.name, 'EmptyMainRouter');
      expect(shell.stack.map((page) => page.name), ['MainRoute']);
      expect(shell.parentAsStackRouter?.stack.map((page) => page.name), [
        'EmptyMainRouter',
      ]);
      expect(router.canPop(), isFalse);
      expect(mainBuilds, 1);
    },
  );

  // The second report on #893: the declarative list returns HomeRoute, whose
  // child at '' is a tab host page; the tab host showed up twice.
  testWidgets(
    'A declarative router returning a page whose empty-path child holds tabs '
    'builds the tab host once',
    (tester) async {
      var tabHostBuilds = 0;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'AppRoute',
            path: '/',
            builder: (_, _) => AutoRouter.declarative(
              routes: (_) => const [NamedRoute('HomeRoute')],
            ),
            children: [
              NamedRouteDef.shell(
                name: 'HomeRoute',
                path: '',
                children: [
                  NamedRouteDef(
                    name: 'TabHostRoute',
                    path: '',
                    builder: (_, _) {
                      tabHostBuilds++;
                      return const AutoTabsRouter(
                        routes: [
                          NamedRoute('ChatTab'),
                          NamedRoute('ContactTab'),
                        ],
                      );
                    },
                    children: [
                      NamedRouteDef(
                        name: 'ChatTab',
                        path: 'chats',
                        builder: (_, _) => const Text('ChatTab'),
                      ),
                      NamedRouteDef(
                        name: 'ContactTab',
                        path: 'contacts',
                        builder: (_, _) => const Text('ContactTab'),
                      ),
                    ],
                  ),
                ],
              ),
              NamedRouteDef(
                name: 'SplashRoute',
                path: 'splash',
                builder: (_, _) => const Text('SplashRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      expect(tester.takeException(), isNull);
      expect(find.text('ChatTab'), findsOneWidget);
      final home = router
          .innerRouterOf<StackRouter>('AppRoute')!
          .innerRouterOf<StackRouter>('HomeRoute')!;
      expect(home.stack.map((page) => page.name), ['TabHostRoute']);
      expect(router.canPop(), isFalse);
      expect(tabHostBuilds, 1);
    },
  );
}
