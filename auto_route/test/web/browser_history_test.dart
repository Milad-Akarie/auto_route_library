@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

// Checks that the helpers in browser_history.dart connect the app to the real
// browser history, which the other web history tests rely on.
void main() {
  useRealBrowserHistory();

  late SimpleRouter router;
  setUp(() async {
    router = SimpleRouter();
    await rewindBrowserHistory();
  });

  testWidgets('Navigating on web writes one browser entry per page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    expect(browserPath, '/');

    router.navigate(const SecondRoute());
    await settleBrowser(tester);
    expect(browserPath, '/second-route');
    expect(browserSerialCount, start + 1);

    router.navigate(const ThirdRoute());
    await settleBrowser(tester);
    expect(browserPath, '/third-route');
    expect(browserSerialCount, start + 2);
    expect(router.canNavigateBack, isTrue);
  });

  testWidgets('back() and the browser back button on web both move the app back', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    router.navigate(const SecondRoute());
    await settleBrowser(tester);
    router.navigate(const ThirdRoute());
    await settleBrowser(tester);

    await browserMove(tester, router.back);
    expectCurrentPage(router, SecondRoute.name);
    expect(browserSerialCount, start + 1);

    await pressBrowserBack(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/');
    expect(browserSerialCount, start);
  });
}
