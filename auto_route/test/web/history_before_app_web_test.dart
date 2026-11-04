@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' show window;

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

// The tab holds pages from before the app, as it does when a user follows a
// link to the app from another site. The navigation history should count and
// walk only the app's own pages.
void main() {
  for (var i = 1; i <= 3; i++) {
    window.history.pushState(null, '', '#/before-$i');
  }
  // The entry the app starts on; the setup below sets its url to '/'.
  window.history.pushState(null, '', '#/');
  useRealBrowserHistory();

  late SimpleRouter router;
  setUp(() async {
    router = SimpleRouter();
    await rewindBrowserHistory();
  });

  // Steps: open the app in a tab with three earlier pages, then navigate to
  // SecondRoute.
  // Should: the history's length is 1, then 2, whatever the tab held before.
  testWidgets('On web, the history counts only the pages of the app', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    expect(router.navigationHistory.length, 1);
    expect(router.canNavigateBack, isFalse);

    router.navigate(const SecondRoute());
    await settleBrowser(tester);
    expect(router.navigationHistory.length, 2);
    expect(router.canNavigateBack, isTrue);
  });

  // Steps: open the app in a tab with three earlier pages, then call back()
  // on the app's first page.
  // Should: the browser stays on the app, as the history's doc promises when
  // there is nothing to go back to; a guard's nextOrBack(false) relies on it.
  testWidgets('On web, back() on the first page of the app does not leave it', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);

    expect(_countBrowserBackCalls(router.back), 0);
    await settleBrowser(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/');
  });
}

/// Runs [body] with the browser's `history.back()` replaced by a counter and
/// returns how often [body] called it.
///
/// The replacement keeps the browser where it is, so the test page never
/// navigates to one of the pages from before the app.
int _countBrowserBackCalls(void Function() body) {
  final history = window.history;
  var calls = 0;
  history['back'] = () {
    calls++;
  }.toJS;
  try {
    body();
  } finally {
    history.delete('back'.toJS);
  }
  return calls;
}
