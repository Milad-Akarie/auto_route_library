import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

void main() {
  late SimpleRouter router;
  setUp(() {
    router = SimpleRouter();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1839
  // Start on FirstRoute, navigate to SecondRoute, navigate to ThirdRoute,
  // pop from ThirdRoute, then call back() from SecondRoute.
  // back() should land on FirstRoute, not on the ThirdRoute that was popped.
  testWidgets('Popping then going back should not return to the popped page', (tester) async {
    await pumpRouterApp(tester, router);
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
    expect(router.urlState.url, '/');

    router.navigate(const SecondRoute());
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(router.navigationHistory.length, 2);
    expect(router.urlState.url, '/second-route');

    router.navigate(const ThirdRoute());
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name, ThirdRoute.name]);
    expect(router.navigationHistory.length, 3);
    expect(router.urlState.url, '/third-route');

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(router.navigationHistory.length, 2);
    expect(router.urlState.url, '/second-route');

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
    expect(router.urlState.url, '/');
    expect(router.canNavigateBack, isFalse);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1839
  // pushAll records only the last page, so after popping it the page now on top
  // has no history entry yet; it must take the popped page's entry, not follow it.
  testWidgets('Popping a page pushed with pushAll then going back should not return to it', (tester) async {
    await pumpRouterApp(tester, router);
    router.pushAll([const SecondRoute(), const ThirdRoute()]);
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.navigationHistory.length, 2);

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.navigationHistory.length, 2);
    expect(router.urlState.url, '/second-route');

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
  });
}
