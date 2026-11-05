import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back returns to a page with the same url as the current one.
// Found while guarding
// https://github.com/Milad-Akarie/auto_route_library/issues/1864
// Headless tests: auto_route/test/simple_router/back_same_url_test.dart
// (native) and auto_route/test/web/back_same_url_web_test.dart (web).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('back same url', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/'),
          AutoRoute(page: _BookRoute.page, path: '/book'),
        ],
      );
    });

    Future<void> pushTwoBooks(WidgetTester tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(_BookRoute(bookId: 'some-id')));
      await tester.pumpAndSettle();
      unawaited(router.push(_BookRoute(bookId: 'some-id-2')));
      await tester.pumpAndSettle();
      expect(find.text('Book some-id-2'), findsOneWidget);
      await expectBrowserUrl('/book');
    }

    // Steps: push Book with bookId 'some-id', push Book again with bookId
    // 'some-id-2', then call back().
    // Should: the first Book, 'some-id', not Home. On web the second Book has a
    // browser entry of its own, and back() steps back from it.
    testWidgets(
      'back() returns to a page with the same url as the current one',
      (tester) async {
        await pushTwoBooks(tester);
        final secondBookEntry = browserEntryIndex();

        router.back();
        if (kIsWeb) await expectBrowserEntry(secondBookEntry! - 1);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(router.current.name, _BookRoute.name);
        expect(find.text('Book some-id'), findsOneWidget);
        await expectBrowserUrl('/book');
      },
    );

    // Steps: the same, going back with the browser's back button on
    // web, system back elsewhere.
    // Should: the first Book, 'some-id', not Home.
    testWidgets(
      'Going back returns to a page with the same url as the current one',
      (tester) async {
        await pushTwoBooks(tester);
        final secondBookEntry = browserEntryIndex();

        if (kIsWeb) {
          pressBrowserBack();
          await expectBrowserEntry(secondBookEntry! - 1);
          await tester.pumpAndSettle();
        } else {
          await systemBack(tester);
        }
        expect(tester.takeException(), isNull);
        expect(router.current.name, _BookRoute.name);
        expect(find.text('Book some-id'), findsOneWidget);
        await expectBrowserUrl('/book');
      },
    );

    // Steps: push Book with bookId 'some-id', push Book again with bookId
    // 'some-id-2', press the browser's back button, then its forward button.
    // Should: the second Book, 'some-id-2', back on top of the first.
    // Web only: only the browser has a forward button.
    testWidgets(
      'The browser forward button returns to a page pushed over one with the '
      'same url',
      (tester) async {
        await pushTwoBooks(tester);
        final secondBookEntry = browserEntryIndex()!;
        pressBrowserBack();
        await expectBrowserEntry(secondBookEntry - 1);
        await tester.pumpAndSettle();
        expect(find.text('Book some-id'), findsOneWidget);

        pressBrowserForward();
        await expectBrowserEntry(secondBookEntry);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Book some-id-2'), findsOneWidget);
        expect(router.stack.length, 3);
        await expectBrowserUrl('/book');
      },
      skip: !kIsWeb,
    );
  });
}

class _BookArgs {
  const new({this.bookId});

  final String? bookId;
}

class _BookRoute extends PageRouteInfo<_BookArgs> {
  new({String? bookId}) : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'BookRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_BookArgs>(orElse: () => const _BookArgs());
      return Scaffold(body: Text('Book ${args.bookId ?? 'null'}'));
    },
  );
}
