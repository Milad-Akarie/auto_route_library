import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Logging out and back in keeps the guarded home page's state.
// https://github.com/Milad-Akarie/auto_route_library/issues/2338
// Headless test: auto_route/test/reevaluatable_router/reevaluation_listener_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: one guard on HomeRoute (initial) and LoginRoute sends a
  // logged-out user from HomeRoute to LoginRoute with redirectUntil;
  // reevaluateListenable is the auth store. Start logged in, tap Increment
  // three times, tap Log out, then tap Log in.
  // Should: HomeRoute comes back with its counter still at 3.
  testWidgets(
    'Logging out and back in keeps the state of the guarded home page (#2338)',
    (tester) async {
      final authStore = _AuthStore();
      final authGuard = AutoRouteGuard.simple((resolver, router) {
        final isHome = resolver.route.name == _HomePage.routeName;
        if (!isHome || authStore.isLoggedIn) {
          resolver.next();
        } else {
          unawaited(
            resolver.redirectUntil(const PageRouteInfo(_LoginPage.routeName)),
          );
        }
      });
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo(
              _HomePage.routeName,
              builder: (_) => _HomePage(authStore),
            ),
            guards: [authGuard],
          ),
          AutoRoute(
            page: PageInfo(
              _LoginPage.routeName,
              builder: (_) => _LoginPage(authStore),
            ),
            guards: [authGuard],
          ),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: authStore);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Increment'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Counter 3'), findsOneWidget);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(router.topRoute.name, _LoginPage.routeName);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(router.topRoute.name, _HomePage.routeName);
      expect(find.text('Counter 3'), findsOneWidget);
    },
  );
}

class _AuthStore extends ChangeNotifier {
  bool isLoggedIn = true;

  void logIn() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    isLoggedIn = false;
    notifyListeners();
  }
}

class _HomePage extends StatefulWidget {
  const new(this.authStore);
  static const routeName = 'HomeRoute';

  final _AuthStore authStore;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('Counter $counter'),
            TextButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            TextButton(
              onPressed: widget.authStore.logOut,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPage extends StatelessWidget {
  const new(this.authStore);
  static const routeName = 'LoginRoute';

  final _AuthStore authStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: authStore.logIn,
          child: const Text('Log in'),
        ),
      ),
    );
  }
}
