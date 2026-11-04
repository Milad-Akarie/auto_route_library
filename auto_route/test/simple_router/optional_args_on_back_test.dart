import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';

void main() {
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

  // https://github.com/Milad-Akarie/auto_route_library/issues/1864
  // Push Page1 with the optional argument bookId 'some-id', push Page2 with
  // bookId 'some-id-2', then go back to Page1. Page1 should show 'some-id'
  // again, not a null bookId. test/web/optional_args_on_back_web_test.dart
  // covers the browser's back button on web.
  for (final (how, goBack, skip) in [
    ('back()', () => router.back(), kIsWeb), // on web, back() moves the browser's own history
    ('maybePop()', () => router.maybePop(), false),
  ]) {
    testWidgets('Going back with $how keeps the optional argument of the page underneath', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      router.push(_BookRoute(bookId: 'some-id'));
      await tester.pumpAndSettle();
      expect(find.text('Book some-id'), findsOneWidget);
      router.push(_ChapterRoute(bookId: 'some-id-2'));
      await tester.pumpAndSettle();
      expect(find.text('Chapter some-id-2'), findsOneWidget);

      goBack();
      await tester.pumpAndSettle();
      expect(router.current.name, _BookRoute.name);
      expect(find.text('Book some-id'), findsOneWidget);
      expect(router.urlState.url, '/book');
    }, skip: skip);
  }
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

class _ChapterRoute extends PageRouteInfo<_BookArgs> {
  _ChapterRoute({String? bookId}) : super(name, args: _BookArgs(bookId: bookId));

  static const String name = 'ChapterRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) =>
        Scaffold(body: Text('Chapter ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId}')),
  );
}
