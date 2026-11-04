import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

// router.back() twice in a row goes back two pages, and a page pushed after a
// back() gets its own history entry. No upstream issue matches.
//
// Steps: start on FirstRoute, push SecondRoute, push ThirdRoute, then call
// back() twice, or call back() once and push ThirdRoute again.
//
// back() waited for the page it went back to to be popped before it took new
// entries again, so until then canNavigateBack was false and new pages were
// not recorded.
//
// These tests check the native history; on web back() walks the browser's own
// history, which isn't connected in the default headless test setup.
void main() {
  late SimpleRouter router;
  setUp(() {
    router = SimpleRouter();
  });

  Future<void> pushSecondThenThird(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    unawaited(router.push(const ThirdRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.navigationHistory.length, 3);
  }

  testWidgets('Calling back() twice goes back two pages', (tester) async {
    await pushSecondThenThird(tester);

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.navigationHistory.length, 2);
    expect(router.canNavigateBack, isTrue);

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
    expect(router.urlState.url, '/');
    expect(router.canNavigateBack, isFalse);
  }, skip: kIsWeb);

  testWidgets('A page pushed after back() is recorded in the history', (tester) async {
    await pushSecondThenThird(tester);

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);

    unawaited(router.push(const ThirdRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.navigationHistory.length, 3);

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(router.navigationHistory.length, 2);
  }, skip: kIsWeb);
}
