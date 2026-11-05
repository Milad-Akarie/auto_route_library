import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A CustomRoute keeps its own transitionsBuilder under a custom
// defaultRouteType.
// https://github.com/Milad-Akarie/auto_route_library/issues/1956
// Headless test: auto_route/test/transitions/custom_route_transition_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: the router's defaultRouteType is a custom fade-in; '/devices' is a
  // shell route with a page '/devices/add' and a CustomRoute
  // ':id/controller' with its own builder. Open '/devices/add', then
  // '/devices/1/controller'.
  // Should: the controller page is built with its own builder.
  testWidgets(
    'A CustomRoute pushed in a nested router uses its own transitionsBuilder',
    (tester) async {
      final used = <String>{};
      RouteTransitionsBuilder recording(String builder) {
        return (context, animation, secondaryAnimation, child) {
          used.add(
            '$builder:${ModalRoute.of(context)!.settings.name ?? 'null'}',
          );
          return child;
        };
      }

      final router = RootStackRouter.build(
        defaultRouteType: RouteType.custom(
          transitionsBuilder: recording('default'),
          duration: const Duration(milliseconds: 500),
        ),
        routes: [
          AutoRoute(page: _page('HomeRoute'), path: '/'),
          AutoRoute(
            page: const PageInfo.emptyShell('ShellRoute'),
            path: '/devices',
            usesPathAsKey: true,
            children: [
              AutoRoute(page: _page('AddRoute'), path: 'add'),
              CustomRoute(
                page: _page('ControllerRoute'),
                path: ':id/controller',
                transitionsBuilder: recording('slideTop'),
                usesPathAsKey: true,
              ),
            ],
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.navigatePath('/devices/add'));
      await tester.pumpAndSettle();
      used.clear();

      unawaited(router.navigatePath('/devices/1/controller'));
      await tester.pumpAndSettle();

      expect(find.text('ControllerRoute'), findsOneWidget);
      expect(used, contains('slideTop:ControllerRoute'));
      expect(used, isNot(contains('default:ControllerRoute')));
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
