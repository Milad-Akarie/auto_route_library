import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1956
  // Setup, as reported: the router's defaultRouteType is a custom fade-in. A
  // '/devices' shell route has a CustomRoute child ':id/controller' with its
  // own transitionsBuilder.
  // Reported: only the fade-in of defaultRouteType runs, never the builder of
  // the CustomRoute.
  // Should: the page of the CustomRoute is built with its own builder, not the
  // default one. The shell page that holds it is a route of its own: it uses
  // the default, and so does a first page of a new nested router, which only
  // shows with its shell's transition.
  late Set<String> used;
  late RootStackRouter router;

  RouteTransitionsBuilder recording(String builder) {
    return (context, animation, secondaryAnimation, child) {
      used.add('$builder:${ModalRoute.of(context)!.settings.name ?? 'null'}');
      return child;
    };
  }

  setUp(() {
    used = {};
    router = RootStackRouter.build(
      defaultRouteType: RouteType.custom(
        transitionsBuilder: recording('default'),
        duration: const Duration(milliseconds: 500),
      ),
      routes: [
        AutoRoute(page: _PageRoute.homePage, path: '/'),
        AutoRoute(
          page: _ShellRoute.page,
          path: '/devices',
          usesPathAsKey: true,
          children: [
            AutoRoute(page: _PageRoute.addPage, path: 'add'),
            CustomRoute(
              page: _PageRoute.controllerPage,
              path: ':id/controller',
              transitionsBuilder: recording('slideTop'),
              usesPathAsKey: true,
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('A CustomRoute pushed in a nested router uses its own transitionsBuilder', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/devices/add'));
    await tester.pumpAndSettle();
    used.clear();

    unawaited(router.navigatePath('/devices/1/controller'));
    await tester.pumpAndSettle();

    expect(find.text('Controller'), findsOneWidget);
    expect(used, contains('slideTop:ControllerRoute'));
    expect(used, isNot(contains('default:ControllerRoute')));
  });

  testWidgets('A CustomRoute opened with its shell uses its own transitionsBuilder', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    used.clear();

    unawaited(router.navigatePath('/devices/1/controller'));
    await tester.pumpAndSettle();

    expect(find.text('Controller'), findsOneWidget);
    expect(used, contains('default:ShellRoute'));
    expect(used, contains('slideTop:ControllerRoute'));
    expect(used, isNot(contains('default:ControllerRoute')));
  });
}

class _ShellRoute extends PageRouteInfo<void> {
  const _ShellRoute() : super(name);

  static const String name = 'ShellRoute';
  static PageInfo page = const PageInfo.emptyShell(name);
}

class _PageRoute {
  static PageInfo homePage = PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('Home')));
  static PageInfo addPage = PageInfo('AddRoute', builder: (_) => const Scaffold(body: Text('Add')));
  static PageInfo controllerPage = PageInfo(
    'ControllerRoute',
    builder: (_) => const Scaffold(body: Text('Controller')),
  );
}
