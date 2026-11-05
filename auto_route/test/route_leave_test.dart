import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// flutter/flutter#145079: go_router's onExit doesn't say how the page is
// left, so an app can't ask before a back while letting a navigation
// elsewhere through. flutter/flutter#137394 asks for the same hook on typed
// routes; in auto_route a generated route's page is the app's own widget, so
// the listener goes in the page.
// Steps: open the home page, then the editor page, whose content sits in an
// AutoRouteLeaveListener; leave the editor each way auto_route has.
// Should: each leave is reported once, with its kind; a back that a PopScope
// refuses is not reported.
void main() {
  late List<RouteLeaveKind> leaves;
  late bool editorCanPop;
  late RootStackRouter router;

  setUp(() {
    leaves = [];
    editorCanPop = true;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/editor',
          page: PageInfo(
            'EditorRoute',
            builder: (_) => PopScope(
              canPop: editorCanPop,
              child: AutoRouteLeaveListener(onLeave: leaves.add, child: const Text('EditorRoute')),
            ),
          ),
        ),
        AutoRoute(
          path: '/preview',
          page: PageInfo('PreviewRoute', builder: (_) => const Text('PreviewRoute')),
        ),
      ],
    );
  });

  const editor = PageRouteInfo('EditorRoute');
  const preview = PageRouteInfo('PreviewRoute');
  const home = PageRouteInfo('HomeRoute');

  Future<void> openEditor(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(editor));
    await tester.pumpAndSettle();
    expectTopPage(router, 'EditorRoute');
    expect(leaves, isEmpty);
  }

  testWidgets('system back reports popped', (tester) async {
    await openEditor(tester);
    await systemBack(tester);
    expect(leaves, [RouteLeaveKind.popped]);
    expectTopPage(router, 'HomeRoute');
  });

  testWidgets('pop reports popped', (tester) async {
    await openEditor(tester);
    router.pop();
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.popped]);
  });

  testWidgets('a back the PopScope refuses is not reported', (tester) async {
    editorCanPop = false;
    await openEditor(tester);
    await systemBack(tester);
    unawaited(router.maybePop());
    await tester.pumpAndSettle();
    expect(leaves, isEmpty);
    expectTopPage(router, 'EditorRoute');
  });

  testWidgets('a push over the page reports covered, and a second push nothing more', (tester) async {
    await openEditor(tester);
    unawaited(router.push(preview));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered]);

    unawaited(router.push(const PageRouteInfo('HomeRoute')));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered], reason: 'after router.push(const PageRouteInfo(HomeRoute)))');

    // Back to the editor, then covered again: a second leave.
    router.popUntilRouteWithName('EditorRoute');
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered], reason: 'after router.popUntilRouteWithName(EditorRoute)');
    unawaited(router.push(preview));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered, RouteLeaveKind.covered]);
  });

  testWidgets('a pop of the page over it reports nothing', (tester) async {
    await openEditor(tester);
    unawaited(router.push(preview));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered]);
  });

  testWidgets('replace reports replaced', (tester) async {
    await openEditor(tester);
    unawaited(router.replace(preview));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.replaced]);
    expectTopPage(router, 'PreviewRoute');
  });

  testWidgets('replacePath reports replaced', (tester) async {
    await openEditor(tester);
    unawaited(router.replacePath('/preview'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.replaced]);
    expectTopPage(router, 'PreviewRoute');
  });

  testWidgets('replaceAll reports replaced', (tester) async {
    await openEditor(tester);
    unawaited(router.replaceAll([preview]));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.replaced]);
    expect(router.stack.map((page) => page.name), ['PreviewRoute']);
  });

  testWidgets('pushAndPopUntil reports replaced', (tester) async {
    await openEditor(tester);
    unawaited(router.pushAndPopUntil(preview, predicate: (_) => false));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.replaced]);
  });

  testWidgets('navigate to the page below reports removed', (tester) async {
    await openEditor(tester);
    unawaited(router.navigate(home));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.removed]);
    expectTopPage(router, 'HomeRoute');
  });

  // A root route that isn't in the stack opens over the top page, as a push.
  testWidgets('navigate to a route not in the stack reports covered', (tester) async {
    await openEditor(tester);
    unawaited(router.navigatePath('/preview'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered]);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'EditorRoute', 'PreviewRoute']);
  });

  testWidgets('a deep link to the page below reports removed', (tester) async {
    await openEditor(tester);
    unawaited(router.navigatePath('/'));
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.removed]);
    expectTopPage(router, 'HomeRoute');
  });

  testWidgets('removeLast reports removed', (tester) async {
    await openEditor(tester);
    router.removeLast();
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.removed]);
  });

  testWidgets('removeWhere under the top page reports removed', (tester) async {
    await openEditor(tester);
    unawaited(router.push(preview));
    await tester.pumpAndSettle();
    router.removeWhere((route) => route.name == 'EditorRoute');
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered, RouteLeaveKind.removed]);
  });

  testWidgets('popUntil past the page reports popped', (tester) async {
    await openEditor(tester);
    unawaited(router.push(preview));
    await tester.pumpAndSettle();
    router.popUntilRoot();
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.covered, RouteLeaveKind.popped]);
  });

  testWidgets('navigating to the page on top updates it in place and reports nothing', (tester) async {
    await openEditor(tester);
    unawaited(router.navigatePath('/editor'));
    await tester.pumpAndSettle();
    router.notifyAll();
    await tester.pumpAndSettle();
    expect(leaves, isEmpty);
  });

  // The editor's guard lets it in while signedIn is true; signing out and
  // reevaluating closes it.
  testWidgets('a guard that closes the page on reevaluation reports removed', (tester) async {
    final signedIn = ValueNotifier(true);
    addTearDown(signedIn.dispose);
    final guarded = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/editor',
          guards: [AutoRouteGuard.simple((resolver, _) => signedIn.value ? resolver.next() : resolver.reject())],
          page: PageInfo(
            'EditorRoute',
            builder: (_) => AutoRouteLeaveListener(onLeave: leaves.add, child: const Text('EditorRoute')),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, guarded, reevaluationNotifier: signedIn);
    unawaited(guarded.push(editor));
    await tester.pumpAndSettle();
    expectTopPage(guarded, 'EditorRoute');

    signedIn.value = false;
    await tester.pumpAndSettle();
    expect(leaves, [RouteLeaveKind.removed]);
    expectTopPage(guarded, 'HomeRoute');
  });

  // In a router AutoRouter.declarative builds, the app's list decides the
  // pages; system back reaches onPopRoute, and the pop is reported.
  testWidgets('a pop in a declarative router reports popped', (tester) async {
    final depth = ValueNotifier(2);
    addTearDown(depth.dispose);
    final declarative = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => ValueListenableBuilder<int>(
              valueListenable: depth,
              builder: (_, value, _) => AutoRouter.declarative(
                routes: (_) => [home, if (value > 1) editor],
                onPopRoute: (_, _) => depth.value = 1,
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
            ),
            AutoRoute(
              path: 'editor',
              page: PageInfo(
                'EditorRoute',
                builder: (_) => AutoRouteLeaveListener(onLeave: leaves.add, child: const Text('EditorRoute')),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, declarative);
    expect(find.text('EditorRoute'), findsOneWidget);

    await systemBack(tester);
    expect(leaves, [RouteLeaveKind.popped]);
    expect(find.text('HomeRoute'), findsOneWidget);
  });
}
