import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// A guard whose redirect page was closed doesn't resume a later navigation.
// https://github.com/Milad-Akarie/auto_route_library/issues/2178
// Headless test: auto_route/test/reevaluatable_router/redirect_lifecycle_test.dart
/// The reporter's notifier of the login and subscription state.
class GuardChangeNotifier extends ChangeNotifier {
  bool connected = false;
  bool hasProSubscription = false;
  void connect() {
    connected = true;
    notifyListeners();
  }

  void disconnect() {
    connected = false;
    notifyListeners();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps, the reporter's: open the paywall, log in, go back, open the
  // profile, log out, go back from the sign-in page, open the paywall again,
  // log in.
  // Should: the paywall opens, not the profile.
  testWidgets('Logging in after leaving an earlier redirect opens the route that redirected last (#2178)', (
    tester,
  ) async {
    final n = GuardChangeNotifier();
    final login = AutoRouteGuard.simple((resolver, router) {
      if (n.connected) {
        resolver.nextOrBack(true);
      } else {
        resolver.redirectUntil(const NamedRoute('SignInRoute'));
      }
    });
    final anonymous = AutoRouteGuard.simple((resolver, router) => resolver.nextOrBack(!n.connected));
    final noPro = AutoRouteGuard.simple((resolver, router) => resolver.nextOrBack(!n.hasProSubscription));
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: const Text('Home Page')),
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => unawaited(context.router.push(const NamedRoute('SubscriptionPaywallRoute'))),
                  child: const Text('Click to open Subscription Paywall Page'),
                ),
                ElevatedButton(
                  onPressed: () => unawaited(context.router.push(const NamedRoute('ProfileRoute'))),
                  child: const Text('Click to open Profile Page'),
                ),
              ],
            ),
          ),
        ),
        NamedRouteDef(
          name: 'ProfileRoute',
          path: '/profile',
          guards: [login],
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('Profile Page')),
            body: ElevatedButton(onPressed: n.disconnect, child: const Text('Click to logout')),
          ),
        ),
        NamedRouteDef(
          name: 'SignInRoute',
          path: '/signin',
          guards: [anonymous],
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('SignIn Page')),
            body: ElevatedButton(onPressed: n.connect, child: const Text('Click to login')),
          ),
        ),
        NamedRouteDef(
          name: 'SubscriptionPaywallRoute',
          path: '/paywall',
          guards: [noPro, login],
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('Subscription Paywall Page')),
            body: const Text('paywall body'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config(
          reevaluateListenable: n,
          // on web the browser's url would otherwise carry over from the previous test
          deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/') : link,
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String t) async {
      await tester.tap(find.text(t));
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    List<String> stack() => router.stack.map((e) => e.routeData.name).toList();

    expect(find.text('Home Page'), findsOneWidget);
    await tap('Click to open Subscription Paywall Page');
    expect(find.text('SignIn Page'), findsOneWidget);
    await tap('Click to login');
    expect(stack(), ['HomeRoute', 'SubscriptionPaywallRoute']);
    await back();
    expect(stack(), ['HomeRoute']);
    await tap('Click to open Profile Page');
    expect(find.text('Profile Page'), findsOneWidget);
    await tap('Click to logout');
    expect(find.text('SignIn Page'), findsOneWidget);
    await back();
    expect(stack(), ['HomeRoute']);
    await tap('Click to open Subscription Paywall Page');
    expect(find.text('SignIn Page'), findsOneWidget);
    await tap('Click to login');

    expect(stack(), ['HomeRoute', 'SubscriptionPaywallRoute']);
    expect(find.text('Subscription Paywall Page'), findsOneWidget);
  });
}
