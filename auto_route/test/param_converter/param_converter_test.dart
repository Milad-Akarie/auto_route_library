import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import 'user_router.dart';

void main() {
  // #1794: an app keeps its ids in a value class, UserId, and a page takes one
  // as a path param and another as a query param. A ParamConverter on each
  // annotation reads them from the url and writes them back. The router and
  // its page are in user_router.dart, with the router generated next to it.
  testWidgets('A deep link reads path and query params through their converter', (tester) async {
    final router = UserRouter();
    await pumpRouterApp(tester, router, initialLink: '/user/u-7?by=u-3');
    expect(tester.takeException(), isNull);
    expect(router.current.name, UserProfileRoute.name);
    expect(find.text('User 7 by 3'), findsOneWidget);
  });

  testWidgets('Pushing the route writes each param with its converter', (tester) async {
    final router = UserRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(UserProfileRoute(id: const UserId('8'), by: const UserId('2'))));
    await tester.pumpAndSettle();
    expect(find.text('User 8 by 2'), findsOneWidget);
    expect(router.urlState.url, '/user/u-8?by=u-2');
  });

  testWidgets('An optional param the converter refuses reads as null', (tester) async {
    final router = UserRouter();
    await pumpRouterApp(tester, router, initialLink: '/user/u-7?by=nobody');
    expect(tester.takeException(), isNull);
    expect(find.text('User 7 by null'), findsOneWidget);
  });

  testWidgets('A required param the converter refuses fails naming the key and the text', (tester) async {
    final router = UserRouter();
    await pumpRouterApp(tester, router);
    Object? caught;
    try {
      await router.navigatePath('/user/nobody');
      // The error is the one an app catches for a bad path param.
      // ignore: avoid_catching_errors
    } on MissingRequiredParameterError catch (e) {
      caught = e;
    }
    expect(caught?.toString(), contains('Failed to parse [UserId] id value from nobody'));
  });
}
