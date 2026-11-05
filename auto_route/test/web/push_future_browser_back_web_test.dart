@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late SimpleRouter router;
  setUp(() async {
    router = SimpleRouter();
    await rewindBrowserHistory();
  });

  // flutter/flutter#153546: the future of an awaited push never completed
  // when the browser's back button closed the page.
  // Push SecondRoute and keep its future, then press the browser's back
  // button: the future completes, with null, and SecondRoute is gone.
  testWidgets("The browser back button completes the closed page's push future", (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    var completions = 0;
    Object? result = 'not completed';
    unawaited(
      router.push<String>(const SecondRoute()).then((value) {
        completions++;
        result = value;
      }),
    );
    await settleBrowser(tester);

    await pressBrowserBack(tester);
    expect(completions, 1);
    expect(result, isNull);
    expectCurrentPage(router, FirstRoute.name);
  });

  // flutter/flutter#128122: rebuilding the stack from a browser entry broke
  // the push futures, which then completed twice or never.
  // Push SecondRoute and keep its future, press the browser's back button,
  // then its forward button, which opens SecondRoute again, and pop it. The
  // first future completes once, with null, from the back button; the pop
  // throws nothing.
  testWidgets('The browser back and forward buttons complete a push future once', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    var completions = 0;
    unawaited(router.push<String>(const SecondRoute()).then((_) => completions++));
    await settleBrowser(tester);

    await pressBrowserBack(tester);
    await pressBrowserForward(tester);
    expectCurrentPage(router, SecondRoute.name);
    router.pop('picked');
    await settleBrowser(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });
}
