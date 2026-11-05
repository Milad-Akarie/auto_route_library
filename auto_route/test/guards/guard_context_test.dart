import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1707
// A guard reads an app-wide value, such as a provider's access token, through
// the context of the navigator. Steps: show the app, then push a page whose
// guard reads an inherited widget above MaterialApp.router with
// resolver.context. The guard should get a context and the value; it used to
// fail with "Unexpected null value" when it asked the navigator key.
void main() {
  testWidgets('A guard reads an inherited value from its resolver context', (tester) async {
    String? token;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(
          page: SecondRoute.page,
          path: '/second',
          guards: [
            AutoRouteGuard.simple((resolver, guardedRouter) {
              token = resolver.context.getInheritedWidgetOfExactType<_Token>()?.value;
              resolver.next();
            }),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _Token(
        value: 'abc',
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();

    expect(token, 'abc');
    expectTopPage(router, SecondRoute.name);
  });
}

class _Token extends InheritedWidget {
  const _Token({required this.value, required super.child});

  final String value;

  @override
  bool updateShouldNotify(_Token oldWidget) => value != oldWidget.value;
}
