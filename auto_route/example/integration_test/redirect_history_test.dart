import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A guard's redirect page leaves no history entry once the guard resolves.
// https://github.com/Milad-Akarie/auto_route_library/issues/2331
// Headless test: auto_route/test/guards/redirect_history_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RootStackRouter buildRouter() => RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'RouteA',
        initial: true,
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            resolver.redirectUntil(NamedRoute('RouteARedirected', args: resolver.next));
          }),
        ],
        builder: (context, _) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.router.replace(const NamedRoute('RouteC')),
              child: const Text('Go to Page C (replace)'),
            ),
          ),
        ),
      ),
      NamedRouteDef(
        name: 'RouteARedirected',
        builder: (_, data) {
          final next = data.args as VoidCallback;
          WidgetsBinding.instance.addPostFrameCallback((_) => next());
          return const Scaffold(body: Center(child: Text('PageARedirected')));
        },
      ),
      NamedRouteDef(
        name: 'RouteC',
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            resolver.redirectUntil(NamedRoute('RouteCRedirected', args: () => resolver.nextOrBack(false)));
          }),
        ],
        builder: (_, _) => const Scaffold(body: Center(child: Text('Page C'))),
      ),
      NamedRouteDef(
        name: 'RouteCRedirected',
        builder: (_, data) => Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: data.args as VoidCallback, child: const Text('Go back')),
          ),
        ),
      ),
    ],
  );

  // Steps, the reporter's: the app opens on RouteA, whose guard redirects to
  // RouteARedirected until that page calls next(); tap 'Go to Page C (replace)',
  // whose guard redirects to RouteCRedirected; tap 'Go back', which calls
  // nextOrBack(false); then call back() once more.
  // Should: the app is back on RouteA, and back() has nothing to return to
  // instead of reopening RouteARedirected with a resolver already used.
  testWidgets(
    'A resolved redirect leaves no history entry for back() to return to (#2331)',
    (tester) async {
      final router = buildRouter();
      await pumpRouterAppWithConfig(tester, router);
      expect(router.stack.map((e) => e.routeData.name), ['RouteA']);
      expect(router.canNavigateBack, isFalse);

      await tester.tap(find.text('Go to Page C (replace)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('Go to Page C (replace)'), findsOneWidget);
      expect(router.canNavigateBack, isFalse);

      router.back();
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.routeData.name), ['RouteA']);
      expect(find.text('Go to Page C (replace)'), findsOneWidget);
    },
    skip: kIsWeb,
  ); // on web, back() moves the browser's own history; see auto_route/test/web/redirect_history_web_test.dart
}
