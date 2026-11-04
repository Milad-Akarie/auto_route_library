import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
  // https://github.com/Milad-Akarie/auto_route_library/issues/2178
  // The reporter's app on auto_route 10.0.1, with reevaluateListenable set to
  // the login notifier. ProfileRoute is guarded by LoginGuard, which calls
  // redirectUntil(SignInRoute) when logged out; the paywall is guarded by a
  // subscription guard and LoginGuard. Steps: open the paywall, log in, go
  // back, open the profile, log out, go back from the sign-in page, open the
  // paywall again, log in.
  // On 10.0.0, as on 10.0.1, the last login opened ProfileRoute, not the paywall: the
  // guard of the profile, whose redirect the back button had closed, was
  // still waiting and resumed. On dev it opens the paywall.
  testWidgets('Logging in after leaving an earlier redirect opens the route that redirected last (#2178)', (
    tester,
  ) async {
    final n = GuardChangeNotifier();
    final login = AutoRouteGuard.simple((resolver, router) {
      if (n.connected) {
        resolver.nextOrBack();
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
                  onPressed: () => context.router.push(const NamedRoute('SubscriptionPaywallRoute')),
                  child: const Text('Click to open Subscription Paywall Page'),
                ),
                ElevatedButton(
                  onPressed: () => context.router.push(const NamedRoute('ProfileRoute')),
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
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config(reevaluateListenable: n)));
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
