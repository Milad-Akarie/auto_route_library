import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

void main() {
  late _AuthRepo authRepo;
  late RootStackRouter router;
  setUp(() {
    authRepo = _AuthRepo();
    addTearDown(authRepo.dispose);
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _LoginRoute.page(authRepo)),
        AutoRoute(
          page: _HomeRoute.page(authRepo),
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, guardedRouter) {
              if (authRepo.isLoggedIn) {
                resolver.next();
                return;
              }
              resolver.reject();
              unawaited(guardedRouter.replaceAll([const _LoginRoute()]));
            }),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(reevaluateListenable: authRepo),
      ),
    );
    await tester.pumpAndSettle();
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2172
  // The guarded HomeRoute sends a logged-out user to LoginRoute with
  // replaceAll, and the auth state is the router's reevaluateListenable.
  // Tap 'Log In', which logs in and calls replaceAll([HomeRoute()]) right
  // away. Only HomeRoute should be left, not LoginRoute under it.
  testWidgets(
    'replaceAll right after the reevaluate listenable changes replaces the stack',
    (tester) async {
      await pumpApp(tester);
      expect(router.stack.map((p) => p.name), [_LoginRoute.name]);

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
      expect(find.text('Home Screen'), findsOneWidget);
      expect(router.canPop(), isFalse);
    },
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2172
  // Then log out, which reevaluates the guard, and log in again.
  testWidgets('logging out and in again leaves one page each time', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), [_LoginRoute.name]);

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), [_HomeRoute.name]);
  });
}

class _LoginRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'LoginRoute';
  static PageInfo page(_AuthRepo authRepo) => .new(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: FilledButton(
          onPressed: () {
            authRepo.login();
            unawaited(context.router.replaceAll([const _HomeRoute()]));
          },
          child: const Text('Log In'),
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
      body: Column(
        children: [
          const Text('Home Screen'),
          FilledButton(
            onPressed: authRepo.logOut,
            child: const Text('Log Out'),
          ),
        ],
      ),
    ),
  );
}
