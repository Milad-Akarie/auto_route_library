import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2331
// The reporter's app: RouteA, the first page, has a guard that calls
// redirectUntil(RouteARedirected(next: resolver.next)), and that page calls
// next() after its first frame. RouteA's button replaces it with RouteC, whose
// guard calls redirectUntil(RouteCRedirected), and that page's 'Go back' button
// calls resolver.nextOrBack(false).
// Tapping 'Go back' failed the assertion '!isResolved': when the redirect page
// was removed, the url of the empty stack used up the replace mark meant for
// RouteA, so RouteARedirected stayed in the history behind RouteA. back() then
// reopened it with the resolver.next of the first navigation, already called.
// A resolved redirect must leave no history entry: back() lands on RouteA.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'RouteA',
        initial: true,
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            unawaited(resolver.redirectUntil(NamedRoute('RouteARedirected', args: resolver.next)));
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
          final next = data.args! as VoidCallback;
          WidgetsBinding.instance.addPostFrameCallback((_) => next());
          return const Scaffold(body: Center(child: Text('PageARedirected')));
        },
      ),
      NamedRouteDef(
        name: 'RouteC',
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            unawaited(resolver.redirectUntil(NamedRoute('RouteCRedirected', args: () => resolver.nextOrBack(false))));
          }),
        ],
        builder: (_, _) => const Scaffold(body: Center(child: Text('Page C'))),
      ),
      NamedRouteDef(
        name: 'RouteCRedirected',
        builder: (_, data) => Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: data.args! as VoidCallback, child: const Text('Go back')),
          ),
        ),
      ),
    ],
  );

  testWidgets('A resolved redirect leaves no history entry for back() to return to (#2331)', (tester) async {
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    expect(router.stack.map((e) => e.routeData.name), ['RouteA']);
    // The redirect page left no entry behind, so there is nothing to go back to.
    expect(router.canNavigateBack, isFalse);

    await tester.tap(find.text('Go to Page C (replace)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Go to Page C (replace)'), findsOneWidget);
    expect(router.canNavigateBack, isFalse);

    // A second back() has nowhere to go, rather than reopening RouteARedirected.
    router.back();
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.routeData.name), ['RouteA']);
    expect(find.text('Go to Page C (replace)'), findsOneWidget);
  }, skip: kIsWeb); // on web, back() moves the browser's own history; see test/web/redirect_history_web_test.dart
}
