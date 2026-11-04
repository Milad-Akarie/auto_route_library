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
}
