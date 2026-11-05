import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back to a page keeps its optional argument.
// https://github.com/Milad-Akarie/auto_route_library/issues/1864
// Headless tests: auto_route/test/simple_router/optional_args_on_back_test.dart
// (native) and auto_route/test/web/optional_args_on_back_web_test.dart (web).
//
// On web the page comes back from the browser's history, which the fix for
// #1842 made keep each page's arguments; elsewhere it stays in the stack.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _BookRoute.page, path: '/book'),
        AutoRoute(page: _ChapterRoute.page, path: '/chapter'),
      ],
    );
  });

  // Steps: push Page1 with bookId 'some-id', push Page2 with bookId
  // 'some-id-2', then go back: the browser's back button on web, system back
  // elsewhere.
  // Should: Page1 shows 'some-id' again, not a null bookId.
  testWidgets('Going back keeps the optional argument of the page underneath', (
    tester,
  ) async {
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(_BookRoute(bookId: 'some-id')));
    await tester.pumpAndSettle();
    expect(find.text('Book some-id'), findsOneWidget);
    unawaited(router.push(_ChapterRoute(bookId: 'some-id-2')));
    await tester.pumpAndSettle();
    expect(find.text('Chapter some-id-2'), findsOneWidget);
    await expectBrowserUrl('/chapter');

    if (kIsWeb) {
      pressBrowserBack();
      await expectBrowserUrl('/book');
      await tester.pumpAndSettle();
    } else {
      await systemBack(tester);
    }
    expect(tester.takeException(), isNull);
    expect(router.current.name, _BookRoute.name);
    expect(find.text('Book some-id'), findsOneWidget);
  });

  // Steps: the same, going back with back().
  // Should: Page1 shows 'some-id' again.
  testWidgets('back() keeps the optional argument of the page underneath', (
    tester,
  ) async {
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(_BookRoute(bookId: 'some-id')));
    await tester.pumpAndSettle();
    unawaited(router.push(_ChapterRoute(bookId: 'some-id-2')));
    await tester.pumpAndSettle();
    await expectBrowserUrl('/chapter');

    router.back();
    await expectBrowserUrl('/book');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.current.name, _BookRoute.name);
    expect(find.text('Book some-id'), findsOneWidget);
  });
}

class _BookArgs {
  const _BookArgs({this.bookId});

  final String? bookId;
}

class _BookRoute extends PageRouteInfo<_BookArgs> {
  _BookRoute({String? bookId}) : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'BookRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(
      body: Text(
        'Book ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId}',
      ),
    ),
  );
}

class _ChapterRoute extends PageRouteInfo<_BookArgs> {
  _ChapterRoute({String? bookId})
    : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'ChapterRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(
      body: Text(
        'Chapter ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId}',
      ),
    ),
  );
}
