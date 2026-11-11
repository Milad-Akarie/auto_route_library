import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// AutoRouter.of in a page of a declarative router finds that router, and a pop
// on its only page closes the page holding it.
// https://github.com/Milad-Akarie/auto_route_library/issues/2087
// Headless tests: auto_route/test/nested_router/declarative_router_of_test.dart
// and auto_route/test/nested_router/declarative_pop_only_page_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AutoRouter.of in a declarative router', () {
    RootStackRouter buildRouter(void Function(BuildContext context) onPress) =>
        .build(
          routes: [
            AutoRoute(
              path: '/',
              initial: true,
              page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
            ),
            AutoRoute(
              path: '/host',
              page: PageInfo(
                'HostRoute',
                builder: (_) => AutoRouter.declarative(
                  routes: (_) => const [PageRouteInfo('ARoute')],
                ),
              ),
              children: [
                AutoRoute(
                  path: 'a',
                  page: PageInfo(
                    'ARoute',
                    builder: (_) => Builder(
                      builder: (context) => TextButton(
                        onPressed: () => onPress(context),
                        child: const Text('Close host'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

    Future<void> pressClose(WidgetTester tester, RootStackRouter router) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(const PageRouteInfo('HostRoute')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close host'));
      await tester.pumpAndSettle();
    }

    // Steps: Home pushes Host, whose declarative router shows A. A's button
    // calls AutoRouter.of(context).parent<StackRouter>()!.maybePop().
    // Should: Host closes, as the parent of the declarative router is the
    // root router.
    testWidgets('parent of the found router closes the host', (tester) async {
      final router = buildRouter(
        (context) => unawaited(
          AutoRouter.of(context).parent<StackRouter>()!.maybePop(),
        ),
      );
      await pressClose(tester, router);
      expect(find.text('Home'), findsOneWidget);
    });

    // Steps: as before, with a button that calls AutoRouter.of(context).pop()
    // on the only page of the declarative router.
    // Should: Host closes, and the screen doesn't go blank.
    testWidgets('pop on the only page closes the host', (tester) async {
      final router = buildRouter((context) => AutoRouter.of(context).pop());
      await pressClose(tester, router);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
