import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replaceAll right after the reevaluate listenable changes replaces the stack.
// https://github.com/Milad-Akarie/auto_route_library/issues/2172
// Headless test:
// auto_route/test/reevaluatable_router/replace_all_on_reevaluation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('replace all on reevaluation', () {
    late _AuthRepo authRepo;
    late RootStackRouter router;
    setUp(() {
      authRepo = _AuthRepo();
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _LoginRoute.page(authRepo), path: '/login'),
          AutoRoute(
            page: _HomeRoute.page(authRepo),
            path: '/',
            initial: true,
            guards: [
              AutoRouteGuard.simple((resolver, guardRouter) {
                if (authRepo.isLoggedIn) {
                  resolver.next();
                  return;
                }
                resolver.reject();
                unawaited(guardRouter.replaceAll([const _LoginRoute()]));
              }),
            ],
          ),
        ],
      );
    });

    // Steps: the guarded HomeRoute sends the logged-out user to LoginRoute. Tap
    // 'Log In', which logs in and calls replaceAll([HomeRoute()]) right away.
    // Then tap 'Log Out' and 'Log In' again.
    // Should: each time one page is left: HomeRoute, then LoginRoute, then
    // HomeRoute.
    testWidgets(
      'replaceAll right after the reevaluate listenable changes replaces the '
      'stack',
      (tester) async {
        await pumpRouterApp(tester, router, reevaluationNotifier: authRepo);
        final earlier2 = router.stack.map((p) => p.name).toList();

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();
        final earlier1 = router.stack.map((p) => p.name).toList();
        expect(find.text('Home Screen'), findsOneWidget);
        await expectBrowserUrl('/');

        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        expect(
          [earlier2, router.stack.map((p) => p.name).toList()],
          [
            [_LoginRoute.name],
            [_LoginRoute.name],
          ],
        );

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();
        expect(
          [earlier1, router.stack.map((p) => p.name).toList()],
          [
            [_HomeRoute.name],
            [_HomeRoute.name],
          ],
        );
      },
    );
  });
}

class _AuthRepo with ChangeNotifier {
  bool isLoggedIn = false;

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    isLoggedIn = false;
    notifyListeners();
  }
}

class _LoginRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'LoginRoute';
  static PageInfo page(_AuthRepo authRepo) => .new(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: FilledButton(
            onPressed: () {
              authRepo.login();
              unawaited(context.router.replaceAll([const _HomeRoute()]));
            },
            child: const Text('Log In'),
          ),
        ),
      ),
    ),
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page(_AuthRepo authRepo) => .new(
    name,
    builder: (_) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text('Home Screen'),
            FilledButton(
              onPressed: authRepo.logOut,
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    ),
  );
}
