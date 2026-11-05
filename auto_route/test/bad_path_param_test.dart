import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: _BookRoute.page, path: '/book/:id'),
        AutoRoute(page: _PriceRoute.page, path: '/price/:amount'),
        AutoRoute(page: _SearchRoute.page, path: '/search'),
        AutoRoute(page: SecondRoute.page, path: '*'),
      ],
    );
  });

  Matcher invalidParam(String type, String key, String value) =>
      isA<FlutterError>().having(
        (e) => e.toString(),
        'message',
        allOf(
          contains('Missing or invalid required parameter'),
          contains('Failed to parse [$type] $key value from $value'),
        ),
      );

  // flutter/flutter#155598: a typed url param given text of another type, as
  // '/book/abc' for an int id, threw a FormatException deep in the build that
  // the app could not handle. A route matches by its path alone, so the url
  // reaches the page; a required param it can't parse fails the navigation
  // with an error naming the param and the value, which the caller can catch,
  // and the page under it stays.
  testWidgets(
    'A required int path param given text fails with its name and value',
    (tester) async {
      await pumpRouterApp(tester, router);
      await expectLater(
        () => router.navigatePath('/book/abc'),
        throwsA(invalidParam('int', 'id', 'abc')),
      );
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);

      unawaited(router.navigatePath('/book/5'));
      await tester.pumpAndSettle();
      expect(find.text('Book 5'), findsOneWidget);
    },
  );

  // flutter/flutter#155598: an app catches the error by its type. This file
  // compiles only while auto_route.dart exports MissingRequiredParameterError.
  testWidgets('A bad path param fails with a MissingRequiredParameterError', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    await expectLater(
      () => router.navigatePath('/book/abc'),
      throwsA(isA<MissingRequiredParameterError>()),
    );
  });

  // flutter/flutter#155598, the same for a decimal where an int is expected.
  testWidgets(
    'A required int path param given a decimal fails with its name and value',
    (tester) async {
      await pumpRouterApp(tester, router);
      await expectLater(
        () => router.navigatePath('/book/1.5'),
        throwsA(invalidParam('int', 'id', '1.5')),
      );
    },
  );

  // flutter/flutter#155598, the same for a required double.
  testWidgets(
    'A required double path param given text fails with its name and value',
    (tester) async {
      await pumpRouterApp(tester, router);
      await expectLater(
        () => router.navigatePath('/price/abc'),
        throwsA(invalidParam('double', 'amount', 'abc')),
      );
    },
  );

  // flutter/flutter#155598, the reporter's own case: a nullable int, here a
  // query param, given text. It reads as null and the page opens.
  testWidgets('A nullable int query param given text reads as null', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, initialLink: '/search?n=abc');
    expect(tester.takeException(), isNull);
    expect(find.text('Search null'), findsOneWidget);
  });
}

abstract final class _BookRoute {
  static const String pageName = 'BookRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text('Book ${data.inheritedPathParams.getInt('id')}'),
  );
}

abstract final class _PriceRoute {
  static const String pageName = 'PriceRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) =>
        Text('Price ${data.inheritedPathParams.getDouble('amount')}'),
  );
}

abstract final class _SearchRoute {
  static const String pageName = 'SearchRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text('Search ${data.queryParams.optInt('n') ?? 'null'}'),
  );
}
