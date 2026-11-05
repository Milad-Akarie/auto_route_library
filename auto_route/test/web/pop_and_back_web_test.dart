@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show WindowEventGetters, window;

import '../main_router.dart';
import '../nested_router/router.dart';
import '../nested_tabs_router/router.dart';
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

  // https://github.com/Milad-Akarie/auto_route_library/issues/1839
  // Start on FirstRoute, navigate to SecondRoute, navigate to ThirdRoute,
  // pop from ThirdRoute, then call back() from SecondRoute.
  // back() should land on FirstRoute, and so should the browser's back step,
  // not on the ThirdRoute that was popped.
  testWidgets(
    'Popping then going back on web should not return to the popped page',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;

      unawaited(router.navigate(const SecondRoute()));
      await settleBrowser(tester);
      unawaited(router.navigate(const ThirdRoute()));
      await settleBrowser(tester);
      expectCurrentPage(router, ThirdRoute.name);
      expect(browserSerialCount, start + 2);

      router.pop();
      await settleBrowser(tester);
      expectCurrentPage(router, SecondRoute.name);
      expect(browserPath, '/second-route');
      expect(browserSerialCount, start + 1);

      await browserMove(tester, router.back);
      expectCurrentPage(router, FirstRoute.name);
      expect(browserPath, '/');
      expect(browserSerialCount, start);
    },
  );

  // pushAll records only the last page, so the entry before the popped one
  // belongs to FirstRoute; SecondRoute must take the popped page's entry.
  testWidgets('Popping a page pushed with pushAll on web replaces its entry', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;

    unawaited(router.pushAll([const SecondRoute(), const ThirdRoute()]));
    await settleBrowser(tester);
    expect(browserSerialCount, start + 1);

    router.pop();
    await settleBrowser(tester);
    expectCurrentPage(router, SecondRoute.name);
    expect(browserPath, '/second-route');
    expect(
      browserSerialCount,
      start + 1,
      reason: 'after settleBrowser(tester)',
    );

    await pressBrowserBack(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserSerialCount, start);
  });

  testWidgets(
    'Popping with a result on web still delivers it to the awaiting push',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;

      unawaited(router.navigate(const SecondRoute()));
      await settleBrowser(tester);
      String? result;
      unawaited(
        router.push<String>(const ThirdRoute()).then((value) => result = value),
      );
      await settleBrowser(tester);

      router.pop('picked');
      await settleBrowser(tester);
      expect(result, 'picked');
      expectCurrentPage(router, SecondRoute.name);
      expect(browserSerialCount, start + 1);

      await browserMove(tester, router.back);
      expectCurrentPage(router, FirstRoute.name);
    },
  );

  testWidgets(
    'Popping a dialog on web closes only the dialog and leaves the history alone',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;

      unawaited(router.navigate(const SecondRoute()));
      await settleBrowser(tester);
      showDialog<void>(
        context: router.navigatorKey.currentContext!,
        builder: (_) => const Text('Dialog'),
      );
      await settleBrowser(tester);
      expect(find.text('Dialog'), findsOneWidget);

      router.pop();
      await settleBrowser(tester);
      expect(find.text('Dialog'), findsNothing);
      expectCurrentPage(router, SecondRoute.name);
      expect(browserPath, '/second-route');
      expect(browserSerialCount, start + 1);
    },
  );

  testWidgets('A dialog opened right after a pop on web stays open', (
    tester,
  ) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;

    unawaited(router.navigate(const SecondRoute()));
    await settleBrowser(tester);
    unawaited(router.navigate(const ThirdRoute()));
    await settleBrowser(tester);

    // The browser reports the step back to SecondRoute only after this frame.
    router.pop();
    showDialog<void>(
      context: router.navigatorKey.currentContext!,
      builder: (_) => const Text('Dialog'),
    );
    await settleBrowser(tester);
    expect(find.text('Dialog'), findsOneWidget);
    expect(browserPath, '/second-route');
    expect(browserSerialCount, start + 1);
  });

  testWidgets(
    'Popping a page outside the visible url on web leaves the history alone',
    (tester) async {
      final tabsRouter = NestedTabsRouter();
      await pumpRouterConfigApp(tester, tabsRouter.config());
      await settleBrowser(tester);

      unawaited(tabsRouter.navigate(const Tab2Route()));
      await settleBrowser(tester);
      final tab2Router = tabsRouter
          .innerRouterOf<TabsRouter>(TabsHostRoute.name)!
          .stackRouterOfIndex(1)!;
      unawaited(tab2Router.push(const Tab2Nested2Route()));
      await settleBrowser(tester);
      expect(browserPath, '/tab2/tab2Nested2');
      unawaited(tabsRouter.navigate(const Tab1Route()));
      await settleBrowser(tester);
      final serialCount = browserSerialCount;
      expect(browserPath, '/');

      tab2Router.pop();
      await settleBrowser(tester);
      expect(tab2Router.current.name, Tab2Nested1Route.name);
      expect(tabsRouter.urlState.url, '/');
      expect(browserPath, '/', reason: 'after settleBrowser(tester)');
      expect(browserSerialCount, serialCount);
    },
  );

  testWidgets(
    'Popping a nested page then going back on web should not return to it',
    (tester) async {
      final nestedRouter = NestedRouter();
      await pumpRouterConfigApp(tester, nestedRouter.config());
      await settleBrowser(tester);
      final start = browserSerialCount;

      unawaited(nestedRouter.navigate(SecondHostRoute()));
      await settleBrowser(tester);
      final hostRouter = nestedRouter.innerRouterOf<StackRouter>(
        SecondHostRoute.name,
      )!;
      unawaited(hostRouter.push(const SecondNested2Route()));
      await settleBrowser(tester);
      expect(browserPath, '/second/nested2');
      expect(browserSerialCount, start + 2);

      hostRouter.pop();
      await settleBrowser(tester);
      expectTopPage(nestedRouter, SecondNested1Route.name);
      expect(browserPath, '/second');
      expect(browserSerialCount, start + 1);

      await browserMove(tester, nestedRouter.back);
      expectCurrentPage(nestedRouter, FirstRoute.name);
      expect(browserPath, '/');
      expect(browserSerialCount, start);
    },
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2069
  // The same bug seen through the browser's back button: push SecondRoute, push
  // ThirdRoute, maybePop from ThirdRoute, then press the browser's back button.
  // It should go straight to FirstRoute, not through ThirdRoute again.
  testWidgets(
    'maybePop then the browser back button on web goes to the page before',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;
      unawaited(router.push(const SecondRoute()));
      await settleBrowser(tester);
      unawaited(router.push(const ThirdRoute()));
      await settleBrowser(tester);

      await router.maybePop();
      await settleBrowser(tester);
      expectCurrentPage(router, SecondRoute.name);

      await pressBrowserBack(tester);
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(browserSerialCount, start);
    },
  );

  testWidgets(
    'The browser back button pressed right after a pop on web still goes back',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;
      unawaited(router.navigate(const SecondRoute()));
      await settleBrowser(tester);
      unawaited(router.navigate(const ThirdRoute()));
      await settleBrowser(tester);

      // The press lands before the browser reports the pop's own step back.
      final reports = window.onPopState.take(2).toList();
      router.pop();
      window.history.back();
      await reports;
      await settleBrowser(tester);
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(browserPath, '/');
      expect(browserSerialCount, start);
    },
  );

  testWidgets('Popping on web with rebuildStackOnDeepLink keeps the stack', (
    tester,
  ) async {
    await pumpRouterConfigApp(
      tester,
      router.config(rebuildStackOnDeepLink: true),
    );
    await settleBrowser(tester);
    unawaited(router.navigate(const SecondRoute()));
    await settleBrowser(tester);
    unawaited(router.navigate(const ThirdRoute()));
    await settleBrowser(tester);

    router.pop();
    await settleBrowser(tester);
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [
      FirstRoute.name,
      SecondRoute.name,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Popping on web does not rerun the deep link builder', (
    tester,
  ) async {
    var deepLinkBuilds = 0;
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (link) {
          deepLinkBuilds++;
          return link;
        },
      ),
    );
    await settleBrowser(tester);
    unawaited(router.navigate(const SecondRoute()));
    await settleBrowser(tester);
    unawaited(router.navigate(const ThirdRoute()));
    await settleBrowser(tester);
    final buildsBeforePop = deepLinkBuilds;

    router.pop();
    await settleBrowser(tester);
    expectCurrentPage(router, SecondRoute.name);
    expect(deepLinkBuilds, buildsBeforePop);
  });
}
