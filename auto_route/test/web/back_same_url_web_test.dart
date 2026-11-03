@TestOn('browser')
library;

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
      ],
    );
    await rewindBrowserHistory();
  });

  Future<void> pushTwoBooks(WidgetTester tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    router.push(_BookRoute(bookId: 'some-id'));
    await settleBrowser(tester);
    router.push(_BookRoute(bookId: 'some-id-2'));
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
    testWidgets('Going back on web with $how returns to a page with the same url', (tester) async {
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
    });
  }

  // Popping the second Book in the app returns the browser to the first Book's
  // entry, so the browser's back button then goes to Home, not to the first
  // Book again.
  testWidgets('Popping a page with the same url as the one under it steps the browser back to its entry',
      (tester) async {
    await pushTwoBooks(tester);

    router.maybePop();
    await settleBrowser(tester);
    expect(find.text('Book some-id'), findsOneWidget);
    expect(browserSerialCount, 1);

    await pressBrowserBack(tester);
    expect(router.current.name, FirstRoute.name);
    expect(browserPath, '/');
  });

  // navigate() to the page on top with other arguments replaces it in place,
  // so it keeps the one browser entry.
  testWidgets('navigate() to the page on top with other arguments adds no browser entry', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    router.navigate(_BookRoute(bookId: 'some-id'));
    await settleBrowser(tester);
    router.navigate(_BookRoute(bookId: 'some-id-2'));
    await settleBrowser(tester);
    expect(find.text('Book some-id-2'), findsOneWidget);
    expect(router.stack.length, 2);
    expect(browserSerialCount, 1);
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
    builder: (data) => Scaffold(body: Text('Book ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId}')),
  );
}
