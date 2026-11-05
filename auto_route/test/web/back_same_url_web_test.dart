@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _BookRoute.page, path: '/book'),
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );
    await rewindBrowserHistory();
  });

  Future<void> pushTwoBooks(WidgetTester tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(_BookRoute(bookId: 'some-id')));
    await settleBrowser(tester);
    unawaited(router.push(_BookRoute(bookId: 'some-id-2')));
    await settleBrowser(tester);
    expect(find.text('Book some-id-2'), findsOneWidget);
  }

  // Found while guarding https://github.com/Milad-Akarie/auto_route_library/issues/1864
  // Push Book with the optional argument bookId 'some-id', push Book again
  // with bookId 'some-id-2', then go back, by back() and by the browser's back
  // button. The second Book has the same url as the first, so the router
  // reported it as a replace of the first Book's browser entry, and going back
  // left both Books for Home.
  for (final (how, goBack) in [
    ('the browser back button', pressBrowserBack),
    ('back()', (WidgetTester tester) => browserMove(tester, router.back)),
  ]) {
    testWidgets(
      'Going back on web with $how returns to a page with the same url',
      (tester) async {
        await pushTwoBooks(tester);
        expect(browserSerialCount, 2);

        await goBack(tester);
        expect(router.current.name, _BookRoute.name);
        expect(find.text('Book some-id'), findsOneWidget);
        expect(router.stack.length, 2);
        expect(browserPath, '/book');
        expect(browserSerialCount, 1);

        await goBack(tester);
        expect(router.current.name, FirstRoute.name);
        expect(router.stack.length, 1);
        expect(browserPath, '/');
      },
    );
  }

  // Popping the second Book in the app returns the browser to the first Book's
  // entry, so the browser's back button then goes to Home, not to the first
  // Book again.
  testWidgets(
    'Popping a page with the same url as the one under it steps the browser back to its entry',
    (tester) async {
      await pushTwoBooks(tester);

      unawaited(router.maybePop());
      await settleBrowser(tester);
      expect(find.text('Book some-id'), findsOneWidget);
      expect(browserSerialCount, 1);

      await pressBrowserBack(tester);
      expect(router.current.name, FirstRoute.name);
      expect(browserPath, '/');
    },
  );

  // After going back from the second Book to the first, the browser's forward
  // button puts the second Book back on top of the first. The first Book used
  // to take the second one's arguments in place, so back() then left for Home.
  testWidgets(
    'The browser forward button returns to a page pushed over one with the same url',
    (tester) async {
      await pushTwoBooks(tester);
      await pressBrowserBack(tester);
      expect(find.text('Book some-id'), findsOneWidget);

      await pressBrowserForward(tester);
      expect(find.text('Book some-id-2'), findsOneWidget);
      expect(router.stack.length, 3);
      expect(browserSerialCount, 2);

      await browserMove(tester, router.back);
      expect(
        find.text('Book some-id'),
        findsOneWidget,
        reason: 'after browserMove(tester, router.back)',
      );
      expect(router.stack.length, 2);
    },
  );

  // Pushing a route without arguments twice gives the second page a browser
  // entry of its own too, although the two pages' routes compare equal.
  testWidgets(
    'Going back on web returns to the same route pushed with equal arguments',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.push(const SecondRoute()));
      await settleBrowser(tester);
      unawaited(router.push(const SecondRoute()));
      await settleBrowser(tester);
      expect(router.stack.length, 3);
      expect(browserSerialCount, 2);

      await pressBrowserBack(tester);
      expect(router.current.name, SecondRoute.name);
      expect(router.stack.length, 2);
      expect(browserPath, '/second');
    },
  );

  // navigate() to the page on top with other arguments replaces it in place,
  // so it keeps the one browser entry.
  testWidgets(
    'navigate() to the page on top with other arguments adds no browser entry',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.navigate(_BookRoute(bookId: 'some-id')));
      await settleBrowser(tester);
      unawaited(router.navigate(_BookRoute(bookId: 'some-id-2')));
      await settleBrowser(tester);
      expect(find.text('Book some-id-2'), findsOneWidget);
      expect(router.stack.length, 2);
      expect(browserSerialCount, 1);
    },
  );
}

class _BookArgs {
  const new({this.bookId});

  final String? bookId;
}

class _BookRoute extends PageRouteInfo<_BookArgs> {
  new({required String bookId}) : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'BookRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(
      body: Text(
        'Book ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId ?? 'null'}',
      ),
    ),
  );
}
