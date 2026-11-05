import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/188993
// Setup: a home page and a shell page whose nested stack holds an inner page.
// Steps: press system back while the shell's nested navigator is not built:
// in the frame the shell is pushed, in the frame the stack is replaced away
// from it, while the shell page hides its nested router, and after the app
// pauses and resumes.
// Should: back never throws; it pops what is built, or reports that the
// app doesn't handle it.
void main() {
  final showNested = ValueNotifier(true);
  late RootStackRouter router;
  setUp(() {
    showNested.value = true;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: _page('HomeRoute')),
        AutoRoute(
          path: '/shell',
          page: PageInfo(
            'ShellRoute',
            builder: (_) => ValueListenableBuilder(
              valueListenable: showNested,
              builder: (_, show, _) => show ? const AutoRouter() : const Text('Hidden'),
            ),
          ),
          children: [
            AutoRoute(path: '', page: _page('InnerRoute')),
            AutoRoute(path: 'second', page: _page('SecondRoute')),
          ],
        ),
      ],
    );
  });

  Future<void> pushShell(WidgetTester tester) async {
    unawaited(router.push(const _Route('ShellRoute')));
    await tester.pumpAndSettle();
    unawaited(router.innerRouterOf<StackRouter>('ShellRoute')!.push(const _Route('SecondRoute')));
    await tester.pumpAndSettle();
    expect(find.text('SecondRoute'), findsOneWidget);
  }

  testWidgets('Back in the frame a shell is pushed does not throw', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/shell/second'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back in the frame the stack is replaced away from a shell does not throw', (tester) async {
    await pumpRouterApp(tester, router);
    await pushShell(tester);
    unawaited(router.replaceAll([const _Route('HomeRoute')]));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsOneWidget);
  });

  testWidgets('Back while a shell page hides its nested router does not throw', (tester) async {
    await pumpRouterApp(tester, router);
    await pushShell(tester);
    showNested.value = false;
    await tester.pump();
    expect(find.text('Hidden'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // With no nested router built, the shell page is the page on top, and
    // back pops it.
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
    expect(find.text('HomeRoute'), findsOneWidget);
  });

  testWidgets('Back after the app pauses and resumes pops the nested page', (tester) async {
    await pumpRouterApp(tester, router);
    await pushShell(tester);
    tester.binding.handleAppLifecycleStateChanged(.inactive);
    tester.binding.handleAppLifecycleStateChanged(.hidden);
    tester.binding.handleAppLifecycleStateChanged(.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(.hidden);
    tester.binding.handleAppLifecycleStateChanged(.inactive);
    tester.binding.handleAppLifecycleStateChanged(.resumed);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('InnerRoute'), findsOneWidget);
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
