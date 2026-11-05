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
        AutoRoute(page: _ChapterRoute.page, path: '/chapter'),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1864
  // Push Page1 with the optional argument bookId 'some-id', push Page2 with
  // bookId 'some-id-2', then go back to Page1, by the browser's back button and
  // by back(). Page1 should show 'some-id' again, not a null bookId.
  for (final (how, goBack) in [
    ('the browser back button', pressBrowserBack),
    ('back()', (WidgetTester tester) => browserMove(tester, router.back)),
  ]) {
    testWidgets(
      'Going back on web with $how keeps the optional argument of the page '
      'underneath',
      (tester) async {
        await pumpRouterConfigApp(tester, router.config());
        await settleBrowser(tester);
        unawaited(router.push(_BookRoute(bookId: 'some-id')));
        await settleBrowser(tester);
        expect(find.text('Book some-id'), findsOneWidget);
        unawaited(router.push(_ChapterRoute(bookId: 'some-id-2')));
        await settleBrowser(tester);
        expect(find.text('Chapter some-id-2'), findsOneWidget);

        await goBack(tester);
        expect(router.current.name, _BookRoute.name);
        expect(
          find.text('Book some-id'),
          findsOneWidget,
          reason: 'after goBack(tester)',
        );
        expect(browserPath, '/book');
      },
    );
  }
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
    builder: (data) => Scaffold(body: Text('Book ${_bookIdOf(data)}')),
  );
}

class _ChapterRoute extends PageRouteInfo<_BookArgs> {
  new({required String bookId}) : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'ChapterRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(body: Text('Chapter ${_bookIdOf(data)}')),
  );
}

String _bookIdOf(RouteData<Object?> data) =>
    data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId ?? 'null';
