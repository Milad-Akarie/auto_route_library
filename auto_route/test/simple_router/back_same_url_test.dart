import 'dart:async';

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
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );
  });

  // Found while guarding https://github.com/Milad-Akarie/auto_route_library/issues/1864
  // Push Book with the optional argument bookId 'some-id', push Book again
  // with bookId 'some-id-2', then call back(). The native history dropped the
  // second Book's entry because its url equals the first's, so back() went
  // straight to Home. On web, back() moves the browser's own history.
  testWidgets('back() returns to a page with the same url as the current one', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(_BookRoute(bookId: 'some-id')));
    await tester.pumpAndSettle();
    unawaited(router.push(_BookRoute(bookId: 'some-id-2')));
    await tester.pumpAndSettle();
    expect(find.text('Book some-id-2'), findsOneWidget);
    expect(router.navigationHistory.length, 3);

    router.back();
    await tester.pumpAndSettle();
    expect(find.text('Book some-id'), findsOneWidget);
    expect(router.stack.length, 2);
    expect(router.urlState.url, '/book');
  }, skip: kIsWeb);

  // Push a route without arguments twice, then call back(). The two pages'
  // routes compare equal, so the url was never rebuilt for the second page,
  // which got no history entry, and back() went straight to Home.
  testWidgets('back() returns to the same route pushed with equal arguments', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expect(router.stack.length, 3);
    expect(router.navigationHistory.length, 3);

    router.back();
    await tester.pumpAndSettle();
    expect(router.current.name, SecondRoute.name);
    expect(router.stack.length, 2);
  }, skip: kIsWeb);

  // navigate() to the page on top with other arguments replaces that page in
  // place, so there is no page under it to return to: back() goes to the page
  // before, like maybePop().
  testWidgets('back() after navigate() replaced a page in place goes to the page before', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigate(_BookRoute(bookId: 'some-id')));
    await tester.pumpAndSettle();
    unawaited(router.navigate(_BookRoute(bookId: 'some-id-2')));
    await tester.pumpAndSettle();
    expect(find.text('Book some-id-2'), findsOneWidget);
    expect(router.stack.length, 2);
    expect(router.navigationHistory.length, 2);

    router.back();
    await tester.pumpAndSettle();
    expect(router.current.name, FirstRoute.name);
    expect(router.stack.length, 1);
  }, skip: kIsWeb);

  // Rebuilding the url of the page on top adds no entry.
  testWidgets('Rebuilding the url of the same page adds no history entry', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(_BookRoute(bookId: 'some-id')));
    await tester.pumpAndSettle();
    router.navigationHistory.rebuildUrl();
    await tester.pumpAndSettle();
    expect(router.navigationHistory.length, 2);
  }, skip: kIsWeb);
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
    builder: (data) =>
        Scaffold(body: Text('Book ${data.argsAs<_BookArgs>(orElse: () => const _BookArgs()).bookId ?? 'null'}')),
  );
}
