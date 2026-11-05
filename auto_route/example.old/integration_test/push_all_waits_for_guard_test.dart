import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pushAll completes only once an async guard has decided.
// Found while moving the package to very_good_analysis; no upstream issue.
// Headless test: auto_route/test/guards/push_all_waits_for_guard_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Completer<bool> decision;

  Widget page(String name, {Widget? action}) => Scaffold(
    body: SafeArea(child: Column(children: [Text(name), ?action])),
  );

  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        builder: (_, _) => page(
          'HomeRoute',
          action: Row(
            children: [
              TextButton(
                onPressed: () => decision.complete(true),
                child: const Text('Allow'),
              ),
              TextButton(
                onPressed: () => decision.complete(false),
                child: const Text('Deny'),
              ),
            ],
          ),
        ),
      ),
      NamedRouteDef(
        name: 'ListRoute',
        path: '/list',
        builder: (_, _) => page('ListRoute'),
      ),
      NamedRouteDef(
        name: 'CheckoutRoute',
        path: '/checkout',
        guards: [
          AutoRouteGuardCallback((resolver, _) async {
            if (await decision.future) {
              resolver.next();
            } else {
              resolver.reject();
            }
          }),
        ],
        builder: (_, _) => page('CheckoutRoute'),
      ),
    ],
  );

  // Steps: on HomeRoute, pushAll([ListRoute, CheckoutRoute]). The router draws
  // the new pages only once CheckoutRoute's guard decides, so HomeRoute stays
  // on screen while the guard waits for a tap on its Allow or Deny.
  // Should: the future is still pending before the tap, and completes after
  // it, with CheckoutRoute shown when allowed and not when denied.
  for (final allow in [true, false]) {
    testWidgets(
      'pushAll completes once the guard ${allow ? 'allows' : 'denies'} the routes',
      (tester) async {
        decision = Completer<bool>();
        final router = buildRouter();
        await pumpRouterApp(tester, router);
        var completed = false;
        unawaited(
          router
              .pushAll(const [
                NamedRoute('ListRoute'),
                NamedRoute('CheckoutRoute'),
              ])
              .then((_) => completed = true),
        );
        await tester.pumpAndSettle();
        expect(completed, isFalse);

        expect(find.text('HomeRoute'), findsOneWidget);
        await tester.tap(find.text(allow ? 'Allow' : 'Deny'));
        await tester.pumpAndSettle();
        expect(completed, isTrue);
        expect(
          find.text('CheckoutRoute'),
          allow ? findsOneWidget : findsNothing,
        );
      },
    );
  }
}
